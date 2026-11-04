# Status

Updated: 2026-11-03

Current phase: **Phase 2, shared packages and admin portal** ([docs/phases/phase-2-shared-and-admin-web.md](docs/phases/phase-2-shared-and-admin-web.md))

## Phases

| Phase | Goal | State |
|---|---|---|
| 0 Foundation | Monorepo layout, docs, skills, workflow, GitHub setup | Done and merged into `dev` |
| 1 Backend | Secure multi-tenant Supabase backend | Done and merged into `dev` (126 database tests) |
| 2 Shared and admin web | Shared Dart packages, admin portal | In progress. Merged: busin_core, portal shell and sign-in, subscription review, people, stops with a map, semesters, buses, trips, boardings. In progress: admin portal redesign in five PRs (foundation and styleguide in review; then shell and navbar, components and Mapbox, page redesigns, trip cancel and Docker). Next after that: stop photos, busin_ui, busin_data |
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

Done: trip cancel and archive (branch `phase-2/trip-cancel-archive`, stacked on the sticky toolbar PR #102). Administrators no longer delete trips: the delete grant and policy are gone, because boardings point to a trip. Instead, `admin_cancel_trip` cancels a trip that has not started (optional reason, kept in the audit log) and `admin_set_trip_archived` archives a completed or cancelled trip or brings it back; both are audited, admin only and limited to the school. In the portal, a trip that has not started has a Cancel this trip section (with the reason), a finished or cancelled trip has Archive or Restore, archived trips leave every list and have an Archived tab with its own count. 23 new database tests, 3 unit tests and 4 browser tests. Applied to the local database only.

Next: Docker for the portal (last step of the redesign plan).

Blockers: none.

Owner must do: merge #100, then #102, then this PR (each is based on the previous branch; retarget to `dev` with `gh pr edit --base dev` once its parent merges). Before this is used on the hosted project, approve running `supabase/migrations/20261104120000_trip_cancel_and_archive.sql` there (I have not run it). Note the migration revokes delete on trips for administrators.
