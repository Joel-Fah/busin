# Admin web portal

Next.js 16 and TypeScript portal for school administrators. It talks to the shared Supabase backend as the signed-in user, so Row Level Security decides what each admin can see. Rules: [busin-admin-web skill](../../.claude/skills/busin-admin-web/SKILL.md).

## What exists

| Area | State |
|---|---|
| Sign-in with Google, admin-only guard, no-access page | Done |
| Shell with navigation, language switch (EN and FR), sign-out | Done |
| Overview with live counts (reviews waiting, students, trips running, boardings today) | Done |
| Subscriptions review, people, stops with map, semesters, buses and trips, scans | Next PRs |

## Run it

From the repo root, with Docker Desktop running:

```bash
npm install          # first time only
npm run backend:start   # local database and sign-in (first start downloads images and is slow)
npm run web:setup       # first time only: writes apps/admin_web/.env.local from the running backend
npm run web             # http://127.0.0.1:3000
```

Stop the backend with `npm run backend:stop`.

**Signing in.** The real way is Google: follow [the Google sign-in guide](../../docs/guides/google-sign-in.md) to create the OAuth client and put its keys in `supabase/.env`. For quick local work there is also a development-only page: run `npm run dev:user` to create a local admin, then sign in at http://127.0.0.1:3000/dev/login. That page only exists on a development server whose backend is on your machine; in a production build it returns not found. The browser tests below sign in with real Supabase sessions created for temporary test users.

## Checks

```bash
npm run typecheck -w apps/admin_web
npm run lint -w apps/admin_web
npm run test -w apps/admin_web          # unit tests (Vitest)
npm run test:e2e -w apps/admin_web      # browser tests (Playwright); needs the local stack
```

## How it is built

- **Proxy** (`proxy.ts`): refreshes the session cookie and sends signed-out visitors to the login page. This is an optimistic check only.
- **Real authorization** (`lib/auth.ts`, `requireAdmin`): asks the auth server to validate the session, loads the profile and allows only a verified admin. Every page, action and route handler calls it again.
- **Rendering**: Cache Components is on (Next 16 default). Anything that reads the session or the database runs at request time inside `<Suspense>`.
- **Data**: counts and selected columns only, never `select('*')`. Types come from the database (`npm run gen:types`, which needs the local stack).
- **Text**: every string is in `lib/i18n/messages.ts` in English and French; the French catalogue must have the same keys, which the type checker and a test enforce.
- **Theme**: BusIn tokens as CSS variables in `app/globals.css`, light and dark. The Bevellier font and logo come from the legacy app.
- **Headers**: baseline security headers in `next.config.ts`. A nonce-based Content-Security-Policy is a follow-up.
