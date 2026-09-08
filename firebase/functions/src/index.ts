import {randomInt} from "node:crypto";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {DocumentReference, FieldValue, Timestamp, getFirestore} from "firebase-admin/firestore";
import {getDatabase} from "firebase-admin/database";
import {getMessaging} from "firebase-admin/messaging";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions";

initializeApp();

const db = getFirestore();
const rtdb = getDatabase();
const messaging = getMessaging();
const region = "europe-west2";
const invitationLifetimeMs = 24 * 60 * 60 * 1000;
const maximumTripLengthMs = 90 * 24 * 60 * 60 * 1000;
const minimumTripExtensionMs = 60 * 60 * 1000;

type JsonObject = Record<string, unknown>;
type CircleRole = "owner" | "admin" | "member";

function requireUid(auth: {uid: string} | undefined): string {
  if (!auth?.uid) throw new HttpsError("unauthenticated", "Sign in before using this feature.");
  return auth.uid;
}

function objectData(value: unknown): JsonObject {
  return value && typeof value === "object" && !Array.isArray(value) ? value as JsonObject : {};
}

function requiredString(data: JsonObject, key: string, maxLength = 120): string {
  const value = data[key];
  if (typeof value !== "string") throw new HttpsError("invalid-argument", `${key} is required.`);
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > maxLength) throw new HttpsError("invalid-argument", `${key} is invalid.`);
  return trimmed;
}

function optionalNumber(data: JsonObject, key: string): number | undefined {
  const value = data[key];
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new HttpsError("invalid-argument", `${key} must be a number.`);
  }
  return value;
}

function tokenString(token: JsonObject | undefined, key: string): string {
  const value = token?.[key];
  return typeof value === "string" ? value : "";
}

function invitationCode(data: JsonObject): string {
  const raw = requiredString(data, "code", 12).replace(/\D/g, "");
  if (!/^\d{6}$/.test(raw)) throw new HttpsError("invalid-argument", "Enter a valid six-digit invitation code.");
  return raw;
}

function timestampMillis(value: unknown): number | null {
  return value instanceof Timestamp ? value.toMillis() : null;
}

async function circleAndRole(circleId: string, uid: string, acceptedRoles: CircleRole[]): Promise<{circleRef: DocumentReference; circle: JsonObject; role: CircleRole}> {
  const circleRef = db.collection("circles").doc(circleId);
  const [circleSnapshot, memberSnapshot] = await Promise.all([
    circleRef.get(),
    circleRef.collection("members").doc(uid).get(),
  ]);
  if (!circleSnapshot.exists) throw new HttpsError("not-found", "This circle no longer exists.");
  if (!memberSnapshot.exists) throw new HttpsError("permission-denied", "You are not a member of this circle.");
  const role = memberSnapshot.get("role") as CircleRole;
  if (!acceptedRoles.includes(role)) throw new HttpsError("permission-denied", "You cannot perform this action.");
  return {circleRef, circle: objectData(circleSnapshot.data()), role};
}

// RTDB cannot read Firestore, so circle membership is mirrored into a small
// `circleMembers` tree there purely so its security rules can authorise live
// location reads/writes without a second round trip. Firestore stays the
// source of truth; a mirror failure is logged but never fails the caller's
// Firestore-side request, which already succeeded.
async function setMembershipMirror(circleId: string, uid: string, isMember: boolean): Promise<void> {
  try {
    if (isMember) {
      await rtdb.ref(`circleMembers/${circleId}/${uid}`).set(true);
    } else {
      await Promise.all([
        rtdb.ref(`circleMembers/${circleId}/${uid}`).remove(),
        // Leaving revokes location sharing immediately, not at the next write.
        rtdb.ref(`locations/${circleId}/${uid}`).remove(),
      ]);
    }
  } catch (error) {
    logger.error(`Failed to update RTDB membership mirror for circle ${circleId}, uid ${uid}`, error);
  }
}

async function removeCircleFromRealtimeDatabase(circleId: string): Promise<void> {
  try {
    await Promise.all([
      rtdb.ref(`circleMembers/${circleId}`).remove(),
      rtdb.ref(`locations/${circleId}`).remove(),
    ]);
  } catch (error) {
    logger.error(`Failed to remove RTDB nodes for circle ${circleId}`, error);
  }
}

