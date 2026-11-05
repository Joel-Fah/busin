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

Done: Phase 3, slice 3 (branch `phase-3/student-qr`, issue #122), on top of slice 2 (`phase-3/student-subscribe`, issue #121) and slice 1 (PR #120). The stack is three branches deep, so merge #120 first, then I open the slice 2 and 3 PRs into `dev`. The Boarding code tab: the secret is fetched once (only for an approved subscription), kept in the keystore per user and deleted on sign-out; the code is derived on the phone every 30 seconds and drawn dark on white with a countdown; it works offline after the first fetch; with no approved subscription or no connection on first use the tab explains and offers the next step. On Android the screen is secure while the tab shows. Also: a stand-in app icon rendered from the BusIn wordmark (`node tools/render-app-icons.mjs`, Android adaptive and themed, iOS), and buttons in the Flutter apps are a little bolder (weight 700). Tests: 59 in the app, 34 in `busin_ui`, and the live test (10 checks) now proves the database computes the same code the app derives and that rotating a secret kills the old codes.

Next: slice 4, scan history (paginated) and the live bus map. It needs the realtime and map decisions (Mapbox token for the student app, `realtime` in the local backend).

Blockers: none.

Owner must do: merge #120 (then tell me, so I open the next two PRs). Test the Boarding code tab on the device: approve your test subscription in the portal, open the tab, confirm the code changes every 30 seconds and that a screenshot is refused. Reinstall the app to see the new icon (a hot restart does not change it). Replace the stand-in icon with your own artwork when ready. Create the iOS OAuth client when you want iOS. Approve the new migrations on the hosted project when ready (trip cancel and archive, stop usage, boardings by day). Create separate dev and prod Mapbox tokens restricted to your URLs.
