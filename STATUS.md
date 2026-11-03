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

Done: PR 1 of the admin portal redesign. Tailwind, Plus Jakarta Sans, Hugeicons and GSAP are installed and pinned; design tokens (shape, contour, motion) and a system, light or dark theme choice exist; first components (button, card, chip, field with icon, shimmer, theme toggle, empty state) are built; the contour is a stitched thread that slides forward and back on hover for buttons, links and empty states; the Stops icon weight is fixed; a logo-only themed favicon is added; and the hidden admin-only page at `/styleguide` (banner photo, sticky labelled section rail, real photos and the 3D set) documents brand, voice, colour (with contrast results), type, shape, contour, icons, motion and the components. ADR 0009 records the stack. Verified with typecheck, lint, 133 unit tests, 98 browser tests (1 pending until the new navigation lands) and a production build. Plain direction labels (Going to school, Going home) are in a separate small PR.

Next: PR 2, the floating bottom navigation bar, profile page (theme, language, sign out), logo intro and the page header with help sheet. Then components and the Mapbox switch, then the page redesigns starting with Stops, then trip cancel and Docker.

Blockers: none for development. The map tiles did not load in this laptop's test browser, and the dev server logs "Worker failed to load" for the map; to be checked in the Mapbox PR.

Owner must do: review and merge the redesign foundation PR and the direction labels PR; the Mapbox key is in `apps/admin_web/.env.local` as MAPBOX_API_KEY (it must be a public pk. token, URL-restricted); confirm the Bevellier font files may be deleted; add the Google keys to `supabase/.env` when ready to test real sign-in.
