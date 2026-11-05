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

Done: redesign B1, the shell, sign-in and gate screens (branch `phase-3/ui-shell`, issue #128, on top of the foundation branch). The signed-in frame is now `AdaptiveScaffold`: a floating glass bar on phones and portrait tablets, a rail with the logo in landscape, short labels ("Code" for the boarding code, the full name for screen readers); tab screens keep clear of the bar and sit in a reading column (640) on tablets. Sign-in is the photo hero: the night-bus photo under a teal gradient, the wordmark, the new headline with the marker under its last line, and a tilted orange call to action with grain and a stitched edge; on wide screens the photo takes the left and the words the right. Splash is the wordmark settling on the seed teal with grain; blocked and problem screens are framed empty states with illustrations (staff, waiting, blocked). The bottom sheet is now fully floating (clear of the screen on every side, all corners rounded) with a single handle outside, above the card, and opens above the bar; the stop and photo-source sheets use it. Debug-only previews: `--route /styleguide/sign-in` (also `/splash`, `/blocked`, `/problem`). Tests: 71 in `busin_ui`, 153 in the app (including sign-in, gate screens and the signed-in frame at four sizes, two languages and 160% text, plus sheets above the bar and the reading column). Real bugs the tests caught: sheets opened under the floating bar (now on the root navigator), the status card header overflowed on a 360 dp phone, empty states and the wide sign-in panel did not scroll when too short, and my first marker change broke intrinsic sizing (now computed at paint time).

Noted: after I reinstalled debug builds the tablet launched on sign-in (signed out). I could not see why from here; please tell me if it happens again after a plain reinstall, because the session should survive one.

Next: B2 the subscription tab (welcome banner, status card with a stage line, contoured form fields, tablet two-pane), then B3 boarding code, B4 history, B5 my bus, B6 polish.

Blockers: none.

Owner must do: review sign-in and the shell on the tablet and a phone (the previews: `cd apps/student && fvm flutter run --dart-define-from-file=../../config/dev.json --route /styleguide/sign-in`), say what to change. Sign in again on the tablet if needed. Merge #123 so the PRs open in order. Still open from before: the push test (service account key, `npm run dev:push`), ADR 0010, hosted migration approvals, iOS push setup, Mapbox tokens for the portal.
