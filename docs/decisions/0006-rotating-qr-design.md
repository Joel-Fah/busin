# 0006: Rotating QR with a per-student secret

Status: accepted, 2026-10-30.

## Context
The original QR was the student's permanent id, so a photo of it worked forever (audit finding C4). Students often have no data connection at a stop, so the code must be producible offline.

## Decision
Each student has a server-held 32-byte secret. The student device fetches it once and derives a 30-second code locally. Verification happens in a database function (no separate Edge Function is needed). Format and test vector: [qr-code-format.md](../guides/qr-code-format.md).

## What this fixes and what it does not
- Fixed: a photographed or screenshotted code stops working within about a minute, and the old plain-id QR is refused.
- Not fixed: a student can give their secret to another person, who can then generate codes. The secret is released only to a verified student with an active subscription, stored in secure storage on the device, and can be rotated, but a determined student can still extract and share it.

## Options if sharing becomes a real problem
- Online issue: the student app asks the server for each code (needs a connection at the stop).
- Device binding: tie the secret to one device with Play Integrity attestation.
- Boarding limits: flag a student scanned at two stops too close in time (the density data will show this).

These are decided later with real usage data; none is built now.

## Consequences
The ops app can later cache secrets for the day's trip to verify offline (Phase 4), which widens exposure and needs its own review.
