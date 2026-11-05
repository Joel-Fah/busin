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

Done: Phase 3, slice 4b, the live bus (branch `phase-3/student-bus`, issue #125), on top of 4a (`phase-3/student-history`, #124), slice 3 (`phase-3/student-qr`, #122) and slice 2 (PR #123, open). The stack is four branches deep; merge #123 first and I open each next PR as the one below lands. The My bus tab shows the buses on a trip now, the live position of one on a MapLibre map (OpenFreeMap, no key) with the stops and the student's own stop marked, how old the position is, and its speed; a position older than two minutes is marked stale; a failed feed says so with a retry; the Realtime subscription is filtered to that one bus on the server and dropped while the tab is hidden. New in the shared packages: `TripsRepository.listActive` and `BusesRepository.listByIds`. Two real bugs found and fixed by tests: refreshing a provider inside `didChangeDependencies` threw (fixed in the bus and QR tabs; they now refresh after the frame), and a failed history page was retried by a late scroll event. Tests: 88 in the app, 31 in `busin_data`, and the live test (12 checks) now proves the bus feed carries only the followed bus. New dev tool: `npm run dev:bus` moves a bus along the stops. `npm run backend:start` now includes Realtime and storage.

Next: slice 5, push notifications (FCM). That needs your Firebase project: see below. After that, Phase 3 exit: your device test of the whole flow.

Product decisions to confirm: (1) With no student-to-bus link in the schema, "my bus" is the bus of the last boarding, else the most recently started running trip. If buses will follow fixed routes, a route table is the real answer (Phase 5 territory). (2) The map uses MapLibre and OpenFreeMap, as ADR 0008 says for the free default; Mapbox in the app would need your restricted token.

Blockers: none for the code; slice 5 needs the Firebase project.

Owner must do: merge #123 (then tell me). Restart the local backend once more so Realtime runs (`npm run backend:stop && npm run backend:start`). To see the bus move on your phone: `npm run dev:bus` in a terminal while a trip is running (the demo data has one), then open My bus. Create the Firebase project for push notifications (FCM) under your personal Google account as ADR 0004 says, add an Android app with package `com.joelfah.busin.student`, and send me the `google-services.json` path only if you want me to wire it in (it holds no secret that matters but keep it out of git until we decide). Reinstall the app to see the icon. Create the iOS OAuth client when you want iOS. Approve the new migrations on the hosted project when ready (trip cancel and archive, stop usage, boardings by day). Create separate dev and prod Mapbox tokens restricted to your URLs (the portal; the app does not need one).
