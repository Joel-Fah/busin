# Status

Updated: 2026-11-03

Current phase: **Phase 2, shared packages and admin portal** ([docs/phases/phase-2-shared-and-admin-web.md](docs/phases/phase-2-shared-and-admin-web.md))

## Phases

| Phase | Goal | State |
|---|---|---|
| 0 Foundation | Monorepo layout, docs, skills, workflow, GitHub setup | Done and merged into `dev` |
| 1 Backend | Secure multi-tenant Supabase backend | Done and merged into `dev` (126 database tests) |
| 2 Shared and admin web | Shared Dart packages, admin portal | **Done and merged into `dev`.** Admin portal (with the bento overview); `busin_core` has the models and the repository interfaces, `busin_data` the Supabase implementations, `busin_ui` the design system. Flutter 3.47.9 through fvm resolves, analyzes and tests the workspace |
| 3 Student app | Lightweight student app | **In progress.** Slice 1 (shell, Google sign-in, role gate) on branch `phase-3/student-shell`; see [apps/student](apps/student/README.md) for the slices |
| 4 Ops app | Scanner and driver mode | Not started |
| 5 Insights | Density map, pickup and route suggestions | Not started |
| 6 Scale | More schools, payments, hardware tracker | Not started |

## Blockers (owner)

- Google sign-in cannot be tested for real until the OAuth client ID and secret are in `supabase/.env` (see [docs/guides/google-sign-in.md](docs/guides/google-sign-in.md)). Local development uses `/dev/login` meanwhile.

## Open questions

- Answered (2026-10-30): scanning happens at each stop as students board, so scan GPS is a valid boarding location. At least 2 buses run, and sometimes only 1 when the other is out of service. Stops are fixed today, but the goal is to suggest better stops and routes from student data (see docs/phases/phase-5-insights.md).
- Web hosting for the admin portal (Phase 2 end).
- Whether and when to retire the old ICTU Firebase project (owner decision).
- Map provider: MapLibre with OpenFreeMap now, Mapbox possible later ([ADR 0008](docs/decisions/0008-map-provider.md)). Confirm OpenFreeMap's usage terms on openfreemap.org before heavy use.

## Findings from the audit that apply only to the legacy app

H6 (release signing fails without `key.properties`), H7 (iOS Google sign-in config), L1 to L3. Not planned for fix in legacy unless the owner asks.

## Last handoff

Done: Phase 3, slice 5b, the app side of push notifications (branch `phase-3/push-app`, issue #126), on top of 5a (`phase-3/push-backend`). Firebase is optional at build time: without `apps/student/android/app/google-services.json` (git-ignored, yours) the app builds and runs with push off; with it, Firebase Cloud Messaging starts (I built both ways, the second with a throwaway dummy file I deleted). Nothing is asked at launch: an already-allowed student is registered silently, and a student with a pending request is offered "Turn on notifications" once on the Subscription tab ("Not now" hides it for good). The token goes to the server with the phone's platform and language, follows a replaced token, and is removed on sign-out before the session ends. Tapping a notification opens the Subscription tab and reloads it; one that arrives while the app is open refreshes the status and shows a banner. New: `DeviceTokensRepository` in the shared packages, an Android notification channel `busin_updates` (English and French names), `npm run dev:push` (sends a real test push to a local user's phone straight through Firebase), and [the push setup guide](docs/guides/push-setup.md). Tests: 111 in the app, 34 in `busin_data`, 13 live checks, 13 Node tests, 202 database tests, all passing. Real bugs the tests caught: a granted permission was reported as denied when the server was briefly unreachable, and the offer card stayed after granting because the cached permission was stale.

Not verified here: delivery of a real push to a phone (needs the key below), and the iOS side (needs an Apple developer account and an APNs key). I used the documented token calls of `firebase_messaging` 17 even though they are deprecated, because the replacement hands out installation IDs and I cannot confirm FCM accepts them as `message.token`; the real-device test will show.

Next: your device test of the whole flow, which is the Phase 3 exit criterion: sign in, subscribe, see approval, show the QR, see history, follow the bus, get a push. After that, I would prepare the Phase 3 milestone PR from `dev` to `main` with the `Closes #N` list when you ask.

Blockers: delivery needs one more file from you, the service account key (below).

Owner must do: in the Firebase console (project `busin-28e6a`) generate a service account key (Project settings, Service accounts, Generate new private key) and keep it outside the repo. The Android app is already registered through the Firebase CLI and `google-services.json` is in place (git-ignored); the app builds with it. Then `npm run dev:push -- <key.json> <your email> approved fr` sends a real push to your phone. Review ADR 0010 and say if the scheduler (option A) is right. Merge #123 so I can open the PRs for slices 3, 4a, 4b and 5. Approve the hosted migrations when ready (trip cancel and archive, stop usage, boardings by day, push notifications). Restart the local backend once so Realtime and storage run. Reinstall the app to see the new icon. The iOS OAuth client is created and wired into `Info.plist` (sign-in untested; needs a Mac to build). iOS push still needs an Apple developer account and an APNs key.
