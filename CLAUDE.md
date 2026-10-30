# BusIn: working rules

BusIn manages campus bus subscriptions, boarding scans and bus tracking for schools. It is being rebuilt from a single Flutter + Firebase app into separate tiers on a shared Supabase backend. Read [ARCHITECTURE.md](ARCHITECTURE.md) for the design and [STATUS.md](STATUS.md) for where work stands before starting anything.

## Where code goes

| Path | What | Stack |
|---|---|---|
| `apps/student/` | Student app | Flutter (Android, iOS) |
| `apps/ops/` | Staff scanner and driver mode | Flutter (Android) |
| `apps/admin_web/` | Admin portal | Next.js 16, TypeScript |
| `apps/legacy/` | The original app, frozen. Reference only (uses GetX, which new code must not) | Flutter 3.35.6 + Firebase |
| `packages/busin_core/` | Domain models, enums, repository interfaces. Pure Dart | Dart |
| `packages/busin_data/` | Supabase implementations of the repositories | Dart |
| `packages/busin_ui/` | Design system, shared widgets, l10n | Flutter |
| `supabase/` | Migrations, RLS policies, functions, Edge Functions, tests | Postgres, Deno |
| `docs/` | Phases, decisions (ADRs), guides, audit | Markdown |

Do not add features to `apps/legacy`. Port what you need from it into the new tiers.

## Non-negotiable rules

1. **No emojis** anywhere: code, comments, UI strings, commit messages, issues, PRs, docs. `npm run check:emoji` enforces it.
2. **Versions**: use LTS or the pinned stable release. Flutter is pinned in `.fvmrc` (always run it through `fvm`), Node 24 LTS in `.nvmrc`, Java 21 LTS for Android. Never bump a minor or major version inside a feature PR. Upgrades get their own issue and PR.
3. **Security lives on the server.** Every table has Row Level Security. Roles and school come from the JWT claims, never from a field the user can write. No secrets in any client. Follow the [busin-security skill](.claude/skills/busin-security/SKILL.md).
4. **Least data.** Each app and each user loads only what they need: select explicit columns (never `select('*')` in apps), paginate lists, filter Realtime subscriptions, load admin code only in the admin portal, and start controllers only after the role is known.
5. **Multi-tenant from day one.** Every tenant-owned row has `school_id`. Never hard-code a school or an email domain.

## Workflow

Full details are in the [busin-workflow skill](.claude/skills/busin-workflow/SKILL.md). In short:

1. Every problem or task gets a GitHub issue first (short: what, why, done when), labeled with phase, type, area and priority (high, medium or low).
2. Work on a branch `phase-N/short-name`. One issue per PR, PR into `dev`. The owner reviews and merges.
3. After each PR, add a row to [build_log.md](build_log.md) (including what didn't work and how it was fixed) and update [STATUS.md](STATUS.md).
4. Issue and PR bodies stay short. No attribution lines.
5. **Keep GitHub Actions usage low** (the free minutes are limited). Run checks locally first. CI workflows trigger only on pull requests into `dev` and `main` (never on every push), use path filters so a tier only runs when its files change, cancel superseded runs with `concurrency`, and avoid macOS runners and matrix builds. Add a workflow only when it clearly earns its minutes.
6. End every session with a handoff note in STATUS.md: done, next, blockers, what the owner must do.

## Ask the owner first

Do not do any of these without explicit approval in the current conversation:
- anything destructive (deleting data, files, branches, force-push, rewriting history);
- merging PRs, pushing to `main`, or publishing releases;
- creating or changing cloud resources, accounts, billing, OAuth clients or DNS;
- running migrations against a hosted Supabase project;
- adding a paid service or a new third-party vendor;
- changing a decision recorded in `docs/decisions/`.

## Testing

| Tier | Who runs what |
|---|---|
| `supabase/` | pgTAP tests for every RLS policy and function (`npx supabase test db`). Claude runs them. |
| `apps/admin_web/` | Vitest for logic, Playwright for flows. Claude runs them. |
| `packages/*` | Unit tests (`fvm dart test`). Claude runs them. |
| `apps/student/`, `apps/ops/` | Unit tests written and run by Claude. Device and emulator testing is done by the owner. |

## Skills

Project skills live in [.claude/skills/](.claude/skills/). Load the matching one before working in an area:
`busin-product`, `busin-design-system`, `busin-security`, `busin-flutter`, `busin-supabase`, `busin-admin-web`, `busin-workflow`.

## Commands

```bash
fvm dart pub get                 # resolve the Dart workspace (packages + new apps)
npm install                      # Node tooling (Supabase CLI, admin portal later)
npm run check                    # emoji + markdown link checks
npx supabase start               # local backend (Docker Desktop required, Phase 1+)
npx supabase test db             # database tests (Phase 1+)
```

Legacy app: `cd apps/legacy && fvm flutter run` (uses its own pin, 3.35.6).
