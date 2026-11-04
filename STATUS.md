# Status

Updated: 2026-11-03

Current phase: **Phase 2, shared packages and admin portal** ([docs/phases/phase-2-shared-and-admin-web.md](docs/phases/phase-2-shared-and-admin-web.md))

## Phases

| Phase | Goal | State |
|---|---|---|
| 0 Foundation | Monorepo layout, docs, skills, workflow, GitHub setup | Done and merged into `dev` |
| 1 Backend | Secure multi-tenant Supabase backend | Done and merged into `dev` (126 database tests) |
| 2 Shared and admin web | Shared Dart packages, admin portal | **Done** (pending the merge of the shared packages PR). Admin portal merged into `dev`; `busin_core` has the models and the repository interfaces, `busin_data` the Supabase implementations, `busin_ui` the design system. Flutter 3.47.9 through fvm resolves, analyzes and tests the workspace |
| 3 Student app | Lightweight student app | Not started |
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

Done: the admin overview is now a bento grid (branch `phase-2/overview-bento`, issue #117). Beside the four counts it shows boardings for the last 14 days with a week-on-week change, the subscription status mix, the open semester with progress, today's trips, the requests that have waited longest, and buses and stops. New read-only database function `admin_boardings_by_day` (admin only, runs under Row Level Security, school timezone, capped at 90 days) with a pgTAP test; everything else is counts or short capped lists. Charts are plain HTML, no new dependency. Test 004 now counts only its own school, because the demo data made it fail. Unit, database and the portal and shell end-to-end specs pass.

Next: Phase 3, the student app (see docs/phases/). The mobile apps take their look from `busin_ui` (same palette, Plus Jakarta Sans, radius scale, contour), so they match the portal.

Blockers: none.

Owner must do: merge the PR. Approve the new migrations on the hosted project when ready (trip cancel and archive, stop usage, boardings by day). Create separate dev and prod Mapbox tokens restricted to your URLs. Say when to start Phase 3.