async function sendToMembers(circleId: string, excludeUid: string | null, notification: {title: string; body: string}, data: Record<string, string>): Promise<void> {
  const members = await db.collection("circles").doc(circleId).collection("members").get();
  const recipientIds = members.docs
    .map((member) => member.get("userId") as string | undefined)
    .filter((userId): userId is string => Boolean(userId) && userId !== excludeUid);
  if (recipientIds.length === 0) return;

  const userDocs = await db.getAll(...recipientIds.map((userId) => db.collection("users").doc(userId)));
  const tokens = userDocs.flatMap((snapshot) => {
    const value = snapshot.get("fcmTokens");
    return Array.isArray(value) ? (value as string[]) : [];
  });
  if (tokens.length === 0) return;

  try {
    const response = await messaging.sendEachForMulticast({tokens, notification, data});
    const staleTokens = response.responses
      .map((result, index) => (result.success ? null : tokens[index]))
      .filter((token): token is string => Boolean(token));
    if (staleTokens.length > 0) {
      await Promise.all(
        userDocs
          .filter((snapshot) => Array.isArray(snapshot.get("fcmTokens")))
          .map((snapshot) => snapshot.ref.update({fcmTokens: FieldValue.arrayRemove(...staleTokens)}))
      );
    }
  } catch (error) {
    logger.error(`Failed to send push notification for circle ${circleId}`, error);
  }
}

async function deleteCircleData(circleId: string): Promise<void> {
  const circleRef = db.collection("circles").doc(circleId);
  const [members, invitations] = await Promise.all([
    circleRef.collection("members").get(),
    db.collection("invitations").where("circleId", "==", circleId).get(),
  ]);
  const deletions: Promise<unknown>[] = [];
  for (const member of members.docs) {
    const userId = member.get("userId") as string | undefined;
    if (userId) deletions.push(db.collection("users").doc(userId).collection("circleRefs").doc(circleId).delete());
    deletions.push(member.ref.delete());
  }
  for (const invitation of invitations.docs) deletions.push(invitation.ref.delete());
  await Promise.all(deletions);
  await circleRef.delete();
  await removeCircleFromRealtimeDatabase(circleId);
}

function ensureInvitationUsable(invitation: JsonObject): void {
  if (invitation.revokedAt) throw new HttpsError("failed-precondition", "This invitation has been revoked.");
  const expiresAt = invitation.expiresAt;
  if (!(expiresAt instanceof Timestamp) || expiresAt.toMillis() <= Date.now()) {
    throw new HttpsError("deadline-exceeded", "This invitation has expired.");
  }
  const useCount = typeof invitation.useCount === "number" ? invitation.useCount : 0;
  const maxUses = typeof invitation.maxUses === "number" ? invitation.maxUses : 1;
  if (useCount >= maxUses) throw new HttpsError("resource-exhausted", "This invitation has already been fully used.");
}

export const createCircle = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const data = objectData(request.data);
  const name = requiredString(data, "name", 60);
  const kind = requiredString(data, "kind", 10);
  if (kind !== "family" && kind !== "trip") throw new HttpsError("invalid-argument", "Circle type must be family or trip.");

  let expiresAt: Timestamp | null = null;
  if (kind === "trip") {
    const expiryMs = optionalNumber(data, "expiresAtMs");
    if (!expiryMs || expiryMs <= Date.now() + 60 * 60 * 1000) {
      throw new HttpsError("invalid-argument", "Trip Circles must end at least one hour from now.");
    }
    if (expiryMs > Date.now() + maximumTripLengthMs) {
      throw new HttpsError("invalid-argument", "Trip Circles can last up to 90 days.");
    }
    expiresAt = Timestamp.fromMillis(expiryMs);
  }

  const circleRef = db.collection("circles").doc();
  const userRef = db.collection("users").doc(uid);
  const memberRef = circleRef.collection("members").doc(uid);
  const circleIndexRef = userRef.collection("circleRefs").doc(circleRef.id);
  const displayName = tokenString(request.auth?.token as JsonObject | undefined, "name");
  const email = tokenString(request.auth?.token as JsonObject | undefined, "email");
  const batch = db.batch();

  batch.set(circleRef, {name, kind, ownerId: uid, status: "active", expiresAt, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp()});
  batch.set(memberRef, {userId: uid, displayName, role: "owner", status: "active", sharingEnabled: true, joinedAt: FieldValue.serverTimestamp()});
  batch.set(circleIndexRef, {circleId: circleRef.id, name, kind, role: "owner", expiresAt, joinedAt: FieldValue.serverTimestamp()});
  batch.set(userRef, {uid, displayName, email, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
  await batch.commit();
  await setMembershipMirror(circleRef.id, uid, true);
  return {circleId: circleRef.id};
});

