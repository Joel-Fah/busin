# Push notifications setup

What is needed to get a push from Firebase onto a phone. The Firebase project is the owner's (`busin-28e6a`, personal account, [ADR 0004](../decisions/0004-accounts-ownership.md)). The design is in [ADR 0010](../decisions/0010-push-notifications.md).

The app builds and works without any of this: with no Firebase file, push is simply off.

## 1. Register the Android app (about 3 minutes)

In the [Firebase console](https://console.firebase.google.com/), open the project `busin-28e6a`:

1. Project overview, then the Android icon (Add app).
2. Android package name: `com.joelfah.busin.student`. Nickname: `BusIn Student`. Leave the SHA-1 empty (Cloud Messaging does not need it).
3. Register, then **Download google-services.json**.
4. Save it as `apps/student/android/app/google-services.json`. Git ignores that path, so it is not committed. Skip the console's "add the SDK" steps: the project already has them.

Run the app again (`fvm flutter run --dart-define-from-file=../../config/dev.json`). The first build after adding the file applies the Google services plugin.

## 2. Try it on your phone, before anything is deployed

1. Start the backend and the app. Sign in as a student with a pending subscription request. On the Subscription tab choose **Turn on notifications** and allow them in the system dialog. The phone's token is now registered (`select token, platform, locale from public.device_tokens;`).
2. In the Firebase console: Project settings, Service accounts, **Generate new private key**. Save the file **outside the repository** (for example `~/secrets/busin-firebase.json`). It is a secret: anyone with it can send notifications as BusIn.
3. Send a test push straight to that phone:

   ```bash
   npm run dev:push -- ~/secrets/busin-firebase.json you@ictuniversity.edu.cm approved fr
   ```

   Lock the phone first to see the real system notification, then tap it: the app opens on the Subscription tab.

If it does not arrive: check that the app has notification permission in the phone's settings, that `device_tokens` has a row for your user, and read the status the script prints (401 means the key is wrong or for another project; 404 or UNREGISTERED means the token is stale, so open the app again).

## 3. On a hosted project (owner, later)

1. Apply the push migration (`20261105150000_push_notifications.sql`) after approving it.
2. Set the secrets (never in git): `supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat ~/secrets/busin-firebase.json)" PUSH_SECRET="$(openssl rand -hex 32)"`.
3. Deploy: `supabase functions deploy send-push`.
4. Choose what calls it (ADR 0010, option A: a `pg_cron` job every minute that posts to the function with the `x-push-secret` header).

## What is not covered yet
- iOS needs an Apple developer account, an APNs key uploaded to Firebase and the `GoogleService-Info.plist`. The app code is ready for it; the setup is not done.
- Notification kinds beyond subscription decisions (trip events) arrive with the later phases.
