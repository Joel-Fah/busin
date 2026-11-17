# 0029: Mobile money payments through pawaPay

Status: proposed, 2026-11-17 (the owner's decisions of the same day). Built on the `phase-6/payments` branch and not
deployed until it has been tested end to end against the pawaPay sandbox and the owner approves.

## Context
A student pays the school outside BusIn and uploads a photo of the receipt, which an administrator approves (ADR 0022).
The owner wants students to be able to pay in the app with MTN Mobile Money or Orange Money, through pawaPay (API v2),
as an added option: the receipt upload stays. Mobile money in Cameroon fails often for ordinary reasons (weak network,
the PIN prompt ignored, an empty wallet), so the flow has to survive interruptions without charging twice or losing a
payment.

## Decision
1. **What can be paid.** A student's pending request (in full, or part 1 when paying in installments), a later
   installment part of an approved subscription, and BusIn's invoice to a school. A request paid by mobile money is
   created first, as today but without a receipt (`payment_method = 'mobile_money'`); the payment then approves it. If
   the payment fails, the request stays pending: the student retries, or sends a receipt instead. An administrator
   cannot approve such a request without a receipt, and cannot decide on it while its payment is in progress.
2. **The server starts every payment.** The `payments` Edge Function, called with the student's session, asks the
   database to open the payment (`start_payment`: checks the item, the amount, one payment in progress per item, and a
   limit per hour), which writes the row with its id first; that id is pawaPay's `depositId` and its idempotency key.
   Only then is pawaPay called. The phone never talks to pawaPay and never holds a key.
3. **The result is applied once, whichever way it arrives:** pawaPay's signed callback, a reconciler every two minutes
   for payments still open, and a status check after any timeout. `settle_payment` locks the row and is a no-op for a
   payment already final. A payment pawaPay has never heard of after 15 minutes is failed. An amount or currency that
   does not match, or a status it does not know, is set aside as `needs_attention` for the platform.
4. **Completed means approved.** The request is approved (part 1 paid with it), or the part is marked paid with a
   receipt line, and the student is told. When the item can no longer take the money (already paid, rejected, ended),
   the payment is refunded in full automatically.
5. **The money.** The student pays the school's price plus a service fee: a percentage with a floor and a ceiling,
   set by the platform, shown before paying and stored on each payment. BusIn holds the money in its pawaPay wallet. The
   school's share is written to its ledger (`school_ledger`, one signed row per movement, never edited), available
   after a hold (7 days). BusIn's charge per paying student (each approved subscription, whatever the payment method,
   from the date the school accepted the payment terms) is a ledger debit. Each week the available balance is paid out
   to the school's confirmed payout number. A negative balance (charges for a school paid only by receipts, or a refund
   after a payout) is what the school owes: it is taken from later payments, or invoiced monthly and paid from the
   portal.
6. **Refunds.** System errors are refunded in full, fee included. Otherwise the school decides on a student's request
   (full or partial, of the school's price; the fee stays with BusIn). A refund is a ledger debit.
7. **Receipts.** Every completed payment and refund gets a number (`BI-2026-000123`, refunds `BR-`, invoices `BF-`).
   The payer's number is stored masked; pawaPay keeps the full one under the payment's id.
8. **Who sees what.** A student reads their own payments and refunds; a school administrator their school's payments,
   refunds, ledger, payouts and invoices. Writing is done by `security definer` functions only. The platform reads
   totals through `platform_*` functions; settings and infrastructure costs are private.
9. **Switched on per school** by the platform, with the date its charges start.
10. **The key** lives only in Edge Function secrets (`PAWAPAY_API_TOKEN`, `PAWAPAY_BASE_URL`).

## Consequences
- The receipt flow is unchanged; mobile money is one more way to reach the same approved subscription.
- Accounting rows (payments, refunds, ledger) stay after an account is deleted, under the empty profile (ADR 0028).
- BusIn becomes a collector for schools: pawaPay must confirm this use of the account, and the rules on holding funds
  for others (CEMAC) and the tax on the fee are to be checked before going live.
