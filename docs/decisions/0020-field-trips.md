# 0020: Starting a trip nobody scheduled (field trips)

Date: 2026-11-12. Status: accepted (owner, 2026-11-12). Builds on [ADR 0019](0019-trip-crew.md).

## Context

An administrator can forget to schedule a trip, and then the bus cannot run in the system: nobody can scan, students
cannot follow it. Staff are on the bus and know what is running.

## Decision

1. **A staff member can start a trip from the ops app when none was scheduled** (`start_field_trip`). They give the bus
   (in service, not on a trip), the direction, and whether they are the driver or the assistant. The trip runs at once.
2. **They are assigned on the spot:** as the driver, or as the assistant. The other crew member can be picked from the
   school's verified staff (the driver when the caller is the assistant, the assistant when they are the driver), or
   left for later. A person picked is put on the trip and told: a `crew_assigned` row is queued for push (no names, no
   bus in the text). They can run it and share the position like any crew member (ADR 0019).
3. **It is marked.** `trips.origin` is `field` (or `scheduled`) and `trips.created_by` names who made it. The portal shows
   a "Started in the field" chip and a filter, and the overview counts today's. Each one is in the audit log
   (`trip.started_in_field`).
4. **Guards, on the server:** verified staff or admins only; the school switch (`schools.allow_field_trips`, on by
   default, set by an administrator with `admin_set_field_trips`, audited) must be on; the bus must be in service and
   not on a running trip; if a scheduled trip exists today for that bus and direction it is started instead
   (`use_scheduled_trip`); at most 5 a day per person (`too_many_field_trips`).
5. **The options come in one call** (`field_trip_options`): whether it is allowed, the free buses and the staff to pick
   from, names only, at most 200 each, so the app loads no more than the form needs.

## Consequences

- A mistaken trip creates real boarding data and, for an inbound trip, can trigger "bus near my stop" pushes to
  students. The guards and the audit trail limit it; administrators see it in the list the same day.
- Push to the other crew member reaches a phone only when the ops app registers for push, which it does not yet (only
  the student app does; the ops app would need its own Firebase app and registration). Until then the person finds the
  trip under "Assigned to you" when they open the app. The server side is ready.
- The assignment does not ask for consent. A person added by mistake can be removed by an administrator from the portal
  only before the trip starts, and these trips start running at once; an administrator can end it.
