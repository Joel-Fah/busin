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

Done: Phase 3, slice 2 (branch `phase-3/student-subscribe`, issue #121; it sits on slice 1, PR #120, so open its PR into `dev` after #120 merges). The Subscription tab: the semester is picked by the school day (`SchoolClock`), the student chooses a stop from a searchable sheet and adds a payment-proof photo (camera or gallery, shrunk on the device and checked by its first bytes), the proof is uploaded to the private bucket in the student's own folder and the request is created with its path. The tab then shows pending, approved (with a button to the boarding code), rejected (with the school's reason and a way to ask again) or expired, with pull-to-refresh. New in the shared packages: `ProofsRepository` (upload and signed URLs) with storage errors mapped to repository exceptions. Tests: 45 in the app, 25 in `busin_data`, and an opt-in live test (7 checks against the local stack with a real student session: upload, signed read-back, request, duplicate refused, other folder and other student refused, wrong type refused by the bucket, no replace or delete). `npm run backend:start` now includes the storage service.

Next: slice 3, the rotating QR code with screenshot protection.

Blockers: none.

Owner must do: merge #120, then slice 2's PR. Restart your local backend once (`npm run backend:stop && npm run backend:start`) so storage runs if you did not already. Test on a device: sign in, subscribe with a stop and a photo, then approve it in the admin portal and pull down to refresh. Create the iOS OAuth client when you want iOS. Approve the new migrations on the hosted project when ready (trip cancel and archive, stop usage, boardings by day). Create separate dev and prod Mapbox tokens restricted to your URLs.
