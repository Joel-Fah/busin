# 0005: RLS reads role and school live from profiles

Status: accepted, 2026-10-30.

## Context
ARCHITECTURE.md first described Row Level Security reading `school_id` and `role` from JWT claims. A claim stays valid until the token refreshes (up to one hour), so a suspended or demoted user would keep access for that long.

## Decision
RLS policies call small `security definer` helpers (`private.my_school_id()`, `private.my_role()`, `private.is_admin()`, `private.is_staff()`) that read the caller's row in `public.profiles` and return nothing unless the account is `verified`. A suspension or role change therefore takes effect on the next request.

The access token hook still copies `school_id`, `role` and `status` into `app_metadata`, but only so clients can choose screens without an extra request. Nothing authorizes on those claims.

## Consequences
- One indexed primary-key lookup per statement (cached by wrapping the helper in `select`). Acceptable at campus scale.
- Suspended users keep read access to their own profile and subscriptions, and nothing else.
- If scale ever makes the lookup a bottleneck, switch to claims plus a short token lifetime and record a new decision.
