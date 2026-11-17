# Terms for schools (draft, for owner review)

The text schools accept on their profile page lives in
[apps/admin_web/lib/legal/school-terms.ts](../../apps/admin_web/lib/legal/school-terms.ts), in English and French. Its
version is `SCHOOL_TERMS_VERSION` in [apps/admin_web/lib/school.ts](../../apps/admin_web/lib/school.ts).

Version `2026-11-17` (adds payments to `2026-11-11`, which added staff phones, insights, invites and automatic trip
ends to `2026-11`). Status: draft written
by Claude, not reviewed. Before schools are asked to accept for real, the owner (and a lawyer if
needed) reviews it.

What it covers, in short:
- what using BusIn means for the school;
- the school's and students' data stay the school's, are never sold or mixed with another school's; students' phones
  are never tracked (Show me keeps the position on the phone), and a staff phone shares the bus position only during a
  trip it runs;
- **staff phones** keep the day's riders and a day key for offline checks (ADR 0014); the school keeps them locked and
  suspends a lost one;
- **insights**: counts per stop and departure, and distances from shared areas, only for groups of five or more;
- **name and logo**: accepting allows BusIn to show the school's name, city and logo publicly (for example the wall of
  schools on the BusIn site, and the student app) while "Show our school publicly" is on, and the school can turn it
  off at any time; the school confirms it has the right to use the logo it uploads;
- administrators: access only for people who need it (including people added by email, ADR 0015), actions are the
  school's responsibility and are audited; trips left running from an earlier day end automatically;
- **payments** (ADR 0029): BusIn collects mobile money payments for the school through pawaPay and passes its share on;
  BusIn's charge per paying student, taken from the balance or invoiced monthly; the school chooses who pays the fees;
  a 7-day hold and weekly payouts to a number confirmed by a second administrator (a replacement used after 7 days);
  refunds decided by the school, BusIn's own errors refunded at its cost;
- **pawaPay's sub-merchant terms**: the school accepts them (pawaPay can enforce them directly and suspend payments),
  sells only lawful services, does not surcharge students beyond what they allow, keeps payment records 10 years, and
  answers questions about a disputed payment within one business day. Merchant terms: pawapay.io/merchant-terms-of-service
  (to be read in full by a lawyer before schools accept);
- changes: a meaningful change means a new version, which every school is asked to accept again.

How it is enforced: `public.schools.public_listing` can only be on once `terms_accepted_at` is set (a table check and
`admin_update_school_profile`), and `public.public_schools()` (the only thing a visitor can read) returns listed schools
with their public fields only.
