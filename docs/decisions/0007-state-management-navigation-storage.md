# 0007: State management, navigation and local storage for the Flutter apps

Status: accepted, 2026-10-30. Chosen by the owner after the comparison below.

## Context
The legacy app uses GetX for state, GetX snackbars and dialogs, `go_router` for navigation and `get_storage` for local data. The new student and ops apps need state that is easy to test, scoped to the signed-in user, and cleaned up on sign-out. The audit found the opposite in the legacy app: every controller was created at startup and scan streams survived sign-out (findings H1 and H3).

Local data has three different needs: harmless preferences, secrets (the session and the QR secret), and structured offline data for the ops app (a scan queue and cached rider lists).

## Facts checked on 2026-10-30 (pub.dev)

| Package | Latest | Last published |
|---|---|---|
| get (GetX) | 4.7.3 | 24 Nov 2025 |
| get_storage | 2.1.1 | 27 Feb 2023 |
| flutter_riverpod | 3.4.3 | 3 Sep 2026 |
| flutter_bloc | 9.1.1 | 2 May 2025 |
| go_router | 18.1.2 | 29 Oct 2026 |
| signals | 7.1.0 | 29 May 2026 |
| shared_preferences | 2.5.6 | 5 Oct 2026 |
| flutter_secure_storage | 11.2.0 | 16 Sep 2026 |
| drift | 2.35.3 | 23 Oct 2026 |

Blog posts from 2026 claim the GetX repository was removed in April 2026; sources disagree and this was not verified.

## State management options compared

| | GetX | Riverpod 3 | Bloc / Cubit | Provider |
|---|---|---|---|---|
| Maintenance | Slow | Very active | Active, slower | Maintenance mode |
| Familiar to the owner | Yes | No | No | Somewhat |
| Unit testing | Hard (global lookups, shared singletons) | Easy (override providers per test) | Easy | Medium |
| Scoped lifecycle, disposed on sign-out | Manual | Built in | Manual | Manual |
| Async data, caching, pagination | Hand written | `AsyncNotifier` with loading, error and data | Hand written states | Hand written |
| Boilerplate | Lowest | Low to medium | Highest | Low |
| Works with `go_router` | Yes | Yes | Yes | Yes |

Migration cost does not favour GetX: the new apps use a new backend and new repositories, so every controller is rewritten regardless.

## Decision

| Concern | Choice |
|---|---|
| State management | `flutter_riverpod` 3.x with plain `Notifier` and `AsyncNotifier`. No code generation at first; revisit if boilerplate hurts. |
| Navigation | `go_router`, with the redirect reading the auth state from a provider |
| Preferences (theme, language, flags) | `shared_preferences` |
| Secrets (auth session, QR secret) | `flutter_secure_storage` |
| Structured offline data (ops app only) | `drift` (SQLite) |
| Not used | GetX in any role (state, routes, snackbars, dialogs) and `get_storage` |

`get_storage` writes plain JSON, so it cannot hold the QR secret or session (OWASP MASVS storage rules), and it has not been released since 2023.

## Rules that follow
- Every repository and service is exposed as a provider, so tests replace it with a fake.
- Providers that hold user data watch the auth state, so they reset when the user signs out.
- Screens read state with `ref.watch` and never reach into storage or the backend directly.
- Dialogs and snackbars use Flutter's own `showDialog` and `ScaffoldMessenger`.
- Versions are pinned and bumped in dedicated PRs, like all dependencies.

## Consequences
- The owner learns a new library. Mitigation: small first screens, worked examples in the `busin-flutter` skill, and notes in the build log when a pattern is introduced.
- The lifecycle and testing problems found in the audit are avoided by default instead of by discipline.
- Code generation (`riverpod_generator`) is deferred, so no `build_runner` step is needed yet.
