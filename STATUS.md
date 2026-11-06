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

Done: the opening logo animation (branch `phase-3/ui-intro`, issue #130, on top of the B2 branch). On a cold start the BusIn logo draws itself once on the teal splash (about 2.8 s, a tap skips it, reduced motion shows the finished mark for half a second); after it the finished mark stays with a thin progress bar while the session loads. The native launch screen (generated with `flutter_native_splash`, teal with the same wordmark at 144 dp, Android 12 included, dark variants, iOS storyboard) and the animated mark are the same size and in the same place, so the hand-off should be invisible. The path data comes from the portal logo (`node tools/export-brand-paths.mjs`; splash image: `node tools/render-app-icons.mjs`). The router holds every page on the splash until the intro is done (`introDoneProvider`); tests switch it off with `introEnabledProvider`.

Verified: analyze clean, student 173 tests and busin_ui 95 tests pass, debug APK installed on the connected phone: the native splash shows teal with the mark, then sign-in. I could not capture the animation itself in a debug build (slow start), so the hand-off needs your eyes.

Next: B3 boarding code, B4 history, B5 my bus, B6 polish.

Blockers: none.

Owner must do: cold-start the app on a phone and the tablet and tell me if the splash-to-drawing hand-off jumps (size, position, flash); a release build is smoother than debug. Merge #123 so the stacked PRs open in order. Earlier items still stand: approve the hosted migrations, review ADR 0010, Firebase service account key for the push test, iOS push setup when wanted.
