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

Done: the Stops page redesign (branch `phase-2/stops-page`). Full-screen map; stops as two-row tiles in the navigation bar's dock that scroll sideways (the bar keeps one width on every page); a floating non-blocking sheet to add and edit with the map still clickable; "View all stops" splits the screen three to one, map shrinking as a rounded card, list on the background with search; numbered cluster bubbles (9+) that follow the zoom; your location as a blue dot with a pinging wave and approximate distances; the focused stop pings the same way. Also: MapLibre's blank map fixed (the worker is served as a static file), tooltips in the design system replacing the browser's, fading scrollbars, the Edit02 and Gps01 icons, and the old Stops add and edit pages now redirect into the sheet. Verified with typecheck, lint, 187 unit tests, a clean build and the browser suite (195 passing in the last full run, then the one test that depended on other specs' data was made independent and the Stops spec re-run: 33 passing).

Next: the other page redesigns on these components (tabs with counters on Subscriptions, People and Trips; Overview; Trips, Boardings, Semesters, Buses; login), then trip cancel and archive, then Docker.

Blockers: none.

Owner must do: review and merge the Stops PR; try the page on your tablet and phone; decide whether stops should show how many students use each (it needs a small database function, so I have not added it); the Mapbox usage and token tasks from the cost PR still apply.
