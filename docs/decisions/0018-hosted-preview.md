# 0018: Hosted preview on Supabase and Vercel

Date: 2026-11-12. Status: accepted (owner, 2026-11-12). Builds on [ADR 0008](0008-map-provider.md) and
[ADR 0004](0004-accounts-ownership.md).

## Context

Until now everything ran on the owner's machine. The owner wants to show the app to a few people, so the admin portal
and a backend have to be reachable on the internet. It is a preview: demo data, no real students, free plans.

## Decision

1. **Backend: one hosted Supabase project, `busin-preview`, region Frankfurt (eu-central-1),** free plan, in the
   owner's own Supabase organization. Supabase has no African region; Frankfurt is the nearest practical one.
2. **Admin portal: Vercel (Hobby plan), deployed from `main`.** The Vercel project is linked to the GitHub repository
   with `apps/admin_web` as its root directory. `main` is the production branch; only `main` and pull requests into
   `dev` or `main` build, to keep build minutes low. Vercel is a new vendor, approved by the owner.
3. **The schema is pushed from the repository** (`supabase db push`), never edited in the dashboard. The ICT University
   seed (`supabase/seed.sql`) and the demo data (`supabase/seed-demo.sql`) were loaded once.
4. **Secrets stay out of git.** The database password and the demo password live in the git-ignored
   `supabase/.env.hosted`. The Mapbox Directions token is a secret of the `route-directions` function. The portal gets
   only public values (project URL, publishable key). The service role key is never used by the portal.
5. **Sign-in is Google only.** The demo accounts carry a random password nobody uses (the `/dev/login` page returns
   not found in a production build). A person becomes an administrator by signing in with Google after an invite.
6. **Push notifications are off** on the hosted project until the Firebase credential is added (see
   [push-setup](../guides/push-setup.md)).

## Consequences

- A free Supabase project is paused after about a week without activity; it is resumed from the dashboard.
- The demo data is fake. Removing it (before real use) is `delete` on the `demo.%` accounts and `de%` rows, as
  `seed-demo.sql` does when it reruns.
- The Supabase auth settings of the hosted project differ from the local `config.toml` (site URL, redirect URLs, Google).
  They are pushed from a hosted-only copy of the config, never from the local file as it is.
- Moving to a paid plan or a custom domain is a new decision.
