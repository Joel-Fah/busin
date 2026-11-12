# Student app setup

What is needed to run the student app against a Supabase project. The Google steps create cloud resources, so they are the owner's (see [ADR 0004](../decisions/0004-accounts-ownership.md)).

## 1. Values the app is built with

Copy `config/dev.example.json` to `config/dev.json` (git ignores it) and fill in:

| Value | Where it comes from |
|---|---|
| `SUPABASE_URL` | Local: `http://127.0.0.1:54321` (on an Android emulator use `http://10.0.2.2:54321`). Hosted: the project URL. |
| `SUPABASE_PUBLISHABLE_KEY` | `npx supabase status` locally, or the project's API settings. Public by design; Row Level Security protects the data. |
| `GOOGLE_SERVER_CLIENT_ID` | The Web application OAuth client id (step 2). |

None of these is a secret. Never put a service key in the app.

## 2. Google sign-in (owner)

The app signs in with the Google sheet on the phone and gives Supabase the ID token (`signInWithIdToken`). Supabase checks the token against its Google client id, so the app and Supabase must use the same **Web application** client.

1. Create the Web application client and put its id and secret in Supabase as described in the [Google sign-in guide](google-sign-in.md). The same client id is `GOOGLE_SERVER_CLIENT_ID` in the app. (Locally, if Supabase rejects the token for its audience, list the Web client id first in `SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID`; Supabase accepts several, separated by commas. Turn on "Skip nonce checks" only if sign-in fails with a nonce error.)
2. In the same Google Cloud project, create an OAuth client of type **Android** with package name `com.joelfah.busin.student` and the SHA-1 of the signing key (the debug key for development: `cd apps/student/android && ./gradlew signingReport`). Nothing from this client goes into the app; Google matches the app by package and key. Each person who builds with their own debug key needs their SHA-1 added.
3. Create an OAuth client of type **iOS** with bundle id `com.joelfah.busin.student`. Done for this project: its client id is in `apps/student/ios/Runner/Info.plist` as `GIDClientID`, with the reversed id (`com.googleusercontent.apps.<the id before .apps.googleusercontent.com>`) as a URL scheme under `CFBundleURLTypes`, so Google can return to the app after sign-in. Both are public identifiers, not secrets. A different iOS client means changing both lines. iOS sign-in has not been tried on a device yet (building for iOS needs a Mac).

The school's email domain must be in `school_domains` or the server refuses the sign-up; the app then says the account is not allowed.

## 3. Reaching the local backend from a phone

`127.0.0.1` on a phone or emulator is the phone itself, so the backend and portal ports are forwarded over USB. One command does everything:

```bash
npm run dev:device                  # student app on the connected device
npm run dev:device -- ops           # ops app
npm run dev:device -- --device ID   # pick one when several are connected (or --all)
npm run dev:device -- --no-run      # only check the backend and set up the tunnels
```

It checks the local backend (and starts it if Docker is running), runs `adb reverse` for ports 54321 and 3000 on each device, starts the app with `config/dev.json`, and restores the tunnels whenever a USB reset drops them while the app runs. By hand, the equivalent is `adb reverse tcp:54321 tcp:54321`, repeated on every reconnect. Google sign-in also needs the Web client id and secret in `supabase/.env` (see the Google sign-in guide) with the local backend started.

## 4. Local backend

```bash
npm run backend:start    # includes the storage and Realtime services (proof upload, live bus)
npm run seed:demo        # optional demo people, stops, trips
```

The repository tests can also be run against this backend with a real student session (storage and Row Level Security included):

```bash
cd packages/busin_data && fvm dart test -t live --run-skipped
```

It creates a throwaway student and removes everything it made.

To watch a bus move in the app, run the simulator while a trip is running (the demo data has one):

```bash
npm run dev:bus                 # drives the bus of the most recently started trip along the stops
npm run dev:bus -- DEMO-101     # or a bus by plate
```

## Offline behaviour

The student app keeps a saved copy of what the boarding pass needs (the profile, the school and where the subscription stands) in the phone's secure storage, one copy per signed-in user. The server is always asked first. Only when it cannot be reached (no connection, or no answer: 3 seconds when a saved copy exists, 15 seconds when it does not) is the copy used, and then a notice at the top says so and when the copy dates. A refusal from the server is never hidden by the copy, and signing out, or the server blocking the account, deletes it.

- With an approved subscription whose semester is running at the school, an offline start goes straight to the boarding code (the secret kept on the phone makes the code).
- After the semester's last day, or before its first, the saved pass is not shown as working; the app asks to reconnect.
- Sending or changing a request needs a connection; the button is disabled with the reason.
- When the network returns, or the app is opened again, the app asks the server again (package `connectivity_plus`), and a decision made meanwhile (a revoked subscription) replaces the copy and locks the pass. The door is the authority: the scan is checked by the server, so a revoked pass still shows a code offline but is refused when scanned.

To try it on a device: open the app once online, then cut the route to the local backend with `adb reverse --remove-all`, force stop the app and open it again. Restore with `npm run dev:device -- --no-run` (or the two `adb reverse` commands) and the notice disappears by itself.

