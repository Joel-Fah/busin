# Student app

Flutter app for students (Android and iOS): Google sign-in, subscriptions with private proof upload, rotating QR code, scan history, live bus map, notifications.

Created in [Phase 3](../../docs/phases/phase-3-student-app.md). It contains no staff or admin code.

## State of the build

| Slice | What | State |
|---|---|---|
| 1 | Shell: theme, English and French, Google sign-in, session in secure storage, role and status gate, four-tab frame | Done |
| 2 | Subscribe with a stop and a private proof upload, status tracking | Done (this branch) |
| 3 | Rotating QR code with screenshot protection | Done (this branch) |
| 4 | Scan history, live bus map | Next |
| 5 | Push notifications (needs the owner's Firebase project) | |

## How it fits together

- `lib/src/auth/`: `AuthService` (an interface), its Supabase and Google implementation, the secure session storage, and `accessFor`, the pure rule that decides what a signed-in account may see. Only a verified student gets in; staff, administrators, pending and suspended accounts see a page that says why.
- `lib/src/providers.dart`: every service is a provider, so tests replace it with a fake. Data providers watch the signed-in user, so they reset on sign-out.
- `lib/src/router.dart`: `go_router`; the redirect reads the access state, so a screen is never reachable without the right to see it.
- Look and strings come from `busin_ui` (same palette and type as the admin portal). Data comes from `busin_data`.

## The subscription flow

- The semester is the one that includes today **at the school** (`SchoolClock`, from the school's IANA zone), or the next one if none is running. The phone's own zone and clock are not used for this.
- The photo is taken or chosen with `image_picker`, shrunk on the device (1600 px, quality 80), and checked by its first bytes, not its name: only JPEG, PNG and WebP up to 5 MB. The same limits are enforced by the private `proofs` bucket.
- Sending uploads the proof into the student's own folder (`<school>/<student>/<random>.<ext>`), then creates the request with that path. Proofs are never replaced or deleted by the student; a new request uploads a new file.
- A student sees their live request, or else the latest rejected or expired one with the school's reason, and can ask again. Pull down to refresh.
- Local backend: `npm run backend:start` now includes the storage service, which uploads need.

## The boarding code

- The server releases a per-student secret only to a verified student with an approved subscription (`get_my_qr_secret`). The app fetches it once, keeps it in the platform keystore under that user's id, and derives a new code every 30 seconds on the device with `QrCodeGenerator` (the format and test vector are in [the QR format guide](../../docs/guides/qr-code-format.md)). After the first fetch it needs no connection.
- The secret is deleted from the phone on sign-out, before the session ends. A second account on the same phone never sees the first one's.
- The code is drawn dark on white in both themes, with a countdown to the next one.
- On Android the screen is marked secure while the Boarding code tab shows (no screenshots, no screen recording, blank recent-apps preview). iOS cannot block screenshots, so there the note is not shown and nothing is claimed.
- Known limit: the code depends on the phone's clock. Phones set to automatic time are fine (the server accepts one 30-second window either side); a badly wrong clock gives codes the server refuses. Detecting clock skew against the server is not built yet.

## Run it

```bash
cp config/dev.example.json config/dev.json     # then fill in the values (see the setup guide)
cd apps/student
fvm flutter run --dart-define-from-file=../../config/dev.json
```

Without configuration the app shows which values are missing instead of failing later. Setup, including the Google client ids only the owner can create, is in [the student app setup guide](../../docs/guides/student-app-setup.md).

## Test it

```bash
cd apps/student && fvm flutter test
```
