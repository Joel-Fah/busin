# Phase 4: ops app

Goal: staff scanner and driver mode that work on poor connectivity.

## Scope
- Scanner that verifies the rotating QR locally against the day's cached data.
- Local SQLite queue; idempotent sync of scans.
- Trip start and end; foreground location stream into `live_positions` (driver mode).
- Trip manifest and capacity count.
- Location permission requested only here, with an explanation screen.

## Exit criteria
- Unit tests green (verification, queue, sync).
- Owner device test on a real bus run, including a stretch with no connection.

## Depends on
Phase 2. The answer to where scanning happens (see STATUS.md).
