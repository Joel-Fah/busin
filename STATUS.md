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

Done: Phase 3, slice 1 (branch `phase-3/student-shell`, issue #119). `apps/student` exists (Android and iOS, id `com.joelfah.busin.student`) and joins the workspace. It has the shared theme and English and French strings, Google sign-in through `signInWithIdToken`, the session in secure storage, a pure access rule (only a verified student gets in; staff, admins, pending and suspended accounts see a page that says why), a `go_router` redirect that reads it, and a four-tab frame whose screens say "coming soon". `busin_ui` gained the sign-in, blocked-account and navigation strings. 18 app tests (access rules, redirect table, full flows with fakes) pass; `fvm flutter analyze packages apps/student` is clean. The Android native build is not verified: the first Gradle build must download NDK 28.2 (about 1 GB), which stalled here, so the owner's first `fvm flutter run` will do it. Setup guide: [docs/guides/student-app-setup.md](docs/guides/student-app-setup.md). Also merged earlier: the bento overview (#118).

Next: slice 2, subscribing with a stop and a private proof upload, and status tracking.

Blockers: real sign-in on a device needs the Google clients below (owner).

Owner must do: merge the slice 1 PR. Create the Android and iOS OAuth clients and give me the Web client id for `config/dev.json` (see the setup guide); the Android client needs the package `com.joelfah.busin.student` and your debug SHA-1. Approve the new migrations on the hosted project when ready (trip cancel and archive, stop usage, boardings by day). Create separate dev and prod Mapbox tokens restricted to your URLs. Test slice 1 on a device: sign in with a school account, sign out, try a staff account.
