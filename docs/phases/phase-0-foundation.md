# Phase 0: foundation

Goal: a repository, rules and tooling the later phases can build on without drifting.

## Scope
- Monorepo layout: `apps/`, `packages/`, `supabase/`, `docs/`, with the current app frozen in `apps/legacy`.
- Root documents: CLAUDE.md, ARCHITECTURE.md, STATUS.md, build_log.md, README.md.
- Project skills in `.claude/skills/`.
- Decision records and a local setup guide.
- GitHub setup: issue and PR templates, labels, issues for the audit findings, a minimal low-cost CI check.

## Exit criteria
- `apps/legacy` analyzes with the same result as before the move (0 errors, 5 warnings).
- `npm run check` passes (no emoji, all relative Markdown links resolve).
- `fvm dart pub get` resolves the workspace.
- Issues exist for the audit findings that still apply, and the foundation PR is open for review.

## Depends on
GitHub CLI installed and signed in (owner).
