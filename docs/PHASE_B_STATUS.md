# Harbor — Phase B Status Report

Repository: `github.com/manojwebdeveloper/rork-app-harbor`, branch `main`.
Firebase project: `harbor-2d498` (Blaze plan). This document is a complete
handoff for a fresh Claude Code session — read this instead of re-deriving
project state from scratch.

Also read `harbor-ios-standards` (project skill) for the architecture, data
model, and workflow rules this codebase follows — this report covers state,
not standards.

## Firebase backend — fully live and verified

| Service | Status |
|---|---|
| Auth (Apple + Anonymous) | Live |
| Firestore | Live — rules + indexes deployed |
| Realtime Database | Live — `harbor-2d498-default-rtdb.europe-west1`, rules deployed, read/write verified directly |
| Cloud Functions | Live — all 16, `europe-west2` |

Deployed functions: `createCircle`, `createInvitation`, `lookupInvitation`,
`acceptInvitation`, `revokeInvitation`, `leaveCircle`, `deleteCircle`,
`deleteAccount`, `updateCircleExpiry`, `registerPushToken`,
`unregisterPushToken`, `updateDigestPreferences`, `sendSafeBroadcast`,
`expireTravelCircles` (scheduled), `generateWeeklyDigests` (scheduled),
`evaluateSmartAlert` (Firestore-triggered).

Getting here needed three IAM grants on the `firebase-adminsdk-fbsvc`
service account, in order: Editor (unblocked RTDB creation, Firestore/RTDB
rules deploy), Blaze billing plan (unblocked Cloud Build/Artifact
Registry/Cloud Run for Functions v2), Project IAM Admin (unblocked the
Eventarc/Pub-Sub service-agent bindings a first-time 2nd-gen
Firestore-triggered function needs). All three are now granted — future
deploys need no further access changes. Deploy command:
```bash
firebase deploy --project harbor-2d498 --only firestore:rules,firestore:indexes,database,functions
```

## What's real (client wired to the live backend)

- **Circles & invitations** — create/join/leave/delete, QR/link/6-digit
  codes, account deletion. Pre-existing, untouched this phase.
- **Location sharing** — `LocationService` throttles publishes to RTDB
  (~12s or 40m movement, whichever first) for every circle the user shares
  with; `LiveCircleLocationsService` reads it back; `MainMapView` renders
  members on a real MapKit map (replaced a hand-drawn illustration that
  used fake unit-square coordinates).
- **Places** — real Firestore CRUD, real MapKit local search, a real map +
  radius circle (was a static illustration), on-device `CLCircularRegion`
  monitoring (capped at the selected circle's places, iOS's 20-region
  limit) reporting crossings to Firestore.
- **Smart Alerts** — real rule CRUD; `evaluateSmartAlert` Cloud Function
  evaluates "arrives"/"leaves" + "after"/"before" rules against reported
  crossings and pushes the circle (excluding the member the rule is
  about). "not_everyone" person-rules and the "by" comparator are stored
  and toggle correctly but **not evaluated yet** — both need a scheduled
  sweep across all members rather than a single event; noted in
  `evaluateSmartAlert`'s doc comment in `firebase/functions/src/index.ts`.
- **Check-ins** — real Firestore writes; `ActivityView` merges them with
  the server-authored activity feed (safe broadcasts, system notices,
  arrival/departure/Smart Alert entries) via `ActivityTimelineMapping`.
  A check-in's sharing-window duration is recorded but doesn't yet toggle
  a temporary live-sharing override.
- **Weekly Digest** — real digest reads, real `updateDigestPreferences`
  call. `generateWeeklyDigests` runs on one fixed weekly schedule for
  every circle; per-user delivery day/time is stored but not yet used to
  time individual sends.
- **"I'm Safe"** — real `sendSafeBroadcast` call, writes an activity entry
  and fans out push, no coordinates in the payload.
