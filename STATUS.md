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

Done: the remaining page redesigns in one PR (branch `phase-2/pages-redesign`): People (search with placeholder, role tabs with counts, profile with the custom role dropdown and danger-styled suspend), Trips (status tabs with counts, schedule and edit forms with the custom dropdowns and date-time picker), Boardings (custom stop and day filters), Semesters and Buses (lists, forms with the custom fields), the Overview (cards that lead to where each figure lives, the review count set apart when something waits), and the sign-in, no-access, dev sign-in and not-found pages (one shared shell). Each list page has a header with help examples in English and French, an illustrated empty state, a shimmer loading state and the shared table and pager. A page past the last one is now an empty list, not an error, on all of them. The unused legacy styles are removed (about 350 lines). The real checkbox, radio and switch inputs now lie invisibly over their faces, so real clicks land on them.

Next: trip cancel and archive (needs a small audited database function, applied locally; hosted needs your approval), then Docker for the portal. Then phase 3, the student app, once the portal is accepted.

Blockers: none.

Owner must do: review and merge the pages PR and try every page on your tablet and phone; decide whether stops should show how many students use each (needs a small database function); the Mapbox usage and token tasks still apply.
