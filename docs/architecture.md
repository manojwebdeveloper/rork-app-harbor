# Harbor architecture direction

## Current milestone

Circles, invitations, location sharing, Places, Smart Alerts, check-ins and
the weekly digest are wired to a live Firebase backend. See
`harbor-ios-standards` (project skill) for the architecture, data-model and
design-fidelity standards this codebase follows — this document covers
product boundaries and security constraints only; it previously described a
"proposed" Cloud Run/Pub/Sub backend that was never built and has been
superseded by the Firebase decision below.

## Product boundaries

- Location sharing is explicit, revocable and circle-scoped.
- Temporary trip circles have an expiry.
- Stale positions are represented as delayed or last known, never as live.
- The primary differentiator is group journey coordination, not generic phone tracking.

## Backend (locked)

- **Firebase Authentication** — Sign in with Apple is primary; anonymous/guest
  auth is a fallback that must resolve to a real `users` profile document.
- **Firestore** — structured data: `users`, `circles`/`circleMembers`,
  `places`/`alertRules`, `checkIns`, `activity`, `digests`. Firestore Security
  Rules scope every collection to circle membership.
- **Realtime Database** — live location ticks only
  (`/locations/{circleId}/{uid}`), chosen for bandwidth-based pricing instead
  of Firestore's per-read pricing. Client-side throttling (10–15s or
  significant movement) is mandatory. RTDB rules can't read Firestore, so
  circle membership is mirrored into a small `/circleMembers` RTDB tree by
  the same Cloud Functions that own membership in Firestore.
- **Cloud Functions** (`europe-west2`) — circle/invitation lifecycle,
  account deletion, Smart Alert rule evaluation (client reports raw
  geofence crossings, the function evaluates rules and fans out push),
  "I'm Safe" push fan-out, scheduled weekly digest generation, and scheduled
  travel-circle auto-expiry.
- **Cloud Messaging (FCM)** — push tokens registered via a callable; delivery
  additionally needs an APNs Authentication Key uploaded to Firebase and the
  Push Notifications capability enabled on the App ID (Apple Developer
  Portal steps, not code).

## Security constraints

- No advertising SDKs
- No coordinates in analytics or notification payloads
- No unsupported end-to-end encryption claims
- Server-side circle authorisation on every protected request
- Automatic deletion of expired temporary data
- Immediate sharing revocation when a member leaves, pauses, or a trip ends
