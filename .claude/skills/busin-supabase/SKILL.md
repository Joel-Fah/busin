---
name: busin-supabase
description: How to work on the BusIn Supabase backend - migrations, RLS patterns, RPC versus Edge Function, PostGIS, pg_cron, storage policies and pgTAP tests. Load before changing anything under supabase/ or writing a query in any client.
---

# BusIn Supabase

Design context: [ARCHITECTURE.md](../../../ARCHITECTURE.md) and ADR 0001. Security rules: `busin-security`.

## Workflow
- Schema changes are migrations only: `npx supabase migration new <name>`, never edit the hosted database by hand. One concern per migration; migrations are append-only once merged.
- Develop against the local stack (`npx supabase start`, needs Docker). Reset with `npx supabase db reset`, which applies migrations then `seed.sql`.
- Never run migrations or push against a hosted project without owner approval.
- Generate types after schema changes and commit them if a client uses them.

## Schema conventions
- Every tenant-owned table has `school_id uuid not null references schools(id)`, indexed.
- Primary keys are `uuid default gen_random_uuid()`. Timestamps are `timestamptz default now()`, set by the server. Names are snake_case.
- Enums for roles and statuses (`student`, `staff`, `admin`; `pending`, `approved`, `rejected`, `expired`).
- Coordinates are PostGIS `geography(Point, 4326)`; add a GiST index.
- Constraints carry the rules: unique `(trip_id, student_id)` on scans, checks on status transitions where practical.

## RLS patterns
- `alter table ... enable row level security` and `force row level security` on every table.
- Read school and role from the JWT: `(auth.jwt() ->> 'school_id')::uuid` and `auth.jwt() ->> 'role'`. Wrap in `select` (`(select auth.jwt() ...)`) so Postgres caches it per statement.
- Students: own rows only. Staff: their school, read plus insert scans. Admin: their school, full read; writes through functions that audit.
- Separate policies per command (select, insert, update, delete). No `using (true)`.
- Never grant `update` on `role`, `status` or `school_id` to the `authenticated` role; use column privileges or functions.

## Functions
- Use a database function (RPC) for transactional business rules (approve, reject, promote, suspend, issue QR secret). Use an Edge Function when you need secrets, outside HTTP calls or non-SQL libraries.
- `security definer` functions set `search_path = ''`, qualify every object name, check the caller, validate inputs, and write `audit_log`.

## Storage
- Private buckets. Policies check path prefix against `school_id` and the owner id. Clients upload to their own path and read via signed URLs.

## Geo and jobs
- PostGIS for distance (`ST_DWithin`), clustering (`ST_ClusterDBSCAN`) and nearest stop. `pg_cron` for nightly aggregates and retention deletes.
- Aggregates go into `stats_*` tables the portal reads; avoid scanning raw `scans` from the UI.

## Least-data queries
- Name the columns. Paginate with `range`. Add an index for each filter and order used. Filter Realtime channels by `school_id` and bus id.

## Tests (pgTAP)
- Every table and function has tests in `supabase/tests/`, with allowed and denied cases for each role and for cross-school access. Run `npx supabase test db` before every PR that touches `supabase/`.
- Minimum cases: student cannot read other students, student cannot change own role, staff cannot read another school, scan duplicate is rejected, proof file not readable by others.
