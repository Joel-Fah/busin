# BusIn

Campus bus management for schools: subscriptions, boarding scans, bus tracking and decision-support analytics.

BusIn is being rebuilt as separate apps on a shared Supabase backend. The original single app is kept in [apps/legacy](apps/legacy/) for reference.

| Part | Path | Audience |
|---|---|---|
| Student app (Flutter) | [apps/student](apps/student/) | Students |
| Ops app (Flutter) | [apps/ops](apps/ops/) | Staff and drivers |
| Admin portal (Next.js) | [apps/admin_web](apps/admin_web/) | School admins |
| Shared Dart packages | [packages/](packages/) | The Flutter apps |
| Backend | [supabase/](supabase/) | All apps |

## Start here

- [ARCHITECTURE.md](ARCHITECTURE.md): how the pieces fit together
- [STATUS.md](STATUS.md): current phase, blockers, last handoff
- [CLAUDE.md](CLAUDE.md): working rules for contributors and Claude Code
- [docs/phases/](docs/phases/): what each phase delivers
- [docs/guides/local-setup.md](docs/guides/local-setup.md): tools and how to run each tier
- [build_log.md](build_log.md): history of PRs

## License

MIT, see [LICENSE](LICENSE).
