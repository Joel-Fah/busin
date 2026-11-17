# Play Console: Data safety and app content answers

Drafted on 2026-11-16 from what the code does (`apps/student`, `apps/ops`, `packages/*`, the Supabase schema). Check
them again before each submission if a feature changed. The privacy policy these answers must match is at
`/legal/privacy` (the same text as in the apps). Not legal advice.

## Both apps
- **Data encrypted in transit:** yes (HTTPS only; no cleartext traffic in release builds).
- **Users can ask for their data to be deleted:** yes, in the app (Profile, Delete my account) and on the web
  (`/delete-account`). See [ADR 0028](../decisions/0028-account-deletion.md).
- **Data shared with third parties:** no. Supabase (hosting the data) and Firebase (push notifications, crash reports)
  process data for BusIn as service providers, which Play does not count as sharing. With mobile money payments
  (ADR 0029, not live yet): pawaPay and the operator process the payer's number and the amount to make the payment;
  declare them as payment processors, which Play also does not count as sharing.
- **Ads:** none. **In-app purchases:** none in Play's sense. A bus pass is a physical service paid to the school,
  either outside the app (a receipt) or, once payments are live, by mobile money through pawaPay; Play Billing does not
  apply to physical services.
- **Account creation:** Google sign-in only. **Deletion link:** `https://<site>/delete-account`.

## Student app (`com.joelfah.busin.student`)

| Play data type | Collected | Why (Play purpose) | Optional? |
|---|---|---|---|
| Name | Yes | App functionality, account management | Required |
| Email address | Yes | App functionality, account management | Required |
| Phone number | Yes | App functionality (the school can reach the student) | Required by setup |
| User IDs | Yes (the account id; the school matricule) | App functionality, account management | Matricule required by setup |
| Approximate location | Yes ("My area", snapped to about 500 m by the server) | App functionality (nearest stops, stop planning) | Optional |
| Precise location | No (Show me on My bus uses it on the phone only, never sent) | | |
| Photos | Yes (the payment proof the student attaches) | App functionality | Required for a request |
| Other user-generated content | No | | |
| Crash logs | Yes (Crashlytics, release builds, no personal data in the reports) | Analytics (app stability) | Required |
| Diagnostics | Yes (device model and OS with a crash) | Analytics | Required |
| Device or other IDs | Yes (the push token) | App functionality (notifications) | Optional (notification permission) |
| App activity: other actions | Yes (subscription requests, boardings, streaks) | App functionality | Required |
| Financial info: purchase history | Yes, once mobile money payments are live (payments and refunds: amounts, operator, the payer's number partly hidden, receipts) | App functionality (paying the pass, receipts, refunds) | Optional (a receipt can be sent instead) |

Not collected: card details or mobile money PINs (the PIN is entered in the operator's own prompt, never in BusIn;
the full payer number goes to pawaPay and is not kept), contacts, messages, health, audio, files other than the proof,
web browsing. Until mobile money payments are live, financial info is not collected at all.

Permissions to explain if asked: location (foreground only, for My area and Show me; background location is removed
from the manifest), notifications, photos or camera (the proof).

## Ops app (`com.joelfah.busin.ops`), staff only

| Play data type | Collected | Why | Optional? |
|---|---|---|---|
| Name, email address | Yes | App functionality, account management | Required |
| Precise location | Yes (the bus position while a trip runs, and where a boarding was scanned) | App functionality (live bus for students) | Required for driver mode |
| Device or other IDs | Yes (push token) | App functionality | Optional |
| Crash logs, diagnostics | Yes (Crashlytics) | Analytics | Required |
| App activity | Yes (trips started and ended, boardings scanned) | App functionality | Required |

The camera reads boarding codes on the phone; no picture is kept or sent. A day's rider list (names, photos,
matricules, stops) is kept on the staff phone for that day only, for offline checks, and deleted at sign-out.

**Foreground service declaration (location type):** driver mode shares the bus position while a trip runs, with a
visible notification; it stops when the trip ends. Play asks for a short video: start a trip, show the notification and
the bus moving in the student app, end the trip.

## App content (both)
- **Target audience:** 18 and over (university students and staff). If schools with younger students join, review the
  Families policy first.
- **Content rating:** no violence, no user-to-user communication, no public user content; location shared with the
  school's own users only.
- **App access for review:** sign-in is restricted to schools' accounts. Give reviewers a demo account (a demo school
  that accepts their Google account, with a seeded subscription for the student app and a scheduled trip for ops), and
  write the steps in "App access".
