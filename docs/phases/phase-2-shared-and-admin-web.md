# Phase 2: shared packages and admin web

Goal: the shared Dart layer and a working admin portal.

## Scope
- `busin_core`: models, enums, value objects, repository interfaces, validation (with unit tests).
- `busin_data`: Supabase repositories with explicit column selection and pagination.
- `busin_ui`: theme, tokens, fonts, shared widgets and EN/FR localization ported from the legacy app.
- `apps/admin_web`: Next.js 16 portal. Auth, school settings, people, stops with map picker, semesters, subscription review, buses and trips, scans list (paginated).
- Vitest for logic and Playwright for flows, run against the local Supabase stack.
- Flutter upgrade tooling confirmed on the pinned version.

## Exit criteria
- An admin can run a semester end to end against local Supabase: create semester and stops, review a subscription, see scans.
- Package unit tests and portal tests are green.

## Depends on
Phase 1.
