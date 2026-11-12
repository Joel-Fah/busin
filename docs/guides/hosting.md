# Hosting the preview

The hosted preview is a Supabase project plus the admin portal on Vercel ([ADR 0018](../decisions/0018-hosted-preview.md)).

## Supabase (project `busin-preview`, Frankfurt)

Everything here uses the Supabase CLI logged in as the owner (`npx supabase login`). The database password and other
secrets are in `supabase/.env.hosted` (git-ignored); load it with `set -a; . supabase/.env.hosted; set +a`.

- **Schema:** `npx supabase link --project-ref <ref>`, then `npx supabase db push --linked` (use `--dry-run` first).
- **Seed once:** `supabase/seed.sql` (the school, its stops and route), then `supabase/seed-demo.sql` with the demo
  password filled in (it is a psql variable; wrap both in `begin;` and `commit;` and run with
  `npx supabase db query --linked -f <file>`).
- **Function:** put `MAPBOX_DIRECTIONS_TOKEN` in the function secrets (`npx supabase secrets set`), then
  `npx supabase functions deploy route-directions --use-api`. Draw the road once as an administrator (Stops, Bus route,
  Draw along roads).
- **Auth settings:** the site URL, the redirect URLs, the access token hook and Google. Push them from a hosted-only
  copy of `config.toml` (`npx supabase config push`), not from the local file, whose values are for 127.0.0.1.
- **Google:** add `https://<ref>.supabase.co/auth/v1/callback` to the OAuth client's authorized redirect URIs, and give
  the client id and secret to the hosted project (Auth, Providers, Google, or `config push`).

## Vercel

- Project root `apps/admin_web`, production branch `main`, Node 24.
- Environment variables (production and preview): `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`,
  `SITE_URL` (the portal's own address), and optionally `MAPBOX_API_KEY` (a public `pk.` token restricted to the site).
- Never add the service role key or any `sk.` token.
