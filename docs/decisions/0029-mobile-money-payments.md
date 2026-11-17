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
5. **The money.** pawaPay takes 1% of every transaction (payments, payouts, refunds) and, as it told the owner, nothing
   more for Cameroon; operator shares and VAT on pawaPay's fee are platform settings, at 0 for now (its public fee page
   listed operator shares, to confirm in the agreement). BusIn's margin, which has to cover its infrastructure and the
   service, is its charge per paying student (each approved subscription, whatever the payment method, from the date
   the school accepted the payment terms), fixed when the request is made and taken from the school's balance.
   **Each school chooses who pays these fees**, where it sets its price, with a breakdown per way of paying
   (`price_breakdown`): what the student pays, BusIn's charge, the transfer costs and what the school receives.
   - Students (the default): BusIn's charge is in the price for every way of paying, and paying by mobile money adds a
     fee worked out per operator so that, once the payment and the payout are paid for, the school receives exactly its
     price (plus 0.2% for rounding). On a 20,000 XAF pass with a 700 XAF charge: 20,700 by receipt, 21,160 by mobile money.
   - The school: students pay the price only; the charge and the transfer costs (a `transaction_fee` ledger row) come out
     of the school's share.

   BusIn holds the money in its pawaPay wallet. The school's share is written to its ledger (`school_ledger`, one signed
   row per movement, never edited), available after a hold (7 days). Each week the available balance is paid out to the
   school's confirmed payout number. A negative balance (a school paid only by receipts, or a refund after a payout) is
   what the school owes: it is taken from later payments, or invoiced monthly and paid from the portal with the cost of
   collecting it on top.
6. **Refunds.** System errors are refunded in full, fee included, at BusIn's cost. Otherwise the school decides on a
   student's request (full or partial, of the school's price; the fee is not returned, as it paid for the transfers)
   and bears what sending the refund costs (a `refund_fee` row in its ledger), or refunds on its own. One refund per
   payment (pawaPay refuses a second one for a deposit already refunded); a declined or failed one leaves the payment
   refundable again. Approving takes the amount from the school's balance at once; a refund that fails is put back,
   except BusIn's own, which goes to the platform. A refund of a request's whole price ends the subscription. The
   reconciler sends refunds and checks them; pawaPay's callbacks settle them like payments.
7. **Receipts.** Every completed payment and refund gets a number (`BI-2026-000123`, refunds `BR-`, invoices `BF-`).
   The payer's number is stored masked; pawaPay keeps the full one under the payment's id.
8. **Who sees what.** A student reads their own payments and refunds; a school administrator their school's payments,
   refunds, ledger, payouts and invoices. Writing is done by `security definer` functions only. The platform reads
   totals through `platform_*` functions; settings and infrastructure costs are private.
9. **Switched on per school** by the platform, with the date its charges start.
10. **The key** lives only in Edge Function secrets (`PAWAPAY_API_TOKEN`, `PAWAPAY_BASE_URL`).
11. **pawaPay's terms.** In pawaPay's merchant terms, BusIn is an intermediary merchant (Schedule 2) and each school a
    sub-merchant: BusIn needs a written agreement with each school, no less strict than pawaPay's general terms, that
    includes the sub-merchant terms (Appendix 1), which pawaPay can enforce against the school directly. Those terms
    forbid surcharging end users (Appendix 1, 3.5.1), and the mobile money fee could read as one. Until pawaPay confirms
    in writing that it may stand, the platform can withhold it (`student_fee_allowed`): schools that chose students then
    still pass BusIn's charge on (it applies to every way of paying) but bear the transfer costs.

## Consequences
- The receipt flow is unchanged; mobile money is one more way to reach the same approved subscription.
- Accounting rows (payments, refunds, ledger) stay after an account is deleted, under the empty profile (ADR 0028).
- BusIn becomes a collector for schools: pawaPay must enable the intermediary schedule on the account and confirm the
  service fee, and the rules on holding funds for others (CEMAC) and the tax on the fee are to be checked before going
  live.
- The school terms grow a payments part that carries pawaPay's sub-merchant terms (slice 7).
