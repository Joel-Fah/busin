# 0001: Supabase as the backend

Status: accepted, 2026-10-30. Decided by the owner after the comparison below.

## Context
The original app used Firebase (Auth, Firestore) plus Supabase Storage. Server-side authorization, private files, geo analytics and scheduled jobs are needed. The owner wants to stay on free tiers while developing.

## Comparison

| Need | Firebase free (Spark) | Supabase free |
|---|---|---|
| File storage | None since February 2026 (Blaze only) | 1 GB, access policies tied to auth |
| Server logic | Cloud Functions need Blaze | Edge Functions (500k calls per month) and database functions |
| Per-school isolation | Rules plus custom claims (claims need Functions) | Row Level Security plus a token hook |
| Geo analytics | Client side or paid | PostGIS clustering and distance in SQL |
| Scheduled aggregates | Scheduled Functions (Blaze) | `pg_cron` |
| Live bus position | Realtime Database | Realtime |
| Local development and tests | Emulator Suite | Supabase CLI local stack and pgTAP |
| Push notifications | FCM | None; keep FCM on a minimal Firebase project |
| Offline cache | Built into Firestore | None; the ops app uses a local SQLite queue |

## Decision
Use Supabase for auth, database, storage, realtime, scheduled jobs and server functions. Use Firebase only for FCM push notifications (and optionally Crashlytics), on a minimal project.

## Consequences
- Every Firestore call in the legacy app is rewritten. Acceptable because existing data is pilot-only.
- Free projects pause after 7 days of inactivity, are limited to two active projects, and have no automatic backups. Mitigation: scheduled `pg_dump`, and a move to Pro once several schools are live.
- Database size is limited to 500 MB, so scans follow a retention policy.
- Free-tier figures come from third-party summaries and must be re-checked on supabase.com/pricing before relying on them.
