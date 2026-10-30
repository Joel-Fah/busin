---
name: busin-workflow
description: The BusIn working process - issues, branches, PRs, build log, status, handoff, GitHub Actions budget and when to ask the owner. Load at the start and end of every work session and before opening any issue or PR.
---

# BusIn workflow

## Loop for every change
1. **Issue first.** Open a GitHub issue for the problem or task: a short title, what, why, done when. Labels: one `phase:N`, one `type:*`, one `area:*`, one `priority:*`.
2. **Branch** from `dev`: `phase-N/short-name`. One issue per branch.
3. **Work** following the skill for the area. Run the checks locally.
4. **PR into `dev`** that says what changed, how it was verified, and `Closes #N`. Keep it short. The owner reviews and merges; never merge for them.
5. **Log it**: add a row to `build_log.md` (date, PR, issue, summary, what did not work and how it was resolved) and update `STATUS.md`.

Do not over-write issues and PRs. A few lines each. No emojis. No attribution lines in commits or PR bodies.

## Labels
- `phase:0` to `phase:6`
- `type:bug`, `type:feature`, `type:chore`, `type:docs`, `type:security`
- `area:backend`, `area:student`, `area:ops`, `area:admin-web`, `area:shared`, `area:infra`
- `priority:high` (security, or blocks other work), `priority:medium` (important, not blocking), `priority:low` (polish). Every issue and PR carries exactly one; a PR takes the priority of the issue it closes.

## Commits
Conventional style, imperative, short: `feat(admin): add subscription review table`. Do not commit secrets, build output or local config.

## GitHub Actions budget
Free minutes are limited. Run everything locally first. Workflows trigger only on pull requests into `dev` and `main`, never on every push; use `paths` filters, `concurrency` with cancel-in-progress and `timeout-minutes`; use Linux runners only; no matrices; no scheduled runs unless the owner asks. Add a workflow only when it clearly earns its minutes, and say so in the PR.

## Handoff (end of every session)
Update `STATUS.md` with: what was done (with PR links), what is next, blockers, and what the owner must do (device tests, accounts, approvals). Leave the branch committed and the working tree clean. Never leave half-applied changes unexplained.

## Ask the owner first
Destructive actions, merging, pushing to `main`, cloud or account changes, running migrations on a hosted project, paid services, new vendors, and changes to recorded decisions. When unsure, ask; do not decide on the owner's behalf.

## Decisions
Record significant choices as ADRs in `docs/decisions/` (context, decision, consequences). Superseding a decision needs owner approval and a new ADR that links the old one.

## Phases
Scope and exit criteria live in `docs/phases/`. Do not start a phase until the previous one meets its exit criteria or the owner says otherwise.
