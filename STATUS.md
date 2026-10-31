# Status

Updated: 2026-10-30

Current phase: **Phase 0, foundation** ([docs/phases/phase-0-foundation.md](docs/phases/phase-0-foundation.md))

## Phases

| Phase | Goal | State |
|---|---|---|
| 0 Foundation | Monorepo layout, docs, skills, workflow, GitHub setup | In progress |
| 1 Backend | Secure multi-tenant Supabase backend | Built; PRs #51, #53, #55 and the QR PR await review and merge in that order |
| 2 Shared and admin web | Shared Dart packages, admin portal | In progress: busin_core (PR 61) and the portal shell with sign-in and overview (PR in review); portal pages, busin_ui and busin_data next |
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

- Answered (2026-10-30): scanning happens at each stop as students board, so scan GPS is a valid boarding location. At least 2 buses run, and sometimes only 1 when the other is out of service. Stops are fixed today, but the goal is to suggest better stops and routes from student data (see docs/phases/phase-5-insights.md).
- Web hosting for the admin portal (Phase 2 end).
- Whether and when to retire the old ICTU Firebase project (owner decision).

## Findings from the audit that apply only to the legacy app

H6 (release signing fails without `key.properties`), H7 (iOS Google sign-in config), L1 to L3. Not planned for fix in legacy unless the owner asks.



## Last handoff

Phase 1 (backend) is built on four stacked branches, each with a PR: #51 (schema and RLS), #53 (admin functions and scan recording), #55 (private storage), and the rotating QR PR. Merge them in that order; GitHub retargets each to `dev` when the one below it is merged.

Verified: `npx supabase db reset` applies every migration and `npx supabase test db` passes 126 tests covering sign-up rules, row isolation between schools and roles, admin functions, scan checks, private storage and the QR codes.

Owner decisions pending: none blocking. Known limit recorded in ADR 0006: a student can share their QR secret; options are listed there for when usage data shows it matters.

Next: Phase 2 (shared Dart packages and the Next.js admin portal). It needs a decision on the Dart state management approach (an ADR before use) and the admin portal hosting choice, and Google OAuth clients on your personal Google Cloud project before real sign-in can be tested.