export const createInvitation = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const data = objectData(request.data);
  const circleId = requiredString(data, "circleId", 128);
  const {circle} = await circleAndRole(circleId, uid, ["owner", "admin"]);
  const circleName = requiredString(circle, "name", 60);
  const circleKind = requiredString(circle, "kind", 10);
  const circleExpiryMs = timestampMillis(circle.expiresAt);
  const expiresAtMs = circleExpiryMs ? Math.min(circleExpiryMs, Date.now() + invitationLifetimeMs) : Date.now() + invitationLifetimeMs;

  for (let attempt = 0; attempt < 12; attempt += 1) {
    const code = String(randomInt(100000, 1000000));
    const invitationRef = db.collection("invitations").doc(code);
    try {
      await db.runTransaction(async (transaction) => {
        const existing = await transaction.get(invitationRef);
        if (existing.exists) throw new Error("INVITATION_CODE_COLLISION");
        transaction.create(invitationRef, {code, circleId, circleName, circleKind, createdBy: uid, createdAt: FieldValue.serverTimestamp(), expiresAt: Timestamp.fromMillis(expiresAtMs), revokedAt: null, maxUses: 20, useCount: 0});
      });
      return {code, circleId, circleName, circleKind, expiresAtMs};
    } catch (error) {
      if (error instanceof Error && error.message === "INVITATION_CODE_COLLISION") continue;
      throw error;
    }
  }
  throw new HttpsError("aborted", "A unique invitation code could not be created. Try again.");
});

export const lookupInvitation = onCall({region, enforceAppCheck: false}, async (request) => {
  requireUid(request.auth);
  const code = invitationCode(objectData(request.data));
  const snapshot = await db.collection("invitations").doc(code).get();
  if (!snapshot.exists) throw new HttpsError("not-found", "Invitation not found.");
  const invitation = objectData(snapshot.data());
  ensureInvitationUsable(invitation);
  return {code, circleId: requiredString(invitation, "circleId", 128), circleName: requiredString(invitation, "circleName", 60), circleKind: requiredString(invitation, "circleKind", 10), expiresAtMs: timestampMillis(invitation.expiresAt)};
});

export const acceptInvitation = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const code = invitationCode(objectData(request.data));
  const invitationRef = db.collection("invitations").doc(code);
  const displayName = tokenString(request.auth?.token as JsonObject | undefined, "name");

  const result = await db.runTransaction(async (transaction) => {
    const invitationSnapshot = await transaction.get(invitationRef);
    if (!invitationSnapshot.exists) throw new HttpsError("not-found", "Invitation not found.");
    const invitation = objectData(invitationSnapshot.data());
    ensureInvitationUsable(invitation);
    const circleId = requiredString(invitation, "circleId", 128);
    const circleRef = db.collection("circles").doc(circleId);
    const memberRef = circleRef.collection("members").doc(uid);
    const userCircleRef = db.collection("users").doc(uid).collection("circleRefs").doc(circleId);
    const [circleSnapshot, memberSnapshot] = await Promise.all([transaction.get(circleRef), transaction.get(memberRef)]);
    if (!circleSnapshot.exists) throw new HttpsError("not-found", "This circle no longer exists.");
    const circle = objectData(circleSnapshot.data());
    const circleExpiresAtMs = timestampMillis(circle.expiresAt);
    if (circleExpiresAtMs && circleExpiresAtMs <= Date.now()) throw new HttpsError("deadline-exceeded", "This Trip Circle has ended.");
    if (!memberSnapshot.exists) {
      transaction.set(memberRef, {userId: uid, displayName, role: "member", status: "active", sharingEnabled: true, joinedAt: FieldValue.serverTimestamp(), joinedWithInvitationCode: code});
      transaction.set(userCircleRef, {circleId, name: requiredString(circle, "name", 60), kind: requiredString(circle, "kind", 10), role: "member", expiresAt: circle.expiresAt ?? null, joinedAt: FieldValue.serverTimestamp()});
      transaction.update(invitationRef, {useCount: FieldValue.increment(1), lastUsedAt: FieldValue.serverTimestamp()});
    }
    return {circleId, alreadyMember: memberSnapshot.exists};
  });

  if (!result.alreadyMember) await setMembershipMirror(result.circleId, uid, true);
  return result;
});

