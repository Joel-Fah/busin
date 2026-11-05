# Status

Updated: 2026-11-03

Current phase: **Phase 2, shared packages and admin portal** ([docs/phases/phase-2-shared-and-admin-web.md](docs/phases/phase-2-shared-and-admin-web.md))

## Phases

| Phase | Goal | State |
|---|---|---|
| 0 Foundation | Monorepo layout, docs, skills, workflow, GitHub setup | Done and merged into `dev` |
| 1 Backend | Secure multi-tenant Supabase backend | Done and merged into `dev` (126 database tests) |
| 2 Shared and admin web | Shared Dart packages, admin portal | **Done and merged into `dev`.** Admin portal (with the bento overview); `busin_core` has the models and the repository interfaces, `busin_data` the Supabase implementations, `busin_ui` the design system. Flutter 3.47.9 through fvm resolves, analyzes and tests the workspace |
| 3 Student app | Lightweight student app | **In progress.** Slice 1 (shell, Google sign-in, role gate) on branch `phase-3/student-shell`; see [apps/student](apps/student/README.md) for the slices |
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

Done: the mobile redesign, PR A, the design system foundation (branch `phase-3/ui-foundation`, issue #127), on top of the push branches. After your feedback that the student app looked like stock Material, the portal's design language is now ported natively into `packages/busin_ui` ([ADR 0011](docs/decisions/0011-mobile-design-system.md)): the stitched `Contour` (with the portal's presets, sliding on press), `Grain`, the `MarkedText` underline, `BusinCard`, a restyled `BusinButton` (squeeze, haptic, thread), `StatusChip` with icons, framed `EmptyState` with 3D illustrations, `Skeleton`, `showBusinSheet`, `StaggeredIn`, `BusinHaptics`, the wordmark and the illustrations, and navigation that adapts to the window: a floating glass bar with an elastic highlight on phones and portrait tablets, a slim rail and two-pane `SplitView` from 840 dp (`AdaptiveScaffold`, `BusinLayout`). Nothing in the app screens uses the new look yet; that is B1 to B5. A debug-only styleguide shows all of it: `cd apps/student && fvm flutter run --dart-define-from-file=../../config/dev.json --route /styleguide` (I installed a debug build on your tablet and reviewed it in portrait and landscape, then restored your rotation setting). Tests: 66 in `busin_ui` (thread maths, nested radius, marker, breakpoints, scaffold bar-or-rail, elastic highlight, reduced motion, haptics, contrast of the glass bar, banner and insight cards), 12 layout tests running every styleguide section at four sizes and 160% text with no overflow, 111 in the app. Real bugs found by the tests: the scaffold had no Material ancestor for the bar's ink effects, and the styleguide banner and header overflowed with large text.

Next: B1, the shell, sign-in (photo hero) and gate screens, then B2 subscription, B3 boarding code, B4 history, B5 my bus, B6 polish, each its own PR as agreed.

Product decisions in the plan (tell me if you want any changed): sign-in uses the legacy night-bus photo; the bar shows short labels ("Code" for the boarding code) with full labels for screen readers.

Blockers: none.

Owner must do: review the styleguide on the tablet (portrait and landscape) and a phone, in light and dark, and tell me what to change before I build B1 to B5 on it. Merge #123 so the PRs for slices 3, 4a, 4b, 5 and this one can open in order. Also still open from before: the push test (service account key, then `npm run dev:push`), ADR 0010 review, approval for the four hosted migrations, the iOS push setup when you want it, and Mapbox tokens for the portal.
