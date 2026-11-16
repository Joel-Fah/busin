# 0027: Platform console

Status: accepted, 2026-11-16 (the owner's request of 2026-11-15, and the plan they approved).

## Context
Everything above one school is done today by hand: reading leads in Studio, SQL for account problems, checking each
school's data one by one. With more schools (phase 6), the owner needs one place that shows every school at a glance,
spots a school that struggles (slow answers to students, an unfinished profile, buses running without scans) so it can
be helped or reminded, and onboards a new school without code.

## Decision
1. **Where:** a console inside the admin portal at `/platform` (its own route group, layout and tabs), not a separate app.
   It reuses the sign-in, the design system and the deploy. Next.js splits code by route, so school admins never load
   the console's code.
2. **Who:** a platform admin is an account listed in `private.platform_admins`, not a fourth role: a profile's role is a
   role inside one school, and a platform admin may also be a member of a school (or of none). Rows are added by the
   owner with SQL only; no app or console screen adds them. The list is read live on the server
   (`private.is_platform_admin()`, as ADR 0005 does for roles), so removing a row applies at once.
3. **What it reads:** aggregates. Every `platform_*` function checks the list first (42501 otherwise) and returns counts
   per school, not people. No existing Row Level Security policy changes, and a platform admin reads no table directly.
   Reading one account comes later, as a lookup by exact email that is audited and rate limited. There is no browsing
   of a school's people and no acting as another user.
4. **The way in:** the console answers "not found" to everyone who is not listed, so it does not show that it exists.
   The school portal's profile shows the way in only to a listed account; the console's account page shows the way back
   to the school portal only to an administrator of a school.
5. **Audit:** what platform admins do (lookups, schools created or switched off, leads handled, notices sent) goes to
   `public.platform_audit`, written only by platform functions and read by no school. It is separate from `audit_log`,
   whose school is required.
6. **School health:** fourteen signals per school, computed in the database from data that already exists (waiting
   times, answers, profile, setup, buses and trips, activity). Each gets a level (OK, Watch, Needs help, Critical) from
   thresholds kept in `private.health_rules`, so they can be tuned without code; a school takes the level of its worst
   signal, with a weighted score to order schools at the same level. Shares and rates need at least 3 trips or 5
   requests. Setup-type signals are capped at Watch during a new school's first 14 days. A switched-off school is not
   scored. A nightly job keeps one record per school per day (`school_health_daily`, about 13 months). No "trips left
   running" signal: a scheduled job already ends stale trips.
7. **Reaching out:** the school page shows the school's contacts and its administrators' (each view in the platform
   audit), and writes a ready message about the chosen signals in English or French. It opens in the owner's own email
   or WhatsApp (no email vendor; nothing is sent for them), or goes to the school's administrators as a notice at the top
   of their overview (`school_notices`: read by that school's administrators only, linking to a page of their portal,
   dismissed by them, expiring after 30 days). Every contact goes to `platform_outreach`, and may pause its signals for
   a few days (they stay visible, marked paused; a school whose serious signals are all paused leaves "Needs you") and
   set a follow-up date, listed in "Needs you" until done.
8. **Onboarding:** a platform admin creates a school (name, short name, country, city, time zone, student email
   domains; a name or a domain already in use is refused) and invites its first administrator, through the staff
   invites of ADR 0015 (an existing account of no other school becomes its administrator at once). That administrator
   sets up the rest in the school's portal. A school can be switched off and back on after a confirmation: switched off,
   it takes no new sign-ups, joins, invites or staff requests, leaves the landing page and is not scored; the people
   already in keep their access.
9. **Leads:** the landing page's requests (schools that want BusIn, people waiting for the apps) are listed in the
   console with a status (new, contacted, converted, dismissed) and a note; a school lead prefills the new school form,
   and once the school exists the lead names it. The visitors sent their email to be contacted, so it is shown.
10. **Version 1, in slices:** access and overview (this decision's first slice); school health with levels (OK, Watch,
   Needs help, Critical) and a nightly health record; reaching out (contacts, ready messages, an in-portal notice, an
   outreach log); school onboarding; leads; usage, costs and system health; account lookup.

## Consequences
- The owner adds their own row on the hosted project with SQL (owner approval, as for any hosted change).
- Local accounts for the development sign-in: `npm run dev:platform` (an account that opens only the console),
  `npm run dev:user -- <email> platform`, or `npm run dev:user -- <email> admin --platform` (a school admin who also
  opens it). An account that administers no school lands on the console after signing in, not on "no access".
- The Google account of a platform admin protects the whole platform's figures: it should have 2-step verification.
- Not in version 1: account deletion, adding platform admins from the console, announcements or feature flags per
  school, the Crashlytics API, revenue across schools. Acting as another user is never planned.
