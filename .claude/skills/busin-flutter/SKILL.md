---
name: busin-flutter
description: Conventions for the BusIn Flutter apps and Dart packages (student, ops, busin_core, busin_data, busin_ui). Load before writing or reviewing any Dart or Flutter code.
---

# BusIn Flutter and Dart

## Toolchain
- Flutter is pinned in `.fvmrc` (3.47.9, Dart 3.13). Always run `fvm flutter ...` and `fvm dart ...`. Never use a global Flutter.
- Android builds use Java 21. The release signing config must not fail when `key.properties` is absent; fall back to debug signing.
- Upgrades are their own PR: `fvm use`, `pub upgrade`, analyze, test, smoke test.

## Layout and layering
- Dart pub workspace at the repo root. Each member has `resolution: workspace`.
- `busin_core`: pure Dart (no Flutter, no Supabase). Models, enums, value objects, repository interfaces, validation.
- `busin_data`: the only Dart code that imports `supabase_flutter`. Implements the core interfaces.
- `busin_ui`: theme, widgets, l10n. No data access.
- Apps depend on the packages; packages never depend on apps. `apps/legacy` is read-only reference and stays outside the workspace.

## Code style
- `flutter_lints` enabled in every package through `analysis_options.yaml`. Zero analyzer warnings in new code.
- Immutable models with `fromMap` and `toMap` (or json), covered by tests. Stored times come from the server in UTC; never trust the device clock.
- Small files and widgets. Split screens past about 400 lines. The legacy app has screens of 1,000 to 2,300 lines; do not copy that.
- No emojis, no `print`. Use `debugPrint` inside `kDebugMode`, and never log personal data.
- Strings go through localization (EN and FR). Colors and sizes come from the theme (see `busin-design-system`).

## State and navigation
- Choose one state management approach for the new apps in Phase 2 and record it in an ADR before using it. The legacy app uses GetX with every controller created at startup; do not reproduce that.
- Create user-scoped state after sign-in and dispose it on sign-out. Route guards read the role from the session. Admin screens do not exist in client apps.
- Declarative routing with a redirect for auth state.

## Data and least-load
- Repository methods take explicit parameters and return typed models. Select named columns, paginate with `range`, and filter Realtime subscriptions.
- Cache read-only reference data (stops, semester) in memory for the session.
- Ops app: SQLite local queue, idempotent sync, scans keyed by trip and student.

## Config
- Public values only, through `--dart-define-from-file=config/<env>.json` and `String.fromEnvironment`. No `.env` asset, no `flutter_dotenv`.

## Platform
- Android first. Complete the iOS Google client id and URL scheme before claiming iOS support.
- Location: ops app only, requested at the moment of use. Foreground service for driver mode.
- Block screenshots on the QR screen.

## Testing
- Claude writes and runs unit tests for models, repositories (with fakes), QR derivation and sync logic: `fvm dart test` or `fvm flutter test`.
- Widget tests for critical reusable widgets. The owner does device and emulator testing; list manual test steps in the PR.

## Done checklist
- [ ] `fvm flutter analyze` clean
- [ ] Tests added or updated and passing
- [ ] Light and dark checked, EN and FR strings present
- [ ] No admin code or all-collection query in a client app
- [ ] Manual test steps listed for the owner
