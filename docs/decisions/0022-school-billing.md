# 0022: School billing

Status: accepted, 2026-11-14 (the owner chose this). Payment itself stays outside BusIn for now: students pay the school
and upload a proof, as before. Mobile Money (phase 6) can later mark parts paid automatically.

## Context
A school decides how much the bus costs and how students pay it. Until now BusIn had no price at all: a request carried
a receipt photo and an administrator checked it by hand. Schools bill differently: some per semester, some per month,
and some let students pay a semester in parts.

## Decision
1. **The school's billing.** On `schools`: `billing_period` (`semester` or `month`), `price_xaf` (the price of one
   period, whole units of `currency`, which is `XAF` and not editable yet) and `installment_plan` (null, or one of
   `50-50`, `40-30-30`, `30-60-10`). Set by an administrator through `admin_set_billing`, audited. Installments split
   a semester only: a month is paid at once.
2. **Nothing before billing.** While a school has not set billing, a student's request is refused (`billing_not_set`).
   Existing subscriptions are untouched. The portal's overview pushes the administrator to set it up first.
3. **A copy on each subscription.** A request stores the period, the price and the plan that applied when it was
   made (`billing_period`, `amount_xaf`, `installment_plan`). Changing billing later only affects new requests.
4. **The server prices.** A student sends only `payment_mode` (`full` or `installments`) and, for monthly billing,
   `period_start` (the first day of this month or the next). A trigger fills in the rest and refuses what does not fit
   (`installments_not_offered`, `month_required`, `month_not_allowed`, `period_ended`, `already_requested`). The
   student's insert grant does not include the price or the end date.
5. **Monthly subscriptions cover one month.** `period_start` and `period_end` are the month, clipped to the semester.
   They are null for a whole-semester subscription, so moving a semester's dates needs nothing else. Everything that
   asks "is this student covered today" (the boarding code, the scan, the day keys, live positions, bus near my stop,
   stop counts) reads `coalesce(period, semester)`. One live request per period. A past month cannot be approved.
6. **The student's preference.** `profiles.payment_preference` (`full`, `installments` or null), set through
   `set_payment_preference`, fills in the request form. A student who has none chooses in the form, and is asked
   whether to keep that choice.
7. **Installments are tracked part by part** (#433): each part has its amount and due date, the student uploads a
   proof for each, and an administrator marks each paid or rejected. The first part is enough to approve the
   subscription.

## Consequences
- Every school must set billing once before its students can ask again; the live schools need this right after the
  migration.
- Students on monthly billing ask again each month; the apps offer this month and the next.
- Prices are readable by the school's members (they need them), like the rest of the school's row.
