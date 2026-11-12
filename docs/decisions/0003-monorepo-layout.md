# 0003: Monorepo layout

Status: accepted, 2026-10-30.

## Decision
One repository with `apps/` (student, ops, admin_web, legacy), `packages/` (busin_core, busin_data, busin_ui), `supabase/` and `docs/`. Dart uses a pub workspace at the root; Node uses npm workspaces.

`apps/legacy` is outside the pub workspace and keeps its own lockfile and Flutter pin (3.35.6) so it builds as before until it is retired.

## Consequences
Shared code is reused through packages instead of copied. The student app stays small because admin code never enters it.
