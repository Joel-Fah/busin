# Push notifications setup

What is needed to get a push from Firebase onto a phone. The Firebase project is the owner's (`busin-28e6a`, personal account, [ADR 0004](../decisions/0004-accounts-ownership.md)). The design is in [ADR 0010](../decisions/0010-push-notifications.md).

The app builds and works without any of this: with no Firebase file, push is simply off.

## 1. Register the Android app

Done for `busin-28e6a`: the Android app `BusIn Student` (package `com.joelfah.busin.student`, app id `1:551894412092:android:4568aaa9f62c9fb9dacc39`) is registered, and its config is saved as `apps/student/android/app/google-services.json` (git ignores that path, so it is not committed). On another machine, or after changing the package name, recreate it with the Firebase CLI:

```bash
firebase apps:sdkconfig ANDROID 1:551894412092:android:4568aaa9f62c9fb9dacc39 --project busin-28e6a --out apps/student/android/app/google-services.json
```

Or in the [Firebase console](https://console.firebase.google.com/): Project settings, your Android app, Download google-services.json. Leave the SHA-1 empty (Cloud Messaging does not need it). The first build with the file applies the Google services plugin.

## 2. Try it on your phone, before anything is deployed

1. Start the backend and the app. Sign in as a student with a pending subscription request. On the Subscription tab choose **Turn on notifications** and allow them in the system dialog. The phone's token is now registered (`select token, platform, locale from public.device_tokens;`).
2. In the Firebase console: Project settings, Service accounts, **Generate new private key** (the CLI cannot create one). Save the file **outside the repository** (for example `~/secrets/busin-firebase.json`). It is a secret: anyone with it can send notifications as BusIn.
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

## 4. The student web app (owner)

The PWA at `/app` (ADR 0021) uses the same Firebase project and the same `send-push` function; only the browser side is new.

1. In the Firebase console: Project settings, Your apps, add a **Web app** (no hosting). Copy its config.
2. Cloud Messaging, **Web Push certificates**: generate a key pair and copy the public key.
3. Set these public values on Vercel and in `apps/admin_web/.env.local`: `NEXT_PUBLIC_FIREBASE_API_KEY`, `NEXT_PUBLIC_FIREBASE_PROJECT_ID`, `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`, `NEXT_PUBLIC_FIREBASE_APP_ID`, `NEXT_PUBLIC_FIREBASE_VAPID_KEY`. Until they are set the app does not offer notifications.
4. Apply the migration `20261115140000_web_push.sql` (the platform `web`) and set the function secret `PUSH_WEB_BASE_URL` to the site's https address (no trailing slash), then redeploy `send-push`.
5. Try it: open `/app` in Chrome on Android (or add it to the home screen on an iPhone with iOS 16.4 or later), turn notifications on from Profile, Notifications, and approve a request from the portal.

## What is not covered yet
- iOS needs an Apple developer account, an APNs key uploaded to Firebase and the `GoogleService-Info.plist`. The app code is ready for it; the setup is not done.
- Notification kinds beyond subscription decisions (trip events) arrive with the later phases.
