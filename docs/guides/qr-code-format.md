# QR code format

The boarding QR is a rotating code, not the student id. The student app, the ops app and the database must produce and
check exactly the same value. This page is the contract ([ADR 0014](../decisions/0014-day-keys.md)). The generator and
the offline checker are `QrCodeGenerator` and `QrCodeVerifier` in [busin_core](../../packages/busin_core/).

## Code

```
busin2.<student uuid>.<window>.<mac>
```

| Part | Value |
|---|---|
| `busin2` | Format version (`busin1`, made straight from the secret, is no longer accepted) |
| student uuid | The student's profile id, lower case with hyphens |
| window | `floor(unix seconds / 30)` as a decimal integer |
| mac | First 20 lower-case hex characters of `HMAC-SHA256(key = day key, message = "<student uuid>:<window>")` |

The day key is `HMAC-SHA256(key = secret, message = "busin-day:YYYY-MM-DD")`, for the date at the school (its time
zone) when the window starts. The secret is 32 random bytes, created on the server. The student device fetches it with
`get_my_qr_secret()` (base64), keeps it in secure storage, and shows a new code every 30 seconds. Staff phones never see
a secret: `staff_day_keys()` gives them the day keys of today's riders.

## Test vector

```
secret   = bytes 0x00 to 0x1f (hex 000102...1f)
date     = 2024-03-09
day key  = dbe88e73a71c3914cdff93d45b3f2f989831796a69b9b00f5ccfaf0b2dfb29a5
           (base64 2+iOc6ccORTN/5PUWz8vmJgxeWppubAPXM+vCy37KaU=)
student  = a1000000-0000-4000-8000-000000000001
window   = 57000000 (starts 2024-03-09 16:00 UTC, 17:00 in Douala)
mac      = cef45af39487cc9ba62e
code     = busin2.a1000000-0000-4000-8000-000000000001.57000000.cef45af39487cc9ba62e
```

The database test `006_rotating_qr.test.sql` and the Dart test `packages/busin_core/test/qr_code_test.dart` both check
these values. They were produced with Node's `crypto` module, an independent implementation.

## Verification

On the staff phone (`QrCodeVerifier.check`), with today's day keys, even offline:

1. the format must be `busin2` with a valid uuid, window and mac;
2. the window must be within one window of now: older is expired, newer is invalid;
3. the student must be on today's list (otherwise "not on today's list");
4. the mac must match the one made with that student's day key.

On the server, `record_qr_scan(trip, code, stop, lat, lng, accuracy, scanned_at, client_id)`:

1. requires a staff or admin caller;
2. checks the format and the window against `scanned_at` (a scan made offline) or now (a live scan);
3. recomputes the mac from the stored secret's day key and compares it;
4. hands the student to the scan check (verified account, approved subscription on the scan day, a trip running at the
   scan time, of the caller's school), which records the scan once per trip and student, and once per `client_id`.

Results are returned as data with a `reason` (`invalid_code`, `expired_code`, `account_not_verified`,
`no_active_subscription`, `student_not_found`) or `valid: true` with `duplicate` and the student's name, photo and
matricule.

## Rotating a secret

`rotate_my_qr_secret()` replaces the secret and is audited. Codes made with the old secret stop working on the server at
once; a staff phone that downloaded the old day key keeps accepting them offline until it refreshes, and the server
refuses those scans on sync.
