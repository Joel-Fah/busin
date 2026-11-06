# 0010: Push notifications through an outbox and a sender function

Status: proposed, 2026-11-05. The owner reviews it with the Phase 3 push slice. The database part and the sender are built and tested; nothing is deployed and no Firebase project is connected yet.

## Context
[ADR 0001](0001-backend-supabase.md) keeps Firebase only for FCM push. Students should hear when their subscription is decided, without opening the app. Later phases add trip events (a bus is about to arrive, a trip was cancelled).

Requirements that shaped the design:
- A notification must exist exactly when the event does (no lost or phantom ones).
- Nothing personal travels through a third party: no names, no review reasons.
- A dead phone or a Firebase hiccup must not lose or repeat a notification.
- A phone can change hands; a token must never keep delivering the previous owner's messages.
- Free: FCM has no per-message charge, and Supabase Edge Functions are within the current plan.

## Decision
1. **Device tokens** live in `public.device_tokens`, one row per phone installation (unique token). A user never writes the table: `register_device_token` and `unregister_device_token` do, as the caller. Registering a token that another user holds moves it to the caller (a token follows the installation). Each user keeps their ten most recent phones. Only verified accounts can register. The phone's language (`en` or `fr`) is stored with the token.
2. **Outbox**: `private.notification_outbox` (not reachable through the API). A trigger on `subscriptions` writes one row when a pending request becomes approved or rejected, in the same transaction as the decision. A row holds a kind and a reference id only.
3. **Sender**: the `send-push` Edge Function claims pending rows through `claim_notifications` (rows are locked and each claim counts as an attempt, so two senders never send the same one), sends one FCM message per phone and reports each outcome through `complete_notification`. All of this is callable by the service role only. After five attempts a row is left alone and its last error stays for inspection.
4. **Wording** lives in the sender, in English and French, in the language the phone registered with. The message carries generic text and ids only (the kind and the subscription id). The app, signed in as the student, loads the details itself.
5. **Dead tokens**: when FCM says a token is unregistered it is dropped. Network errors and 5xx answers are retried; a refusal retrying cannot fix (for example bad credentials) is recorded and not hammered.
6. **The pure logic is tested without Deno**: `supabase/functions/_shared/push.ts` has no Deno or network dependency and `npm run test:functions` runs its tests with Node. The Deno file `send-push/index.ts` only connects it to the database and to Firebase. The database parts have pgTAP tests (`010_push_notifications.test.sql`).

## What triggers the sender (open: owner decision)
Something has to call `send-push`. It checks a shared secret (`PUSH_SECRET`) in the `x-push-secret` header and the platform's own JWT check is off for it. Options:

| Option | How | Latency | Notes |
|---|---|---|---|
| A. Scheduler | `pg_cron` calls the function every minute through `pg_net` | up to a minute | No dependency on dashboard settings; needs the `pg_cron` and `pg_net` extensions enabled and the secret kept in Vault |
| B. Database webhook | A Supabase database webhook calls it when a row is inserted into the outbox | seconds | The outbox is in the `private` schema, which webhooks may not watch; would need a small public insert-only wrapper |
| C. Both | A for safety, B for speed | seconds | More to configure |

Recommendation: A first (simple, robust, one minute is fine for "your subscription was approved"). It is a hosted-project change (extensions and a secret), so it waits for the owner. Locally nothing runs it automatically; the function can be called by hand with the secret.

## Not done on purpose
- No email or SMS, no marketing or broadcast messages, no per-topic subscriptions.
- No notification text from user input. A reviewer's reason is never put in a push.
- The Edge Function is not deployed, and the Firebase service account and `PUSH_SECRET` do not exist yet.

## Consequences
- Adding a notification kind means: one new value in the outbox check, one trigger or function that writes it, text for it in the sender, and a label for it in the app.
- The outbox grows by one row per decision. A retention job (delete sent rows older than 30 days) is a small follow-up once `pg_cron` is in use.
- The client side (the Firebase SDK, asking permission, registering the token on sign-in and removing it on sign-out, opening the right screen from a tap) follows once the owner has created the Firebase project. Until then no app depends on any of this.
