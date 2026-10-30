# Status

Updated: 2026-10-30

Current phase: **Phase 0, foundation** ([docs/phases/phase-0-foundation.md](docs/phases/phase-0-foundation.md))

## Phases

| Phase | Goal | State |
|---|---|---|
| 0 Foundation | Monorepo layout, docs, skills, workflow, GitHub setup | In progress |
| 1 Backend | Secure multi-tenant Supabase backend | Not started |
| 2 Shared and admin web | Shared Dart packages, admin portal | Not started |
| 3 Student app | Lightweight student app | Not started |
| 4 Ops app | Scanner and driver mode | Not started |
| 5 Insights | Density map, pickup and route suggestions | Not started |
| 6 Scale | More schools, payments, hardware tracker | Not started |

## Phase 0 checklist

| Item | State | Issue / PR |
|---|---|---|
| Move current app to `apps/legacy` (still analyzes clean) | Done on branch `phase-0/restructure` | [#47](https://github.com/Joel-Fah/busin/pull/47) |
| Root workspace files (pub workspace, npm, `.nvmrc`, `.fvmrc`, `.gitignore`) | Done on branch | [#47](https://github.com/Joel-Fah/busin/pull/47) |
| CLAUDE.md, ARCHITECTURE.md, STATUS.md, build_log.md, README.md | Done on branch | [#47](https://github.com/Joel-Fah/busin/pull/47) |
| Project skills in `.claude/skills/` | Done on branch | [#47](https://github.com/Joel-Fah/busin/pull/47) |
| `docs/` phases, decisions, guides | Done on branch | [#47](https://github.com/Joel-Fah/busin/pull/47) |
| Issue and PR templates, labels, minimal CI | Done: templates, labels, CI check | [#47](https://github.com/Joel-Fah/busin/pull/47) |
| Issues for audit findings | Done: #33 to #46 | opened |

## Blockers (owner)

None. GitHub CLI, Java 21, Docker Desktop and Flutter 3.47.9 are installed and verified.

## Open questions

- Where does scanning happen: at boarding, inside the bus, or at the campus gate? Decides density inputs (Phase 4 and 5).
- How many buses, and are routes fixed? Shapes the `trips` schema (Phase 1).
- Web hosting for the admin portal (Phase 2 end).
- Whether and when to retire the old ICTU Firebase project (owner decision).

## Findings from the audit that apply only to the legacy app

H6 (release signing fails without `key.properties`), H7 (iOS Google sign-in config), L1 to L3. Not planned for fix in legacy unless the owner asks.

## Last handoff

Phase 0 work is committed on the local branch `phase-0/restructure`. The foundation PR is open: #47 into `dev`, awaiting owner review. Audit issues are #33 to #46.

Verified: the legacy app analyzes as before (0 errors, 5 warnings); `npm run check` passes; `fvm dart pub get` resolves the workspace on Flutter 3.47.9; the Supabase CLI 2.122.0 runs through npx; `gh` is signed in; Docker Desktop and Java 21 are installed.

Next: after #47 is merged, start Phase 1 (backend) on a new branch from `dev`.
