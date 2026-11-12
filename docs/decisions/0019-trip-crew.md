# 0019: Trip crew, a driver and an assistant

Date: 2026-11-12. Status: accepted (owner, 2026-11-12). Extends the phase 4 trip control decisions (see the header of
the `trip_control` migration and [ADR 0014](0014-day-keys.md)), which gave a trip one assignee.

## Context

A driver often cannot work an app while driving. A second staff member on board, an assistant, can handle the scans and
the trip, while either phone can show where the bus is. Until now a trip had one `driver_id`: that person started and
ended it and shared the position.

## Decision

1. **A trip has a driver and, optionally, an assistant** (`trips.assistant_id`, staff of the same school). One person
   cannot be both on the same trip. Administrators set them, as they set the driver. Not more than one assistant now; a
   crew table can replace the column later if a trip ever needs more.
2. **Either crew member can start and end the trip** and share its position. Administrators always can. When nobody is
   assigned (no driver and no assistant) the old rules stand: any verified staff member can run the trip, and whoever
   started it shares the position. Scanning was already open to any staff member of the school and stays so.
3. **One phone leads the position.** When both share, a fix is kept from the phone that leads and set aside from the
   other, so the bus never jumps between two phones. The leader is whoever last had a fix kept; if it sends nothing for
   30 seconds (a dead phone, no signal) the other phone's next fix is kept and that phone leads. The lease is the table
   `trip_position_leases`, written only by `publish_position`; students can read the bus position, so the lease, which
   names staff, is not in `live_positions` and is read by staff only through `trip_position_holder`.
4. The student apps are unchanged: the bus is still one position per bus.

## Consequences

- The ops app lists a trip under "mine" for the assistant too, shows who leads, and tells the other phone it stands by.
- A leader whose fixes are all set aside by the other checks (accuracy over 100 m, closer than 5 seconds) loses the lease
  after 30 seconds, which is the wanted behaviour: the phone with the better signal ends up leading.
- Two crew members sharing means twice the battery use only while they lead; a phone that stands by still sends, but its
  fixes are dropped on the server. A later change can let the app pause sending while it stands by.