export const revokeInvitation = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const code = invitationCode(objectData(request.data));
  const invitationRef = db.collection("invitations").doc(code);
  const snapshot = await invitationRef.get();
  if (!snapshot.exists) throw new HttpsError("not-found", "Invitation not found.");
  const invitation = objectData(snapshot.data());
  const circleId = requiredString(invitation, "circleId", 128);
  const createdBy = requiredString(invitation, "createdBy", 128);
  if (createdBy !== uid) await circleAndRole(circleId, uid, ["owner", "admin"]);
  await invitationRef.update({revokedAt: FieldValue.serverTimestamp(), revokedBy: uid});
  return {revoked: true};
});

export const leaveCircle = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const circleId = requiredString(objectData(request.data), "circleId", 128);
  const {circleRef, role} = await circleAndRole(circleId, uid, ["owner", "admin", "member"]);
  if (role === "owner") throw new HttpsError("failed-precondition", "The owner must delete the circle instead of leaving it.");
  await Promise.all([circleRef.collection("members").doc(uid).delete(), db.collection("users").doc(uid).collection("circleRefs").doc(circleId).delete()]);
  await setMembershipMirror(circleId, uid, false);
  return {left: true};
});

export const deleteCircle = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const circleId = requiredString(objectData(request.data), "circleId", 128);
  await circleAndRole(circleId, uid, ["owner"]);
  await deleteCircleData(circleId);
  return {deleted: true};
});

export const deleteAccount = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const ownedCircles = await db.collection("circles").where("ownerId", "==", uid).get();
  for (const circle of ownedCircles.docs) await deleteCircleData(circle.id);
  const memberships = await db.collectionGroup("members").where("userId", "==", uid).get();
  for (const membership of memberships.docs) {
    const circleRef = membership.ref.parent.parent;
    if (circleRef) {
      await Promise.all([membership.ref.delete(), db.collection("users").doc(uid).collection("circleRefs").doc(circleRef.id).delete()]);
      await setMembershipMirror(circleRef.id, uid, false);
    }
  }
  const [createdInvitations, circleRefs] = await Promise.all([
    db.collection("invitations").where("createdBy", "==", uid).get(),
    db.collection("users").doc(uid).collection("circleRefs").get(),
  ]);
  await Promise.all([...createdInvitations.docs.map((document) => document.ref.delete()), ...circleRefs.docs.map((document) => document.ref.delete())]);
  await db.collection("users").doc(uid).delete();
  await getAuth().deleteUser(uid);
  return {deleted: true};
});

export const updateCircleExpiry = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const data = objectData(request.data);
  const circleId = requiredString(data, "circleId", 128);
  const action = requiredString(data, "action", 20);
  if (action !== "extend" && action !== "keepPermanently") {
    throw new HttpsError("invalid-argument", "action must be extend or keepPermanently.");
  }
  const {circleRef, circle} = await circleAndRole(circleId, uid, ["owner", "admin"]);
  if (circle.kind !== "trip") throw new HttpsError("failed-precondition", "Only Trip Circles have an expiry to change.");

  if (action === "keepPermanently") {
    await circleRef.update({kind: "family", expiresAt: null, updatedAt: FieldValue.serverTimestamp()});
    return {kind: "family", expiresAtMs: null};
  }

  const requestedExpiryMs = optionalNumber(data, "expiresAtMs");
  if (!requestedExpiryMs || requestedExpiryMs <= Date.now() + minimumTripExtensionMs) {
    throw new HttpsError("invalid-argument", "The new end time must be at least one hour from now.");
  }
  if (requestedExpiryMs > Date.now() + maximumTripLengthMs) {
    throw new HttpsError("invalid-argument", "Trip Circles can last up to 90 days.");
  }
  await circleRef.update({expiresAt: Timestamp.fromMillis(requestedExpiryMs), updatedAt: FieldValue.serverTimestamp()});
  return {kind: "trip", expiresAtMs: requestedExpiryMs};
});