- **Travel circles** — `expireTravelCircles` (hourly) ends trips past
  `expiresAt` and revokes their RTDB location node immediately.
- **Push registration** — `PushNotificationService` requests
  authorization, registers for remote notifications, forwards the FCM
  token to `registerPushToken`. **Actual delivery still needs**: an APNs
  Authentication Key uploaded to Firebase Cloud Messaging, and the Push
  Notifications capability enabled on the `com.appamore.harbor` App ID —
  both Apple Developer Portal steps, outside any session's access so far.
- **Widgets** — real App Group (`group.com.appamore.harbor`) snapshot
  pipeline; `MainMapView` writes real member data whenever it changes,
  widgets read it back, falling back to sample data before first launch
  (correct pattern, not leftover fake data).
- **Screen merges** — `NewCircleFlowView` (Phase 2 visuals) is the one
  real circle-creation flow, used everywhere including onboarding; real
  dates, a working custom-date picker, a real invite-link step.
  `ManageCirclesView` (Phase 2 visuals) is the one real circle-management
  screen, with working sharing toggles and Extend/Keep-permanently.
  `CreateCircleView`, `CircleManagementView`, and two already-dead Phase 1
  map views (`MemberCarouselView`, `MemberDetailSheetView`) are deleted.
- **Design fidelity** — splash screen now shows the real app icon (was a
  generic SF Symbol); `CalmTeal`/`DeepTeal`/`SeaGlass`/`MineralBorder`/
  `LaunchBackground` color tokens corrected to match the Phase 1 "Calm
  Signal" design canvas exactly in both light and dark mode.

## Architecture decisions worth knowing

- Firestore direct client writes (rules-gated) for Places/Smart Alert
  rules/Check-ins/geofence events; Cloud Functions reserved for anything
  needing server trust or fan-out (rule evaluation, push, scheduling) —
  matches the existing "circles are function-only" posture.
- RTDB rules can't read Firestore, so circle membership is mirrored into a
  small `/circleMembers` RTDB tree by the same functions that own
  membership in Firestore.
- Protocol-first applied to every new service (`PlacesService`,
  `ActivityService`, `PushNotificationService`, `WidgetSnapshotWriter`) per
  `harbor-ios-standards`. `AuthService`/`CircleService` were **not**
  retrofitted with protocols — a deliberate scope cut given size, flagged
  as a follow-up rather than risked this late in the pass.
- `MapCanvasView` was rewritten from a hand-drawn illustration to real
  MapKit (confirmed with the user first — this was a user-facing visual
  change beyond pure backend wiring).

## Verified vs. not yet verified

**Verified**: full `xcodebuild` green after every commit (app + widget
extension). Live in Simulator: onboarding renders and navigates, guest
sign-in performs a real Anonymous Auth + real Firestore profile write (the
skill's flagged "recurring bug" area — confirmed not broken), the merged
circle-creation flow renders correctly through Kind → Name with correct
validation state. Firestore/RTDB/Functions all independently confirmed
live via direct Admin SDK calls and `firebase functions:list`.

**Not yet verified**: a full circle-creation round-trip in Simulator — a
SwiftUI `TextField` wasn't accepting simulated keyboard input in that
session (looked like a tooling limitation, not an app bug, but never
confirmed on a real device). Background location behavior, actual push
delivery, two-device live sync, and widget behavior on a Home/Lock Screen
all require a real device and haven't been tested at all.

## Before TestFlight

1. Real-device run: background location, two-device live sync, actual
   push delivery (once the APNs key below is set up), widgets.
2. APNs Authentication Key → Firebase Cloud Messaging; Push Notifications
   capability on the App ID.
3. Confirm the Simulator text-input issue was tooling-only, not a real bug,
   on a device.
4. Everything in "Known limitations" in `docs/firebase-testing-setup.md`
   (not_everyone/`by` Smart Alert rules, per-user digest timing, check-in
   temporary sharing override, `harbor://` custom scheme vs. universal
   links, App Check/rate limiting before public release).
