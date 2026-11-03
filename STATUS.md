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

Done: Mapbox map provider (PR #93, part 1 of the Stops redesign), stacked on the components PR #91. The portal uses Mapbox when `MAPBOX_API_KEY` is a valid public token and falls back to MapLibre otherwise. Verified with typecheck, lint, 163 unit tests and the 12 stops browser tests running against the real Mapbox map (clicks, pin drag, coordinates).

Next: part 2, the Stops page redesign (full-page map, stops listed in the navigation bar's dock, add and edit in the floating sheet), then the other page redesigns, then trip cancel and Docker.

Blockers: none. Keep the Mapbox token restricted to the portal's address in your Mapbox account and watch map loads against the free allowance.

Owner must do: merge #91 then #93; restrict the Mapbox token by URL; confirm the Bevellier font files and the unused `components/NavLinks.tsx` can be deleted.