export const registerPushToken = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const token = requiredString(objectData(request.data), "token", 4096);
  await db.collection("users").doc(uid).set({fcmTokens: FieldValue.arrayUnion(token)}, {merge: true});
  return {registered: true};
});

export const unregisterPushToken = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const token = requiredString(objectData(request.data), "token", 4096);
  await db.collection("users").doc(uid).set({fcmTokens: FieldValue.arrayRemove(token)}, {merge: true});
  return {unregistered: true};
});

export const updateDigestPreferences = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const data = objectData(request.data);
  const enabled = data.enabled;
  if (typeof enabled !== "boolean") throw new HttpsError("invalid-argument", "enabled must be a boolean.");
  const dayOfWeek = optionalNumber(data, "dayOfWeek");
  const hourUTC = optionalNumber(data, "hourUTC");
  if (dayOfWeek !== undefined && (dayOfWeek < 0 || dayOfWeek > 6)) {
    throw new HttpsError("invalid-argument", "dayOfWeek must be between 0 (Sunday) and 6 (Saturday).");
  }
  if (hourUTC !== undefined && (hourUTC < 0 || hourUTC > 23)) {
    throw new HttpsError("invalid-argument", "hourUTC must be between 0 and 23.");
  }
  await db.collection("users").doc(uid).set({
    digestPreferences: {
      enabled,
      dayOfWeek: dayOfWeek ?? 0,
      hourUTC: hourUTC ?? 9,
    },
  }, {merge: true});
  return {updated: true};
});

// "I'm Safe" never carries a coordinate — only the fact that the sender chose
// to broadcast it, matching the no-coordinates-in-notifications constraint.
export const sendSafeBroadcast = onCall({region, enforceAppCheck: false}, async (request) => {
  const uid = requireUid(request.auth);
  const circleId = requiredString(objectData(request.data), "circleId", 128);
  const {circle} = await circleAndRole(circleId, uid, ["owner", "admin", "member"]);
  const displayName = tokenString(request.auth?.token as JsonObject | undefined, "name") || "A circle member";
  const circleName = requiredString(circle, "name", 60);

  await db.collection("circles").doc(circleId).collection("activity").add({
    kind: "safe",
    memberId: uid,
    title: `${displayName} is safe`,
    detail: `Sent to ${circleName} · no location shared`,
    createdAt: FieldValue.serverTimestamp(),
  });

  await sendToMembers(
    circleId,
    uid,
    {title: circleName, body: `${displayName} let the circle know they're safe.`},
    {type: "safe", circleId}
  );

  return {sent: true};
});

// Runs hourly: Trip Circles end themselves, revoking location sharing immediately
// rather than leaving a stale "live" position visible after the trip is over.
export const expireTravelCircles = onSchedule({region, schedule: "0 * * * *", timeZone: "Etc/UTC"}, async () => {
  const now = Timestamp.now();
  const expired = await db.collection("circles")
    .where("kind", "==", "trip")
    .where("status", "==", "active")
    .where("expiresAt", "<=", now)
    .get();

  for (const circleDoc of expired.docs) {
    const circleId = circleDoc.id;
    const circleName = requiredString(objectData(circleDoc.data()), "name", 60);
    await circleDoc.ref.update({status: "expired", updatedAt: FieldValue.serverTimestamp()});
    await db.collection("circles").doc(circleId).collection("activity").add({
      kind: "system",
      memberId: null,
      title: `${circleName} has ended`,
      detail: "This Trip Circle's location sharing has stopped.",
      createdAt: FieldValue.serverTimestamp(),
    });
    await removeCircleFromRealtimeDatabase(circleId);
    await sendToMembers(
      circleId,
      null,
      {title: circleName, body: "This trip has ended and location sharing has stopped."},
      {type: "tripEnded", circleId}
    );
  }
});

