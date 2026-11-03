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

Done: PR 2 of the admin portal redesign, on branch `phase-2/shell-navbar` (stacked on the foundation PR #87, so its PR is opened after #87 merges). The sidebar is replaced by a floating bottom navigation bar with a drop-up menu on tablets in portrait and phones; the profile page holds theme, language and sign out; the logo-draw intro and bar reveal play once per session (off for reduced motion); pages get a large headline with a help side sheet (overview first). The styleguide rail now sits in the page margin. The bar has a labelled profile tab, an elastic sliding indicator and roomier tabs; sign out uses the danger style; the styleguide is shown without the bar, with a bento grid of bus photos and a Texture section. Verified with typecheck, lint, 140 unit tests, 132 browser tests and a production build with no warnings.

Next: open the PR for this branch once #87 merges, then PR 3 (components such as tabs with counters and the elastic indicator, dropdowns, pickers, checkboxes, radios, and the Mapbox switch with `MAPBOX_API_KEY`), then page redesigns starting with Stops, then trip cancel and Docker.

Blockers: none for development. Map tiles did not load in this laptop's test browser and the dev server logs "Worker failed to load" for the map; to be checked in the Mapbox PR.

Owner must do: merge #85 and #87; try the new bar on your tablet and phone and tell me what to change; confirm the Bevellier font files and the unused `components/NavLinks.tsx` can be deleted; keep the Mapbox key a public, URL-restricted `pk.` token; add the Google keys to `supabase/.env` when ready to test real sign-in.
