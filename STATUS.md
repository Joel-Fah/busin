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

Done: PR 3 of the admin portal redesign (components), on branch `phase-2/components`. Side sheet and modal now float with a margin all round (the help sheet included), with a rough marker highlight under the title. Added tabs with tone counters and the elastic sliding highlight (shared with the navigation bar), an action menu that opens toward free space, a dropdown, date, time and date-time fields, checkbox, radio group and switch, all shown in the styleguide with their states. Verified with typecheck, lint, 140 unit tests, 148 browser tests and a production build.

Next: the Stops redesign with the Mapbox switch (`MAPBOX_API_KEY`), then the other page redesigns using these components (tabs with counters on Subscriptions, People and Trips), then trip cancel and archive, then Docker. The Mapbox switch moved from the components PR to the Stops PR, where the map is shown.

Blockers: none for development. Map tiles did not load in this laptop's test browser and the dev server logs "Worker failed to load" for the map; to be checked in the Stops PR.

Owner must do: review and merge the components PR; keep the Mapbox key a public, URL-restricted `pk.` token; confirm the Bevellier font files and the unused `components/NavLinks.tsx` can be deleted; add the Google keys to `supabase/.env` when ready to test real sign-in.
