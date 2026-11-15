# 0026: Staff access requests, and student and staff role changes

Status: accepted, 2026-11-15 (the owner's request). Changes one rule of the roles migration of 2026-11-14
(`20261114160000_roles_suspended`), which kept students and staff apart for good.

## Context
Someone who signs in to the ops app before their school invited them gets a student account: sign-up never gives a staff
role, and the phone cannot ask for one. The ops app then showed a dead end ("this app is for staff"), and nothing in the
portal could turn the account into staff, since a student could never become staff and inviting a student's email was
refused. The only way out was a manual change in the database.

## Decision
1. **Asking.** A student account that is not suspended can ask a school for staff access from the ops app. The school
   is found as for students: the school of the email's domain when it has one, else the account's own school when it is
   a student of one, else any active school to choose from. With one school to ask, the app names it and sends at once. One request at a time; it can be withdrawn, and not changed
   more than once every 30 seconds. The request is kept on the profile (`staff_requested_at`, `staff_request_school`)
   and written only through `request_staff_access`. The phone never chooses a role: it only asks.
2. **Deciding.** The administrators of the school asked see the requests on People, To verify (through
   `admin_staff_requests`, since the person may not belong to the school yet). Approving makes the account verified staff
   of the school. It is refused while the person has a subscription still running or waiting. Declining clears the
   request and keeps an optional note the person sees. Nothing else changes: the account stays as it was, the email is
   not blocked, and the person can still use it as a student or ask again.
3. **Role changes.** An administrator can switch a verified member between student and staff, both ways, after a
   confirmation. Becoming staff is refused with a live subscription; becoming a student is refused while on a running
   trip or on the crew of coming trips (reassign them first). A student and an administrator never swap directly (one
   step through staff). The last administrator rule stays.
4. Every request, decision and role change is in the audit log.
5. **Not in this decision:** deleting or removing accounts. That is handled separately.

## Consequences
- One email is one account with one role at a time: student and staff access are never held together. Someone who
  needs both uses two Google accounts (a school email as a student, another invited as staff), or the role is switched.
- A sign-in with an email that no school accepts is still refused before any account exists (the server cannot tell
  which app it came from), and the ops app says to ask the school for an invite. Inviting stays the direct path.
- Installed ops apps from before this change show the old dead end until updated; the request needs the new build.
