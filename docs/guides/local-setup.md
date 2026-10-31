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

## Launch the admin portal

With Docker Desktop running, from the repo root:

```bash
npm install            # first time only
npm run backend:start  # database and sign-in; the first start downloads images and is slow
npm run web:setup      # first time only: writes apps/admin_web/.env.local from the running backend
npm run web            # open http://127.0.0.1:3000
```

Other handy commands: `npm run backend:stop`, `npm run backend:reset` (rebuild the database from the migrations and seed), `npm run backend:test` (database tests). `backend:start` leaves out services the portal does not need (Studio, Storage, Realtime, Edge Functions) to keep the download small; add them back when a feature needs them, for example Storage to show payment proofs.

Sign-in uses Google, which needs an OAuth client on your personal Google Cloud project (see the last section of this page).

## Per tier

| Tier | Run |
|---|---|
| Backend | `npx supabase start` (Phase 1) |
| Admin portal | `cp apps/admin_web/.env.example apps/admin_web/.env.local`, fill it from `npx supabase status -o env`, then `npm run dev -w apps/admin_web` (http://127.0.0.1:3000) |
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

## Admin portal tests

```bash
npm run test -w apps/admin_web       # unit tests
npm run test:e2e -w apps/admin_web   # browser tests; needs the local backend running
```

The browser tests open real sessions for temporary users that they create in the local database and delete afterwards. They need Docker (they run SQL in the `supabase_db_busin` container) and one browser download: `npx playwright install chromium --only-shell`.

## Google sign-in for the portal (when you are ready)

Real Google sign-in needs an OAuth client on your personal Google Cloud project. Create a Web client with the redirect URI shown by `npx supabase status` (the local Auth callback), set its id and secret as environment variables, then enable `[auth.external.google]` in `supabase/config.toml`. I will walk through the steps with you when you want to try it; the tests do not need it.
