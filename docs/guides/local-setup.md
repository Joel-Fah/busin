# Local setup

## Tools

| Tool | Version | Needed from | Notes |
|---|---|---|---|
| Git | any recent | Now | |
| GitHub CLI (`gh`) | latest | Now | `winget install GitHub.cli`, then `gh auth login` |
| FVM | 4.x | Now | Pins Flutter through `.fvmrc` |
| Flutter | 3.47.9 | Phase 2 | `fvm install` at the repo root |
| Node | 24 LTS | Now | `.nvmrc` |
| Java | 21 LTS | Phase 3 | Set `JAVA_HOME` to the JDK 21 folder |
| Docker Desktop | latest | Phase 1 | Local Supabase stack |
| Android Studio and SDK | latest | Phase 3 | Device testing |

Supabase CLI is installed per project (`npm install`), so no global install is needed.

## First run

```bash
npm install
fvm install
fvm dart pub get
npm run check
```

## Per tier

| Tier | Run |
|---|---|
| Backend | `npx supabase start` (Phase 1) |
| Admin portal | `npm run dev -w apps/admin_web` (Phase 2) |
| Student and ops apps | `fvm flutter run` inside the app folder (Phase 3 and 4) |
| Legacy app | `cd apps/legacy && fvm flutter run` |

## Configuration

Copy `config/dev.example.json` to `config/dev.json` and fill in the public Supabase URL and publishable key. Build with `--dart-define-from-file=config/dev.json`. Never commit real config files.

## Local backend (Phase 1)

```bash
npx supabase start        # first run pulls Docker images
npx supabase db reset     # applies migrations and supabase/seed.sql
npx supabase test db      # runs the pgTAP tests in supabase/tests
npx supabase stop
```

Promote a local account to admin after signing in once with Google (replace the email). Local development only; never run this against a hosted project, where roles change through audited functions.

```sql
update public.profiles set role = 'admin' where email = 'you@ictuniversity.edu.cm';
```

Google sign-in locally needs an OAuth client. Until it exists, create test users with SQL as the tests do.