// Runs weekly. Per-user delivery-time preferences (see updateDigestPreferences)
// are stored for a future per-user send scheduler; today every active circle's
// digest is computed and pushed at the same fixed weekly run.
export const generateWeeklyDigests = onSchedule({region, schedule: "5 0 * * 1", timeZone: "Etc/UTC"}, async () => {
  const weekEnd = Timestamp.now();
  const weekStart = Timestamp.fromMillis(weekEnd.toMillis() - 7 * 24 * 60 * 60 * 1000);
  const weekId = weekEnd.toDate().toISOString().slice(0, 10);

  const circles = await db.collection("circles").where("status", "==", "active").get();

  for (const circleDoc of circles.docs) {
    const circleId = circleDoc.id;
    const [members, checkIns, activity] = await Promise.all([
      db.collection("circles").doc(circleId).collection("members").get(),
      db.collection("circles").doc(circleId).collection("checkIns").where("sentAt", ">=", weekStart).get(),
      db.collection("circles").doc(circleId).collection("activity").where("createdAt", ">=", weekStart).get(),
    ]);
    if (members.empty) continue;

    type MemberStats = {checkIns: number; places: Set<string>; alerts: number};
    const statsByMember = new Map<string, MemberStats>();
    for (const member of members.docs) {
      statsByMember.set(member.id, {checkIns: 0, places: new Set(), alerts: 0});
    }

    for (const checkIn of checkIns.docs) {
      const userId = checkIn.get("userId") as string | undefined;
      const stats = userId ? statsByMember.get(userId) : undefined;
      if (stats) stats.checkIns += 1;
    }

    for (const entry of activity.docs) {
      const data = objectData(entry.data());
      const memberId = typeof data.memberId === "string" ? data.memberId : undefined;
      const stats = memberId ? statsByMember.get(memberId) : undefined;
      if (!stats) continue;
      if (data.kind === "arrival" || data.kind === "departure") {
        const placeName = typeof data.placeName === "string" ? data.placeName : undefined;
        if (placeName) stats.places.add(placeName);
      } else if (data.kind === "lowBattery") {
        stats.alerts += 1;
      }
    }

    const memberSummaries = Array.from(statsByMember.entries()).map(([userId, stats]) => ({
      userId,
      checkIns: stats.checkIns,
      places: stats.places.size,
      placeNames: Array.from(stats.places),
      alerts: stats.alerts,
    }));

    await db.collection("circles").doc(circleId).collection("digests").doc(weekId).set({
      weekStart,
      weekEnd,
      memberSummaries,
      createdAt: FieldValue.serverTimestamp(),
    });

    const recipientIds = members.docs
      .map((member) => member.get("userId") as string | undefined)
      .filter((userId): userId is string => Boolean(userId));
    if (recipientIds.length === 0) continue;
    const userDocs = await db.getAll(...recipientIds.map((userId) => db.collection("users").doc(userId)));
    const enabledTokens = userDocs.flatMap((snapshot) => {
      const preferences = objectData(snapshot.get("digestPreferences"));
      if (preferences.enabled === false) return [];
      const tokens = snapshot.get("fcmTokens");
      return Array.isArray(tokens) ? (tokens as string[]) : [];
    });
    if (enabledTokens.length === 0) continue;

    try {
      await messaging.sendEachForMulticast({
        tokens: enabledTokens,
        notification: {
          title: "Your weekly digest is ready",
          body: `See what happened this week in ${requiredString(objectData(circleDoc.data()), "name", 60)}.`,
        },
        data: {type: "weeklyDigest", circleId},
      });
    } catch (error) {
      logger.error(`Failed to send weekly digest push for circle ${circleId}`, error);
    }
  }
});

