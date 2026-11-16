# 0028: Account deletion

Status: accepted, 2026-11-16 (the owner's decisions of the same day). The app stores require it before listing: in the
app (Google Play and the App Store) and on a web page (Google Play).

## Context
Nothing deleted an account: the apps had no way to ask, and a profile could not be removed because subscriptions,
boardings, trips and the audit log point to it. Deletions were done by hand in SQL.

## Decision
1. **Who asks.** The person, from every app (student app, ops app, student web app, the admin portal's profile). A public
   page, `/delete-account`, explains how, and lets someone who lost access ask by email (a `deletion` lead in the
   platform console). The platform can schedule a deletion for such a person from Lookup, after confirming with them by
   email (ADR 0027).
2. **When.** Seven days after asking. Until then the person can cancel, from the same place. Asking is refused for the
   last administrator of a school (hand it over first) and for someone on a running trip (finish it first).
3. **What goes, what stays.** A nightly job erases what identifies the person: name, email, phone, picture, matricule,
   home area, devices, notification preferences, requests, open invites and payment proof files. The school keeps its
   records without a name: subscriptions and payments (amounts, dates, statuses), boardings, trips they drove, its audit
   log. The profile stays as an empty "Deleted account" row those records point to.
4. **The sign-in account** is soft-deleted (Supabase keeps a hashed id only), so the same Google account can sign up
   again as a new account.
5. **How it runs.** `pg_cron` calls the `delete-accounts` Edge Function at 02:40 UTC when something is due, with a secret
   (Vault `deletions_url`, `deletions_secret`, as push does in ADR 0010). The function deletes the proof files through
   Storage (SQL cannot remove stored files), soft-deletes the sign-in account, then calls `erase_account`. Each step is
   safe to repeat; a failure is retried the next night. Locally, `npm run dev:erase -- <email>` runs the same steps.
6. Every request, cancellation, scheduling and erasure is in the school's audit log or the platform audit.

## Consequences
- A school sees "Deleted account" in its history where the person was; their totals and statistics do not change.
- Boarding locations stay with the anonymous boardings (they serve the school's stop statistics).
- The hosted project needs the function deployed with `DELETIONS_SECRET`, and the two Vault values, before deletions
  run (owner, `docs/guides/account-deletion.md`). Until then requests wait, and nothing is lost.
