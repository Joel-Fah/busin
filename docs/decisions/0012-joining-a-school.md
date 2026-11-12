# 0012: Joining a school, by email domain or with the school's approval

Status: accepted, 2026-11-11 (the owner chose this in the ideas round). Supersedes the domain-only rule of
[ADR 0004](0004-accounts-ownership.md), which limited sign-up to the domains in the database allow-list.

## Context
Until now a student could only sign up with a Google account on one of the school's email domains: the sign-up trigger
put them in that school as verified, and refused every other email. Some schools have no institutional email for
every student, or students use a personal Gmail. The owner wants those students to be able to join too, with the school
in control.

## Decision
1. **School email (unchanged):** an email on one of a school's domains joins that school directly, verified. The app
   shows "You are joining X" once, with a way out ("Not my school?").
2. **Other emails, only where a school allows it:** a school can turn on "Also accept students with other email
   addresses" on its profile, optionally limited to some domains (empty means any). An email that matches no school
   domain may sign up only if at least one active school allows it; the account starts **pending with no school**.
3. The student picks a school from the schools that allow their email (`list_open_schools`) and asks to join
   (`request_school`). The account stays pending; it can change its request or withdraw it while waiting.
4. **The school decides:** its admins see the request in People, To verify, and verify it or decline it with a reason
   (`admin_verify_member`, `admin_decline_member`). A declined student goes back to choosing and sees the reason. Both
   are audited. There is no push for these: a pending account cannot register a phone for push ([ADR 0010](0010-push-notifications.md)
   allows verified accounts only), so the app's waiting screen checks again when it is opened or brought back.
5. **Isolation does not change:** a pending or school-less account reads nothing of any school (the helpers behind RLS
   return a school only for verified accounts), gets no QR secret, cannot subscribe and cannot edit its profile. What it
   may see is the list of schools that allow its email (name, city, logo) and its own request.
6. An email that matches no school domain and no open school is still refused at sign-up, as before.

## Consequences
- `profiles.school_id` becomes nullable, allowed only for a pending student (a check constraint).
- Admins have a verification queue to watch; the nav shows its count (see the nav badges slice).
- Any account can now reach the pending state, so the pending state must stay harmless: pgTAP tests prove it reads
  nothing and can do nothing but choose a school.
- Rate limits on `request_school` keep a pending account from spamming a school's queue.