function matchesRule(rule: JsonObject, memberId: string, localMinutes: number, localDayOfWeek: number): boolean {
  const personId = rule.personId;
  // "anyone" matches every member; a specific personId must match exactly.
  // "not_everyone" (a completeness check across all members) and the "by"
  // comparator (a negative "hasn't happened yet" check) both need a
  // scheduled sweep rather than a single event to evaluate — not yet built,
  // see the final report.
  if (personId === "not_everyone") return false;
  if (personId !== "anyone" && personId !== memberId) return false;

  const days = Array.isArray(rule.days) ? (rule.days as unknown[]).filter((d): d is number => typeof d === "number") : [];
  if (days.length > 0 && !days.includes(localDayOfWeek)) return false;

  const ruleMinutes = typeof rule.timeMinutes === "number" ? rule.timeMinutes : null;
  if (ruleMinutes === null) return false;
  if (rule.comparator === "after") return localMinutes >= ruleMinutes;
  if (rule.comparator === "before") return localMinutes <= ruleMinutes;
  return false;
}

function ruleSentence(rule: JsonObject, memberName: string, placeName: string): string {
  const verb = rule.event === "leaves" ? "left" : "arrived at";
  return `${memberName} ${verb} ${placeName}`;
}

// Triggered by the member's own device reporting a geofence crossing (see
// firestore.rules: only that member may create their own event, and never
// edit it after). Always records an arrival/departure activity entry — the
// weekly digest already aggregates those — then evaluates active Smart
// Alert rules for this place/event and, if one matches, records a
// `smartAlert` activity entry and pushes everyone in the circle except the
// member the rule is about (so "the people named never see the rule" the
// UI already promises stays true structurally, not just by convention).
export const evaluateSmartAlert = onDocumentCreated(
  {region, document: "circles/{circleId}/places/{placeId}/events/{eventId}"},
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const data = objectData(snapshot.data());
    const {circleId, placeId} = event.params as {circleId: string; placeId: string};

    const memberId = requiredString(data, "memberId", 128);
    const type = data.type === "arrival" || data.type === "departure" ? data.type : null;
    const localMinutes = optionalNumber(data, "localMinutes");
    const localDayOfWeek = optionalNumber(data, "localDayOfWeek");
    if (!type || localMinutes === undefined || localDayOfWeek === undefined) return;

    const placesRef = db.collection("circles").doc(circleId).collection("places").doc(placeId);
    const [placeSnapshot, memberSnapshot] = await Promise.all([
      placesRef.get(),
      db.collection("circles").doc(circleId).collection("members").doc(memberId).get(),
    ]);
    if (!placeSnapshot.exists || !memberSnapshot.exists) return;

    const placeName = requiredString(objectData(placeSnapshot.data()), "name", 120);
    const memberName = (memberSnapshot.get("displayName") as string | undefined)?.trim() || "A circle member";
    const activityCollection = db.collection("circles").doc(circleId).collection("activity");

    await activityCollection.add({
      kind: type,
      memberId,
      placeId,
      placeName,
      title: `${memberName} ${type === "arrival" ? "arrived at" : "left"} ${placeName}`,
      detail: type === "arrival" ? "Arrival alert" : "Departure alert",
      createdAt: FieldValue.serverTimestamp(),
    });

    const ruleEvent = type === "arrival" ? "arrives" : "leaves";
    const rulesSnapshot = await placesRef.collection("alertRules")
      .where("isOn", "==", true)
      .where("event", "==", ruleEvent)
      .get();
    if (rulesSnapshot.empty) return;

    const dayKey = new Date().toISOString().slice(0, 10);

    for (const ruleDoc of rulesSnapshot.docs) {
      const rule = objectData(ruleDoc.data());
      if (!matchesRule(rule, memberId, localMinutes, localDayOfWeek)) continue;

      if (rule.frequency === "onceADay") {
        const alreadyFired = await activityCollection
          .where("kind", "==", "smartAlert")
          .where("ruleId", "==", ruleDoc.id)
          .where("firedDayKey", "==", dayKey)
          .limit(1)
          .get();
        if (!alreadyFired.empty) continue;
      }

      const sentence = ruleSentence(rule, memberName, placeName);
      await activityCollection.add({
        kind: "smartAlert",
        memberId,
        placeId,
        placeName,
        ruleId: ruleDoc.id,
        title: sentence,
        detail: "Smart Alert",
        firedDayKey: dayKey,
        createdAt: FieldValue.serverTimestamp(),
      });

      if (rule.frequency !== "weeklySummary") {
        await sendToMembers(circleId, memberId, {title: "Smart Alert", body: sentence}, {type: "smartAlert", circleId, placeId});
      }
    }
  }
);
