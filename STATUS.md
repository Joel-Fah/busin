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

Done: the Subscriptions redesign (branch `phase-2/subscriptions-redesign`). A large header with a help sheet of real situations; tabs showing how many subscriptions are behind each status, in the right tone (head-only counts, no rows downloaded); a refreshed list with avatars and status chips that keeps real table semantics; a friendly empty state with an illustration, and a shimmer loading state shaped like the page; a review page on the design system (back button, details card, payment proof card, Approve button, a danger Reject with a proper textarea field with an icon and placeholder). Behaviour, actions and security are unchanged. Also fixed: asking for a page past the last one showed a "could not load" error instead of an empty list. The illustrations moved from the styleguide folder to `public/illustrations`; the bar's Subscriptions tab uses Ticket03Icon. Verified with typecheck, lint, 188 unit tests, a clean build and the related browser specs (Subscriptions 15, shell and styleguide included: 57 passing).

Next: the remaining page redesigns on the same pattern, People next (tabs with counts and the search field), then Trips, Boardings, Semesters, Buses, Overview and login; then trip cancel and archive, then Docker.

Blockers: none.

Owner must do: review and merge the Subscriptions PR. The same empty-page error exists on People, Trips and Boardings and will be fixed as each is redesigned.
