---
name: busin-admin-web
description: Conventions for the BusIn admin portal (Next.js 16, TypeScript, Supabase). Load before writing or testing anything under apps/admin_web.
---

# BusIn admin portal

Separate app in `apps/admin_web`, for school admins only. Brand and tone follow `busin-design-system`; security follows `busin-security`.

## Stack
- Next.js 16 (App Router), React 19, TypeScript in strict mode, Node 24 LTS. Versions are pinned and recorded in ARCHITECTURE.md. Upgrades are their own PR.
- Supabase JavaScript client with the SSR helpers. Server components and route handlers use the server client; the browser client is used only for what must be live.
- Styling with CSS variables for the BusIn tokens (light and dark), so the portal matches the apps.

## Structure
- `app/` routes grouped by area: people, subscriptions, stops, semesters, buses and trips, scans, analytics, settings.
- `lib/` for Supabase clients, typed queries and utilities. `components/` for shared UI.
- Business rules stay in the database and Edge Functions. The portal calls RPCs; it does not re-implement rules.

## Auth and access
- Google sign-in. Middleware redirects unauthenticated users. Only users with the `admin` role (from the JWT) reach admin routes; check again in each server action and route handler.
- Never send the service role key to the browser. Privileged work happens in server code with the key kept in server environment variables only.
- All tenant data is scoped by RLS; do not filter by school in the client as a substitute for policy.

## Data
- Select named columns. Server-side pagination, sorting and filtering for every table. Exports stream from the server.
- Maps and heatmaps load aggregate tables, not raw scans. Use MapLibre with open tiles unless the owner approves a paid provider.

## UI
- Dense tables, filters and bulk actions are expected. Every list has loading, empty and error states. Destructive actions use an in-page confirmation.
- Accessible by default: labels, focus order, contrast in both themes, keyboard navigation. No emojis.

## Testing (Claude runs these)
- Vitest for utilities, query builders and server actions with a mocked client.
- Playwright for end-to-end flows against the local Supabase stack: sign-in, approve a subscription, create a stop, view scans. Seed data comes from `supabase/seed.sql`.
- Before a PR: typecheck, lint, unit tests, and the Playwright flows touched by the change. Keep browser runs local; CI runs only what is cheap (see CLAUDE.md on Actions usage).

## Config
- Public env vars only for URL and publishable key. Secrets are server-only variables, listed in `.env.example` without values.
