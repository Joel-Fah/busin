---
name: busin-security
description: Security rules for BusIn based on OWASP (MASVS/MASTG for mobile, ASVS and Top 10 for web, API Security Top 10 for Edge Functions and RPCs). Load before touching authentication, authorization, storage, QR codes, secrets, file upload, logging or any query.
---

# BusIn security

Standards: OWASP MASVS and MASTG (mobile apps), OWASP ASVS and Top 10 (admin portal), OWASP API Security Top 10 (Edge Functions and RPC). Review every change against the checklist at the end before opening a PR.

## Core principle

The client is untrusted. Every decision about who may read or change data is made in Postgres (RLS, security definer functions) or an Edge Function. The audit found that the original app trusted the phone for roles; never repeat that.

## Rules

### Authorization (A01 Broken Access Control, API1 and API5)
- RLS is enabled and forced on every table in `public`, including new ones. A table without policies is closed by default; keep it that way.
- `school_id` and `role` are read by server-side helpers over `profiles` (ADR 0005), never from a client-supplied value. Users cannot update their own `role`, `status` or `school_id`: those columns are not in their update grant.
- Sign-up creates only students. Role changes happen in admin-only functions that write the audit log.
- Check object ownership on every read and write: a student reads only their rows, staff only their school.
- `security definer` functions set `search_path = ''`, validate their inputs, and check the caller's role first.
- The service role key never reaches any client, build config or log.

### Authentication (A07, MASVS-AUTH)
- Google sign-in only. Mobile uses the native flow and `signInWithIdToken`. The allowed email domain is verified on the server, not in the app.
- Sessions stay in the SDK's secure storage. Sign-out clears local caches and cancels subscriptions.
- Suspended accounts are rejected by scan verification and by the checks behind RLS.

### Rotating QR (audit finding C4)
- The QR payload is a time-windowed HMAC, not a user id. Window about 30 seconds. Compare in constant time and accept at most one adjacent window for clock skew.
- Per-student secrets stay server-side. The ops app caches only what the day's trip needs.
- Scans are idempotent per trip and student.

### Storage and files (A04, MASVS-STORAGE)
- Private buckets only. Paths contain `school_id` and the owner id, never an email.
- Storage policies mirror RLS. Reads use short-lived signed URLs.
- Validate file type and size on upload (image types, size cap).

### Secrets and configuration (A02, MASVS-CODE)
- No secret ships in a client. Public values only (Supabase URL, publishable key), passed with `--dart-define-from-file` or public env vars. `.env` is never an app asset.
- Real secrets live in Supabase function secrets or the portal's server environment. `.gitignore` blocks `.env`, `config/*.json`, keystores and `key.properties`; do not weaken it.
- If a secret is ever committed, treat it as leaked: rotate it first, then clean up.

### Input and injection (A03, API8)
- Use parameterized queries and the SDK query builder. Never concatenate user input into dynamic SQL; if unavoidable, use `format` with `%I` and `%L`.
- Validate and bound every input in functions: lengths, enums, ranges, coordinates.
- Encode output in the portal. Never inject user content as raw HTML.

### Network and platform (MASVS-NETWORK, MASVS-PLATFORM)
- HTTPS only. No cleartext exceptions in release builds.
- Disable Android backup of app data. Keep screenshot blocking on the QR screen.
- Request the minimum permissions. Location only in the ops app, only when scanning or driving, with an explanation first.

### Privacy and logging
- Collect the minimum. Never log tokens, emails, QR payloads or coordinates in release builds (guard Dart logs with `kDebugMode`; server logs carry no personal data).
- Raw scan locations are deleted after the retention period; analytics use aggregates.
- Anything sent to an AI model is aggregated and anonymized: no names, emails or individual traces.
- Account deletion must exist before store release.

### Abuse and availability (API4, API6)
- Rate limit public or expensive Edge Functions. Paginate every list and cap `limit`.
- Realtime channels are filtered by school and bus; RLS applies to Realtime too.

### Supply chain (A06, A08)
- Pin versions. Review a new dependency (maintenance, popularity, permissions) before adding it. Commit lockfiles for deployable apps.
- Update dependencies in dedicated PRs.

## PR checklist

- [ ] New tables have RLS enabled and policies tested in pgTAP (allowed and denied cases)
- [ ] No role, school or status accepted from client input
- [ ] No secret, key or personal data in code, config examples, logs or fixtures
- [ ] Queries select named columns and are paginated
- [ ] Inputs validated server-side
- [ ] Files private, paths contain no email
- [ ] New permission or dependency justified in the PR text
