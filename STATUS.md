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

Done: Phase 3, slice 5a, the server side of push notifications (branch `phase-3/push-backend`, no issue yet). It needs no Firebase project, so I built it while waiting for yours: migration `20261105150000_push_notifications.sql` (device tokens with register and unregister functions, an outbox filled by a trigger when a subscription is approved or rejected, and service-only claim, complete and drop functions), 36 new pgTAP tests (202 database tests in all, passing), the sender logic as plain TypeScript with 13 Node tests (`npm run test:functions`), the Deno entry point `supabase/functions/send-push` (not runnable here, not deployed), and [ADR 0010](docs/decisions/0010-push-notifications.md). Not applied to any hosted project. Earlier slices: 2 is PR #123 (open); 3 (`phase-3/student-qr`), 4a (`phase-3/student-history`) and 4b (`phase-3/student-bus`) sit on top of it; this branch sits on 4b.

Next: slice 5b, the app side (Firebase SDK, permission, register the token on sign-in and remove it on sign-out, open the right tab from a tap, a channel named `busin_updates`). It needs the Firebase project.

Blockers: slice 5b needs your Firebase project. The sender needs a trigger decision (ADR 0010, option A recommended) and, on the hosted project, your approval for the migration and for enabling `pg_cron` and `pg_net`.

Owner must do: review ADR 0010 and say whether option A (scheduler) is right. Create the Firebase project (personal Google account, ADR 0004) with an Android app (package `com.joelfah.busin.student`), and tell me when it exists. Merge #123 so the later PRs can open. Approve the new migrations on the hosted project when ready (trip cancel and archive, stop usage, boardings by day, push notifications). Restart the local backend once so Realtime and storage run (`npm run backend:stop && npm run backend:start`). Test on the device: `npm run dev:bus` and My bus; the History, Boarding code and Subscription tabs. Reinstall to see the icon. Create the iOS OAuth client when you want iOS.
