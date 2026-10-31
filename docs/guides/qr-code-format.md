# QR code format

The boarding QR is a rotating code, not the student id. The student app and the database must produce and check exactly the same value. This page is the contract; the student app (Phase 3) implements the generator.

## Code

```
busin1.<student uuid>.<window>.<mac>
```

| Part | Value |
|---|---|
| `busin1` | Format version |
| student uuid | The student's profile id, lower case with hyphens |
| window | `floor(unix seconds / 30)` as a decimal integer |
| mac | First 20 lower-case hex characters of `HMAC-SHA256(key = secret, message = "<student uuid>:<window>")` |

The secret is 32 random bytes, created on the server. The student device fetches it once with `get_my_qr_secret()` (returned as base64), keeps it in secure storage, and shows a new code every 30 seconds.

## Test vector

```
secret   = bytes 0x00 to 0x1f (hex 000102...1f)
student  = a1000000-0000-4000-8000-000000000001
window   = 57000000
mac      = c73e53d52fa5fb670e54
```

The database test `006_rotating_qr.test.sql` checks this value, and it was produced with Node's `crypto` module, an independent implementation. The Dart implementation must reproduce it in a unit test.

## Verification

Staff call `record_qr_scan(trip, code, stop, lat, lng, accuracy)`. The function:

1. requires a staff or admin caller;
2. checks the format, then the window: one window of tolerance either side, older is `expired_code`, newer is `invalid_code`;
3. recomputes the mac from the stored secret and compares it;
4. hands the student id to the scan check (verified account, approved subscription covering today, active trip of the caller's school), which records the scan once per trip and student.

Results are returned as data with a `reason` (`invalid_code`, `expired_code`, `account_not_verified`, `no_active_subscription`, `student_not_found`) or `valid: true` with `duplicate` and the student's name, photo and matricule.

## Rotating a secret

`rotate_my_qr_secret()` replaces the secret and is audited. Codes made with the old secret stop working at once.
