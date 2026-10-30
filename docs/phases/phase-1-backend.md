# Phase 1: backend

Goal: a secure multi-tenant Supabase backend that closes every Critical finding from the audit at the database level.

## Scope
- `npx supabase init`, local stack, migrations.
- Schema: schools, profiles, semesters, stops (PostGIS point), buses, trips, subscriptions, scans (unique per trip and student), live_positions, audit_log.
- Row Level Security on every table. Roles and school come from JWT claims.
- Sign-up check against `schools.allowed_domains`; sign-up always creates a student.
- Custom access token hook adding `school_id` and `role`.
- RPC functions for approve, reject, promote and suspend, each writing the audit log.
- Edge Function for the rotating QR secret and verification.
- Private storage buckets with matching policies.
- Seed data for local development.
- pgTAP tests for every policy and function.

## Exit criteria
- `npx supabase test db` is green.
- A user cannot read another school's rows, change their own role, or read another user's proof file (tested).
- Audit findings C1, C2, C3, C4, H5 are covered by tests.

## Depends on
Phase 0. Docker Desktop (owner). Google OAuth clients for sign-in testing (owner).
