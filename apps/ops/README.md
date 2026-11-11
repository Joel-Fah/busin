# Ops app

Flutter app for staff (Android): today's trips, start and end, an offline-capable boarding scanner with a scan queue,
and driver mode (sharing the bus position). Built in [Phase 4](../../docs/phases/phase-4-ops-app.md).

## Run it

```bash
npm run dev:device -- ops     # on a connected Android phone, against the local backend
cd apps/ops && fvm flutter test -j 1
```

Sign-in uses Google: the Google Cloud project needs an Android OAuth client for `com.joelfah.busin.ops` with the
signing certificate's SHA-1 (debug and release). Promote an account to staff in the portal (People) or locally with the
local setup guide.

## How it works

- **Who:** verified staff and admins. Students are told to use the student app.
- **Trips:** the staff member assigned to a trip starts and ends it; when nobody is assigned, any staff member can;
  admins always can (enforced by `start_trip` and `end_trip`).
- **Scanning offline ([ADR 0014](../../docs/decisions/0014-day-keys.md)):** the phone downloads today's day keys
  (`staff_day_keys`) into secure storage and checks each code itself (`decideScan`), so the door works without a
  connection. Each scan is queued in SQLite (drift) with its time, stop and id, and `ScanSyncer` sends it when it can;
  the server checks it again. Sign-out waits until the queue is empty; scans are never dropped.
- **Location:** asked for only on the scanner (the stop of each scan) and in driver mode, each time after an
  explanation. Driver mode runs a foreground service with a visible notification while the trip runs, sending the
  position every 10 seconds (`publish_position`); it stops when the trip ends or is turned off.
