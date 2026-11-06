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
