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

```bash
npx supabase start                      # from the repo root; needs Docker Desktop
cp apps/admin_web/.env.example apps/admin_web/.env.local
# fill in the URL and publishable key printed by: npx supabase status -o env
npm run dev -w apps/admin_web           # http://127.0.0.1:3000
```

Google sign-in needs an OAuth client (see [local setup](../../docs/guides/local-setup.md)). Without one, the tests below sign in with real Supabase sessions created for test users.

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
