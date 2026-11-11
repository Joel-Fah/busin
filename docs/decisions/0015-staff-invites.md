# 0015: Adding staff by email

Date: 2026-11-11. Status: accepted (owner, 2026-11-11). Extends [ADR 0012](0012-joining-a-school.md).

## Context

Staff and administrators who have no school email could only get in through the student app's join request, then be
promoted in People. The ops app turns away anyone who is not staff yet, so a driver had to install the student app just
to ask to join.

## Decision

1. An admin adds a person by email with the role staff or admin (People, Add staff by email; `admin_invite_staff`).
2. If an account with that email already belongs to the school, or has no school yet, it gets the role at once and is
   verified. An account of another school, or an email another school has invited, is refused.
3. Otherwise the invite (`staff_invites`, one per email, 30 days) waits. The sign-up trigger checks it first: signing up
   with exactly that Google email joins the school verified, with the role, whatever the domain; the invite is used up.
4. The email Google returns is the proof. Roles are still never chosen by the client; every step is audited
   (`invite.created`, `invite.applied`, `invite.accepted`, `invite.cancelled`). Only the school's admins read its invites.

## Consequences

- An admin who types the wrong email gives a role to whoever owns that address; the page says which account and role, the
  invite can be withdrawn, and the role changed back in People.
- Expired invites are ignored and stay in the table until withdrawn or invited again; a cleanup job can come with the
  other pg_cron jobs.
