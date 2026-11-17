# Mobile money payments: setup

How to connect BusIn to pawaPay, first in the sandbox. Design: [ADR 0029](../decisions/0029-mobile-money-payments.md).
Nothing here is live until the owner approves it.

## Before you start (owner)

- A pawaPay account. For Cameroon, both operators are on the Enterprise plan and pawaPay notes extra launch
  requirements for each: ask pawaPay what they are.
- Ask pawaPay to enable the intermediary merchant schedule (BusIn collects for schools, which are sub-merchants), and to
  confirm in writing whether the student's service fee is allowed (its sub-merchant terms forbid surcharges). Until
  they confirm, set `costs_paid_by` to `school` before going live.
- Ask for the refund rates in Cameroon (not on the public fee page), and whether VAT applies to pawaPay's 1%.

## The key

The API token lives only in Edge Function secrets. Never put it in an app, the portal, `config/*.json` or git.

Locally, in `supabase/functions/.env` (git-ignored; copy `supabase/functions/.env.example`):

```bash
PAWAPAY_API_TOKEN=<sandbox token from the pawaPay dashboard>
PAWAPAY_BASE_URL=https://api.sandbox.pawapay.io
PAWAPAY_CALLBACK_URL=<the callback address given to pawaPay>
PAWAPAY_SIGNED_CALLBACKS=on
PAYMENTS_RECONCILE_SECRET=<a long random value>
```

On a hosted project (owner approval needed), from a file created with `umask 077` and deleted afterwards:

```bash
npx supabase secrets set --env-file <file> --project-ref <ref>
```

## pawaPay's dashboard

- Callback URL for deposits (and later refunds and payouts):
  `https://<project-ref>.supabase.co/functions/v1/pawapay-callback`. Put the same address in `PAWAPAY_CALLBACK_URL`.
- Turn on signed callbacks. With them off, set `PAWAPAY_SIGNED_CALLBACKS=off`: each callback is then checked with
  pawaPay instead of trusted.

## The reconciler

Every two minutes, `pg_cron` calls `payments-reconcile` when a payment has been open for more than two minutes. On a
hosted project it needs two Vault values (owner approval needed), as for push:

```sql
select vault.create_secret('https://<project-ref>.supabase.co/functions/v1/payments-reconcile', 'payments_reconcile_url');
select vault.create_secret('<the PAYMENTS_RECONCILE_SECRET value>', 'payments_reconcile_secret');
```

## Switching a school on

Done by the platform (the console gets a switch in slice 6). Until then, in SQL:

```sql
insert into private.school_payment_terms (school_id, enabled) values ('<school id>', true)
on conflict (school_id) do update set enabled = true;
```

Rates and the fee are in `private.payment_settings` and `private.provider_rates`; they start from pawaPay's published
Cameroon rates (collections MTN 0.75%, Orange 0.77%; payouts MTN 0.30%, Orange 0%; plus pawaPay's 1%).

## Testing in the sandbox

pawaPay's sandbox answers by phone number. Check the exact list on pawaPay's sandbox test numbers page before
testing; for Cameroon:

| Number | Result |
|---|---|
| 237653456789 (MTN), 237693456789 (Orange) | Completed |
| Numbers ending in 019, 029, 039, 049, 069 | Failed, each with a different reason |
| Numbers ending in 129 | Stays processing (exercises the reconciler) |

Check after each: the payment's status, the request approved (or not), one ledger row, one notification. Send the same
callback twice and check nothing changes the second time.
