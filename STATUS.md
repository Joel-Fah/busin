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

Done: Phase 3, slice 4a, scan history (branch `phase-3/student-history`, issue #124). Slice 2 is open as PR #123 (merge it first). Slice 3 (`phase-3/student-qr`, #122) and this branch sit on top of it, so merge in order and I open each PR as the one below it lands. The History tab lists the student's own boardings newest first, grouped by the day at the school, with stop, direction and time; pages of 20 load as you scroll or when a page does not fill the screen; failures keep the list and offer a retry. New in the shared packages: `ScansRepository.listForStudent` and `TripsRepository.listByIds`. Tests: 71 in the app, 28 in `busin_data`, and the live test (11 checks) now shows RLS returns a student only their own boardings.

Next: slice 4b, the live bus map. Product note: the schema has no link between a student and a bus (no routes yet), so "my bus" will be the buses on a trip right now, defaulting to the bus of the student's latest boarding, with the student's own stop marked. Map through MapLibre and OpenFreeMap as in ADR 0008 (no key, no card); I will not add Mapbox to the app without a restricted token from you.

Blockers: none.

Owner must do: merge #123, then tell me so I open the next PRs. Test on the device: board a trip (scan your code in the ops flow or insert a scan) and check the History tab. Reinstall the app to see the new icon. Replace the stand-in icon when you have your own artwork. Create the iOS OAuth client when you want iOS. Approve the new migrations on the hosted project when ready (trip cancel and archive, stop usage, boardings by day). Create separate dev and prod Mapbox tokens restricted to your URLs.
