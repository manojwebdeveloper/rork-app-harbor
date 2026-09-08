# Firebase testing setup

Firebase Authentication, Firestore, Realtime Database and Cloud Functions are
the backend — see `harbor-ios-standards` (project skill) for why the data is
split between Firestore and RTDB the way it is.

## 1. Create the Firebase project

1. Create or select a Firebase project.
2. Add an Apple/iOS application with bundle identifier `com.appamore.harbor`.
3. Download `GoogleService-Info.plist`.
4. Place it at `ios/HarborPrivateFamilyLocation/Resources/GoogleService-Info.plist`.

The plist must be committed at that exact path — Rork's remote builder has no other way to
receive it. `.gitignore` ignores `GoogleService-Info.plist` everywhere except there. Every
other copy stays untracked.

The values in this file are client identifiers, not secrets; Firestore Security Rules and
App Check are what protect the backend.

## 2. Enable sign-in providers

1. In the Apple Developer portal, enable Sign in with Apple for the App ID matching `com.appamore.harbor`.
2. In Firebase Authentication → Sign-in method, enable the **Apple** provider, entering the Apple Team ID, Key ID and private key Firebase asks for.
3. In the same screen, also enable the **Anonymous** provider — the app's "Continue as guest" flow depends on it, and silently fails otherwise.
4. In Xcode, select the correct Apple Development Team and confirm the Sign in with Apple capability is present.

The project already contains `HarborPrivateFamilyLocation.entitlements` and the XcodeGen capability configuration.

## 3. Create Firestore

Create the default Cloud Firestore database (Native mode). Use a European database location suitable for the UK launch where possible.

Do not use test-mode rules. The repository contains explicit rules that deny direct invitation and membership writes and scope every other collection to circle membership.

## 4. Create the Realtime Database

Firebase Console → Build → Realtime Database → **Create Database**. This is a separate provisioning step from Firestore and also enables the Firebase Realtime Database Management API — a `firebase deploy` targeting `database` fails with a clear `SERVICE_DISABLED` error until this is done, and a **service-account key alone cannot create the instance or enable the API** (the default `firebase-adminsdk` service account is scoped to Admin SDK data access only, not project administration — creating the instance needs an Editor-level identity, i.e. your own `firebase login` or a service account explicitly granted Editor).

## 5. Deploy

Install the Firebase CLI, sign in and select the project:

```bash
npm install -g firebase-tools
firebase login
cp .firebaserc.example .firebaserc
firebase use YOUR_FIREBASE_PROJECT_ID
```

Install and compile the functions:

```bash
cd firebase/functions
npm install
npm run build
cd ../..
```

Deploy everything:

```bash
firebase deploy --only functions,firestore:rules,firestore:indexes,database
```

The callable and scheduled functions deploy to `europe-west2`. Scheduled functions
(`expireTravelCircles`, `generateWeeklyDigests`) additionally need the Cloud Scheduler
and Pub/Sub APIs, which `firebase deploy` enables automatically if the deploying identity
has permission to enable APIs — the same Editor-level requirement as step 4.

## 6. Push notifications (optional but recommended)

1. Apple Developer Portal → Keys → create an APNs Authentication Key, download it.
2. Firebase Console → Project settings → Cloud Messaging → Apple app configuration → upload that key.
3. Apple Developer Portal → the `com.appamore.harbor` App ID → enable the **Push Notifications** capability.
4. In Xcode, confirm Signing & Capabilities shows Push Notifications and Background Modes (Remote notifications) — both are already declared in the committed entitlements/Info.plist, but need a real signing team to actually provision.

Without this, `registerPushToken` still runs (the client registers a token), but no push is ever delivered — the token has nowhere valid to go.

## 7. Generate and run the iOS project

Rork builds `ios/HarborPrivateFamilyLocation.xcodeproj` directly; that project is committed and is
the source of truth. `project.yml` and XcodeGen are only for regenerating a standalone project
locally — running `xcodegen generate` writes `HarborPrivateFamilyLocation.xcodeproj` at the
repository root and leaves the Rork project under `ios/` untouched.

```bash
brew install xcodegen
xcodegen generate
open HarborPrivateFamilyLocation.xcodeproj
```

In Xcode:

1. Select the HarborPrivateFamilyLocation target.
2. Choose the correct development team.
3. Confirm the bundle identifier matches the Firebase iOS app.
4. Confirm Sign in with Apple, Push Notifications and the `group.com.appamore.harbor` App Group are all enabled under Signing & Capabilities — a real team is required for these to provision correctly, which is why `DEVELOPMENT_TEAM` is intentionally left blank in the committed project.
5. Run on a physical iPhone signed in to an Apple Account (background location, real push delivery and widget App Group behavior can't be fully verified in Simulator).

## 8. Test checklist

1. Complete onboarding, including the location and notification permission prompts.
2. Sign in with Apple (and separately, "Continue as guest" — confirm its Firestore profile document is created, not just the auth session).
3. Create a Family Circle and a Trip Circle with an expiry, via the same New Circle flow.
4. Generate an invitation from the Ready step; accept it on a second account and confirm both see the circle update in realtime.
5. Leave a circle as a member; delete a circle as its owner.
6. Enable location sharing for a circle and confirm a second device sees the first move on the map (throttled — expect ticks roughly every 10–15s, not continuous).
7. Add a Place, walk in and out of its radius (or simulate a location change past the boundary), and confirm an activity entry appears.
8. Write a Smart Alert rule ("arrives"/"leaves" + "after"/"before"), trigger it, and confirm the other member gets a push and the rule's own subject does not.
9. Send a check-in and confirm it appears in Activity for the whole circle.
10. Send "I'm Safe" and confirm the receipt screen and the circle's Activity feed both show it.
11. Confirm a Trip Circle actually expires at its end time (or force it by setting a near-future `expiresAt` directly in Firestore) and that location sharing for it stops.
12. Check the Home Screen and Lock Screen widgets update after opening the app.
13. Delete an account and confirm the Apple token is revoked, memberships are removed and the Firebase Authentication user disappears.

## Known limitations

- Smart Alert rules using "Not everyone" as the person, or the "by" time comparator, are stored and toggle correctly but are not evaluated yet — both need a scheduled sweep across all members rather than a single geofence event (see `evaluateSmartAlert`'s doc comment in `firebase/functions/src/index.ts`).
- The weekly digest computes and sends on one fixed schedule for every circle; per-user delivery day/time preferences are stored but not yet used to time individual sends.
- A check-in's "also share my location for" duration is recorded but doesn't yet toggle a temporary sharing override.
- Invitation links use the custom `harbor://` scheme. Add an associated domain and HTTPS universal links before public release.
- App Check enforcement is disabled in callable functions. Six-digit invitation codes are suitable for limited private testing only until it's enabled.
- Before production, enable App Attest/App Check and add abuse throttling.
