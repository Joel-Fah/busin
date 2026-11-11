# 0014: Day keys, so staff phones can check boarding codes offline

Status: accepted, 2026-11-11 (the owner chose day keys at the start of phase 4). Supersedes the code format of
[ADR 0006](0006-rotating-qr-design.md) (`busin1`); the rest of ADR 0006 (a server-made secret per student, a code that
changes every 30 seconds, the window tolerance, rotation) still holds.

## Context
Staff scan students at each stop, and buses often have no connection. With `busin1` only the server could check a
code, because only the server and the student hold the secret, and a scan sent later was checked against the server's
clock, so it came back expired. Giving staff phones the students' secrets would expose them for good if a phone were
lost.

## Decision
1. **A key per school day.** `day_key = HMAC-SHA256(key = secret, message = "busin-day:YYYY-MM-DD")`, for the
   school-local date of the code's window. The code becomes `busin2.<student uuid>.<window>.<mac>`, where `mac` is the
   first 20 hex characters of `HMAC-SHA256(key = day_key, message = "<uuid>:<window>")`. The student phone derives the
   day key from the secret it already holds, in the school's time zone (not the phone's).
2. **Staff phones hold only today's keys.** `staff_day_keys()` gives verified staff the day keys of every verified
   student of their school with an approved subscription covering today, with the name, photo, matricule and stop the
   result card shows. Each download is audited. The phone keeps them in secure storage and checks codes on the spot
   with the same rules as the server (`QrCodeVerifier` in busin_core).
3. **Scans sent later are checked against when they were made.** `record_qr_scan` takes `p_scanned_at` and
   `p_client_id`. The code window is checked against the scan time, which must not be in the future (two minutes of
   slack) or older than a day, and must fall while the trip was running (five minutes of slack). The scan keeps its
   time, and the phone's id makes a second send record nothing.
4. **The server still decides.** On sync every scan is checked again (code, account, subscription on the scan day).
   An offline acceptance that the server refuses is shown to staff afterwards.
5. **`busin1` is no longer accepted.** Nothing had been released, so no phone in the field shows it.

## Consequences
- A lost staff phone exposes one day of keys for one school, never a secret. A revoked or suspended student drops out
  of the next download; offline, until the phone refreshes, their code still checks as valid at the door, and the
  server refuses it on sync.
- The key download covers the riders of the whole school for the day; a school of a few hundred riders is a few tens
  of kilobytes.
- A code near the school's midnight uses the next day's key; the staff phone needs both days' keys only for a bus
  running across midnight, which BusIn does not plan for.
- Test vectors (Node crypto, the database and Dart agree) are in [docs/guides/qr-code-format.md](../guides/qr-code-format.md).
