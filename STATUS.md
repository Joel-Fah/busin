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

Done: demo data for local development (branch `phase-2/demo-data`, based on `phase-2/land-stacked`, PR #110). `npm run seed:demo` fills the local database with 66 people, 12 stops, 6 buses, 3 semesters, 84 subscriptions, about 118 trips (some cancelled or archived, one always running) and about 520 boardings, and prints sign-in details for an administrator, a driver and a student. It is repeatable and only touches rows marked as demo. Also found that #102, #104, #106 and #108 were merged into their parent branches rather than into `dev`; #110 brings all of that work into `dev`.

Next: nothing is queued. Look through the portal with the demo data and note what to change.

Blockers: none.

Owner must do: merge #110 first (it contains the sticky toolbar, trip cancel and archive, Docker and stop usage), then tell me so I retarget the demo data PR to `dev` before it is merged (merging it earlier would put it into the old branch again). Run `npm run seed:demo` to try the portal with data. Approve running the new migrations on the hosted project when ready. Create separate dev and prod Mapbox tokens restricted to your URLs.
