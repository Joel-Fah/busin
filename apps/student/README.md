# Student app

Flutter app for students (Android and iOS): Google sign-in, subscriptions with private proof upload, rotating QR code, scan history, live bus map, notifications.

Created in [Phase 3](../../docs/phases/phase-3-student-app.md). It contains no staff or admin code.

## State of the build

| Slice | What | State |
|---|---|---|
| 1 | Shell: theme, English and French, Google sign-in, session in secure storage, role and status gate, four-tab frame | Done |
| 2 | Subscribe with a stop and a private proof upload, status tracking | Done (this branch) |
| 3 | Rotating QR code with screenshot protection | Done (this branch) |
| 4a | Scan history | Done (this branch) |
| 4b | Live bus map | Done (this branch) |
| 5 | Push notifications | App side done (this branch); needs `google-services.json` to try, see the push setup guide |

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

## Scan history

- The History tab lists the student's own boardings, newest first, grouped by the day **at the school** (the school's IANA zone, not the phone's). Each row shows the stop, the direction of the trip and the time.
- Pages of 20 load as the list is scrolled near its end, and also when a page does not fill the screen. One trip request per page, not per row. A failed page keeps the list and shows a retry row; scrolling never retries a failure by itself.
- The server decides what a student may read: asking for another student's boardings returns nothing (see the live test).

## The live bus

- The My bus tab lists the buses on a trip right now (one request for trips, one for their plates), and shows the live position of one on a map with the stops and the student's own stop marked. The schema has no link between a student and a bus (there are no routes yet), so the bus shown first is the one on the trip the student boarded last, otherwise the one that started most recently; with several running, chips switch between them.
- The position arrives through one Realtime subscription **filtered to that bus on the server**, which the live test proves; a phone never receives other buses' positions. The subscription is dropped while another tab shows and taken up again on return, so nothing listens in the background.
- A position older than two minutes is shown as "last seen", never as fresh. A failed feed says so and can be retried.
- The map is MapLibre with OpenFreeMap (no key, no account; ADR 0008). `MAP_STYLE_URL` in `config/dev.json` points it elsewhere. The screen talks to a `MapScene` and a swappable surface, so everything but the drawing is unit tested; the drawing itself (`maplibre_surface.dart`) needs a device to judge.
- To see a bus move locally: `npm run backend:start` (now includes Realtime), then in another terminal `npm run dev:bus` (see `tools/simulate-bus.mjs`).

## Push notifications

- Firebase is optional at build time: without `android/app/google-services.json` (git-ignored, the owner's file) the app builds and runs with push off; with it, `FirebasePushService` starts.
- Nothing is asked at launch. A student who is already allowed is registered silently; otherwise, once they have a **pending request** (something to wait for), the Subscription tab offers "Turn on notifications" once, and "Not now" hides it for good.
- The token is registered with the server with the phone's platform and language (the server words the notification in French or English), moved along if Firebase replaces it, and removed on sign-out before the session ends.
- A notification carries only a kind and an id. Tapping it opens the Subscription tab and reloads it; one that arrives while the app is open refreshes the status and shows a short banner. Wording and design: [ADR 0010](../../docs/decisions/0010-push-notifications.md). Setup and a real test on a phone: [the push setup guide](../../docs/guides/push-setup.md).

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
