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
3. Create an OAuth client of type **iOS** with bundle id `com.joelfah.busin.student`. For iOS its client id and reversed form also go into `ios/Runner/Info.plist` (`GIDClientID` and a URL scheme). That is completed before iOS support is claimed.

The school's email domain must be in `school_domains` or the server refuses the sign-up; the app then says the account is not allowed.

## 3. Reaching the local backend from a phone

`127.0.0.1` on a phone or emulator is the phone itself. Forward the port over USB (or the emulator bridge) so the same `config/dev.json` works:

```bash
adb reverse tcp:54321 tcp:54321
```

Run it each time the device reconnects. Google sign-in also needs the Web client id and secret in `supabase/.env` (see the Google sign-in guide) with the local backend started.

## 4. Local backend

```bash
npm run backend:start    # includes the storage service the proof upload needs
npm run seed:demo        # optional demo people, stops, trips
```

The repository tests can also be run against this backend with a real student session (storage and Row Level Security included):

```bash
cd packages/busin_data && fvm dart test -t live --run-skipped
```

It creates a throwaway student and removes everything it made.
