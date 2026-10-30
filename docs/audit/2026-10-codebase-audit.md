# BusIn codebase audit and roadmap

| | |
|---|---|
| **Date** | 19 October 2026 |
| **Scope** | Whole repository, branch `dev` at commit `664d981` |
| **Toolchain** | Flutter 3.35.6 · Dart 3.9.2 (pinned in `.fvmrc`) |
| **Size** | ~25k lines of Dart, excluding generated l10n |
| **Online version** | https://claude.ai/artifact/7k9GCCUHC7dDjsRMdeEtLg |

This report covers what works today, what is broken or risky, and a plan for the pending work: student density mapping, splitting the student and admin apps, data-driven route suggestions, bus tracking, and opening BusIn to other schools.

**Method.** I read the full service, model and controller layers, the routing and the platform configs. I ran `dart analyze` on the pinned SDK. I checked one suspected bug (H4) by running the code. I did **not** run the app on a device, and the deployed Firestore rules are not in the repo, so some security findings depend on what those rules allow.

---

## Contents

1. [Verdict](#1-verdict)
2. [What works](#2-what-works)
3. [Findings](#3-findings)
4. [Configuration and secrets (the .env question)](#4-configuration-and-secrets-the-env-question)
5. [Flutter upgrade](#5-flutter-upgrade)
6. [Opening BusIn to other schools](#6-opening-busin-to-other-schools)
7. [Splitting the apps](#7-splitting-the-apps)
8. [Turning scans into decisions](#8-turning-scans-into-decisions)
9. [Bus tracking before hardware](#9-bus-tracking-before-hardware)
10. [Recommended features](#10-recommended-features)
11. [Roadmap](#11-roadmap)
12. [Open questions](#12-open-questions)

---

## 1. Verdict

The feature set is real and largely complete for one school, and the code compiles cleanly. The serious problems are almost all in one place: **every authorization decision is made in the app**. Roles are chosen by the user at sign-up, admin actions are plain client writes, and the Firestore rules that should stop abuse are not in the repository, so nobody can review them. Fix that first. Everything else in this report builds on it.

| Status | Summary |
|---|---|
| Works | Sign-in, subscriptions with proof upload, approvals, QR scanning, stops, semesters, people, analytics, EN/FR, dark mode. |
| Must fix | Client-chosen roles, unversioned rules, public payment proofs, copyable static QR, admin data loaded on student phones. |
| Blocks the roadmap | Stops have no coordinates, scans have no bus or trip, nothing knows which school a record belongs to. |

## 2. What works

Confirmed from source, plus `dart analyze lib` on 3.35.6: **0 errors, 5 unused-code warnings**.

- Google sign-in restricted to `@ictuniversity.edu.cm`, with role-aware routing and a pending-verification screen for staff.
- Subscription lifecycle: create with proof upload and stop choice, approve or reject with a reviewer note, embedded semester dates, automatic expiry.
- Scanner checks for an approved subscription inside the semester window and records each scan with GPS.
- Student scan history as a live stream, with screenshot blocking on the QR tab.
- Admin CRUD for stops (with images), semesters, and people (approve staff, promote and demote).
- Analytics dashboard with fl_chart, EN/FR localization through gen-l10n, light and dark themes.
- Secret hygiene in git: `.env`, `android/key.properties` and the upload keystore have never been committed.

## 3. Findings

Severity levels:

- **Critical**: security or privacy.
- **High**: bug, runaway cost, or broken platform.
- **Medium**: correctness or maintainability.
- **Low**: cleanup.

### Critical

#### C1. Users pick their own role at sign-up, and can edit it afterwards

The sign-up sheet calls `setFirstLoginProfile(role, status)`. The controller then writes the user document with whatever role and status the app sent. `AuthController.setRole` and `setStatus` update the signed-in user's own role and status directly. Someone who uses a modified app, or the Firestore REST API with their own ID token, can create `role: "admin", status: "verified"` unless the deployed rules forbid it.

- [lib/ui/screens/onboarding/auth_modal.dart:103](../../apps/legacy/lib/ui/screens/onboarding/auth_modal.dart#L103)
- [lib/controllers/auth_controller.dart:140](../../apps/legacy/lib/controllers/auth_controller.dart#L140)
- [lib/controllers/auth_controller.dart:297](../../apps/legacy/lib/controllers/auth_controller.dart#L297)

**Fix.** Rules only allow creating `student/verified` or `staff/pending`, and never let users change their own `role`, `status` or `schoolId`. Promotions go through a Cloud Function that also sets [custom claims](https://firebase.google.com/docs/auth/admin/custom-claims). The rules then read claims rather than a field the user can write. See the [rules sketch](#rules-sketch-for-c1-and-c2).

#### C2. Firestore rules and indexes are not in the repo, and there is no server code

The README promises "server-side validation" and "Firestore Security Rules", but there is no `firestore.rules`, no `firestore.indexes.json` and no `functions/`. The "SECURITY CHECK" blocks in `SubscriptionService` filter on the phone, so they protect nothing. Approvals, rejections, promotions and suspensions are all direct client writes of whole documents.

- [lib/services/subscription_service.dart:100](../../apps/legacy/lib/services/subscription_service.dart#L100)
- [lib/services/subscription_service.dart:232](../../apps/legacy/lib/services/subscription_service.dart#L232)
- [firebase.json](../../apps/legacy/firebase.json)

**Fix.** Run `firebase init firestore`, pull the currently deployed rules from the console into `firestore.rules`, commit them, and test them with the Emulator Suite. Move state changes (approve, reject, promote, suspend) into callable Cloud Functions so they can be validated and audit-logged.

#### C3. Payment proofs are public files named after the student's email

Proofs go to the Supabase bucket `busin-bucket` at `subscriptions/<email>/…`, and the app stores `getPublicUrl()`. Anyone who gets the link can open a student's payment receipt. Uploads use the anon key with `upsert: true`. If the bucket policy allows anonymous insert or update, anyone holding the (public) anon key can overwrite files.

- [lib/ui/screens/subscriptions/subscription_new.dart:341](../../apps/legacy/lib/ui/screens/subscriptions/subscription_new.dart#L341)
- [lib/utils/supabase_storage.dart:45](../../apps/legacy/lib/utils/supabase_storage.dart#L45)

**Fix.** Move uploads to Cloud Storage for Firebase with rules keyed to `request.auth`: students write only their own folder, and only staff of the same school can read. Use opaque IDs in paths, not emails. This also removes a second vendor and its key from the app. If you keep Supabase, make the bucket private and serve signed URLs from a function.

#### C4. The QR code is the student's permanent user ID

The QR encodes `currentUser.id` (the Firebase UID), and it never changes. Screenshot blocking only stops the owner's own screenshots. A photo taken with a second phone works forever, so one subscription can carry several riders.

- [lib/ui/screens/home/scannings_tab.dart:234](../../apps/legacy/lib/ui/screens/home/scannings_tab.dart#L234)
- [lib/services/scanner_service.dart:52](../../apps/legacy/lib/services/scanner_service.dart#L52)

**Fix.** Use a rotating code: `uid.window.HMAC(secret, uid|window)` with a 30-second window, like a TOTP. A function issues the per-student secret at approval time. The staff app checks the HMAC, which also works offline if it caches the day's secrets. A short-lived photo becomes useless.

### High

#### H1. Admin data loads on every phone at startup, including students and signed-out users

`main()` registers all 11 controllers before sign-in. `AnalyticsController.onInit` immediately downloads analytics, and `UsersController.onInit` starts streaming the users collection. On a student phone, one of two things happens. If the rules allow it, the student downloads everyone's personal data, which is a privacy breach. If they don't, the reads fail silently while still costing time on launch.

- [lib/main.dart:74](../../apps/legacy/lib/main.dart#L74)
- [lib/controllers/analytics_controller.dart:23](../../apps/legacy/lib/controllers/analytics_controller.dart#L23)
- [lib/controllers/users_controller.dart:35](../../apps/legacy/lib/controllers/users_controller.dart#L35)

**Fix.** Register admin controllers lazily, inside admin routes (`Get.lazyPut` or route bindings), and start them only after the role is known. The app split removes the problem entirely.

#### H2. Analytics reads whole collections, several times per dashboard open

Each `fetchAnalytics()` calls `.get()` on all of `subscriptions` three times (stats, top stops, trends), all student users once, and more for semesters. The cost grows with every subscription ever created. With 2,000 subscriptions, one dashboard open costs about 6,000+ document reads, and the free tier allows 50,000 reads a day.

- [lib/services/analytics_service.dart:160](../../apps/legacy/lib/services/analytics_service.dart#L160), [:300](../../apps/legacy/lib/services/analytics_service.dart#L300), [:366](../../apps/legacy/lib/services/analytics_service.dart#L366), [:393](../../apps/legacy/lib/services/analytics_service.dart#L393)

**Fix.** For simple totals, use `count()` and `sum()` aggregation queries. For everything else, a scheduled function writes `stats/daily/{date}` and `stats/semester/{id}` documents, and the dashboard reads a few small documents. The density map needs the same pipeline.

#### H3. Scan history keeps the previous user's stream after sign-out

`ScanningController._isWatchingInitialized` is set once and never reset, and nothing on sign-out clears it. If a staff member signs out and a student signs in on the same phone, the "all scans" stream keeps running, or the new student never gets their own. Shared staff phones make this likely.

- [lib/controllers/scanning_controller.dart:59](../../apps/legacy/lib/controllers/scanning_controller.dart#L59)

**Fix.** On every auth change, cancel the watcher, clear the list and reset the flag. Better still, delete the user-scoped controllers on sign-out (`Get.delete`) so nothing leaks between sessions.

#### H4. Creating a stop fails for names with accents or apostrophes

`_slugify` strips characters and then calls `substring(0, text.length…)` using the length of the *original* text. I ran it:

| Input | Result |
|---|---|
| `Poste Centrale` | `POSTE-CENTRALE` |
| `Carrefour d'Obili` | `RangeError` |
| `Mendong École` | `RangeError` |
| `john.doe` | `RangeError` |

In Yaoundé, most stop names will hit this.

- [lib/utils/id_generator.dart:74](../../apps/legacy/lib/utils/id_generator.dart#L74)
- [lib/services/bus_stop_service.dart:131](../../apps/legacy/lib/services/bus_stop_service.dart#L131)

**Fix.** Truncate the slug, not the original text: `slug.substring(0, min(slug.length, 20))`. Fold accents to ASCII before stripping. Add a unit test with French names.

#### H5. The scanner accepts suspended students and records unlimited duplicate scans

`verifyStudentQRCode` checks the role and an approved subscription, but never the account `status`. The student app blurs the QR for suspended users, but the scanner itself doesn't care. The only duplicate guard is an in-memory "same code as last time" check, so scanning the same student twice on one trip, or on two staff phones, creates two scans. That inflates every ridership number you will later base decisions on.

- [lib/services/scanner_service.dart:92](../../apps/legacy/lib/services/scanner_service.dart#L92)
- [lib/controllers/scanner_controller.dart:21](../../apps/legacy/lib/controllers/scanner_controller.dart#L21)

**Fix.** Reject `suspended` accounts. Make the scan document ID deterministic per student and trip, for example `{tripId}_{studentId}`, so a second scan becomes an idempotent write instead of a new row.

#### H6. Builds fail for anyone without your keystore file

The release signing block casts `keystoreProperties["keyAlias"] as String`. When `key.properties` is missing (a new teammate, CI), the value is null, and Gradle fails while configuring the project. That happens before it even picks debug or release. There is also a dead `signingConfig = …("debug")` line that gets overwritten immediately.

- [android/app/build.gradle.kts:46](../../apps/legacy/android/app/build.gradle.kts#L46)

**Fix.** Create the release config only `if (keystorePropertiesFile.exists())`, and fall back to debug signing otherwise. Read values with `as String?`.

#### H7. iOS Google Sign-In is probably not configured

`firebase_options.dart` has an iOS app, but there is no `GoogleService-Info.plist` in `ios/Runner`, and `Info.plist` has neither `GIDClientID` nor the reversed-client-ID URL scheme. `google_sign_in` needs these on iOS. Without them, sign-in on iPhone will most likely fail.

- [ios/Runner/Info.plist](../../apps/legacy/ios/Runner/Info.plist)

**Fix.** Re-run `flutterfire configure` including iOS, then add the URL scheme. Test on a real iPhone before claiming iOS support.

### Medium

#### M1. Location permission is requested on launch, for every user

`ScanningController.onInit` calls `requestLocationPermission()`, and it is created in `main()`. So students, who never scan, get a location prompt the first time they open the app. That hurts trust and draws Play review questions.

- [lib/controllers/scanning_controller.dart:35](../../apps/legacy/lib/controllers/scanning_controller.dart#L35)

**Fix.** Ask only when staff open the scanner, with a short explanation screen first.

#### M2. Timestamps come from the phone's clock, as strings without a timezone

Scans, subscriptions and users store `DateTime.now().toIso8601String()`, which is local time with no offset, set by the device. A wrong or spoofed clock corrupts history. One place (`updateUserRole`) writes a server `Timestamp` instead, so the formats are mixed. Time-of-day analytics will be unreliable.

- [lib/models/scannings.dart:54](../../apps/legacy/lib/models/scannings.dart#L54)
- [lib/services/users_service.dart:168](../../apps/legacy/lib/services/users_service.dart#L168)

**Fix.** Write `FieldValue.serverTimestamp()` and read `Timestamp`. Keep a parser that accepts the old strings during migration.

#### M3. Lints are switched off, and there are no real tests

`flutter_lints: ^5.0.0` sits inside the `flutter_launcher_icons:` block in `pubspec.yaml`, so it was never installed (it isn't in `pubspec.lock`), and `analysis_options.yaml` includes a package that doesn't exist. The only test is Flutter's counter template, which doesn't match this app and would fail if run.

- [pubspec.yaml:118](../../apps/legacy/pubspec.yaml#L118)
- [test/widget_test.dart](../../apps/legacy/test/widget_test.dart)

**Fix.** Move it under `dev_dependencies`. Start testing where bugs are cheapest to catch: model `fromMap`/`toMap`, semester date logic, ID generation, and Firestore rules in the emulator.

#### M4. Unbounded live streams on growing collections

`streamAllScannings`, `watchAllSubscriptions` and `streamUsersByRole` listen to whole collections with no `limit()`. Scans grow every school day. After one year, opening the staff home re-reads tens of thousands of documents.

- [lib/services/scanning_service.dart:323](../../apps/legacy/lib/services/scanning_service.dart#L323)
- [lib/services/subscription_service.dart:136](../../apps/legacy/lib/services/subscription_service.dart#L136)

**Fix.** Use paginated queries (`limit` + `startAfterDocument`) and keep live listeners only for "today". Filter scans by date range.

#### M5. The data model can't answer the questions you want to ask

`BusStop` has only a `mapEmbedUrl` string, with no latitude or longitude. A `Scanning` has no bus, trip, direction or stop. Its GPS is the staff phone's position at scan time, which equals the pickup point only if scanning happens at boarding. Nothing in the data marks which school a record belongs to. Each of these blocks a pending task. See [section 8](#8-turning-scans-into-decisions).

- [lib/models/value_objects/bus_stop_selection.dart:4](../../apps/legacy/lib/models/value_objects/bus_stop_selection.dart#L4)
- [lib/models/scannings.dart:1](../../apps/legacy/lib/models/scannings.dart#L1)

#### M6. flutter_markdown is discontinued

The package that renders the docs and legal screens is no longer maintained. Swap it for `flutter_markdown_plus`, which has the same API, during the Flutter upgrade.

### Low

- **L1.** `accessToken = gAuth.idToken` passes the ID token twice. It's harmless, but it's a typo ([lib/services/auth_service.dart:65](../../apps/legacy/lib/services/auth_service.dart#L65)).
- **L2.** `AuthService.createUserDocument` and its `STU-`/`ADM-` ID scheme are never used, because the real user docs are keyed by UID. Delete the dead path so nobody wires it in by mistake. Also clear the 5 analyzer warnings (unused `_ActionButton` and unused parameters).
- **L3.** The `try/catch` "fallback without orderBy" in `streamStudentScannings` can never run, because index errors arrive asynchronously on the stream.
- **L4.** `android/build/` files are tracked in git, and the app title is still `'Material App'` ([lib/main.dart:105](../../apps/legacy/lib/main.dart#L105)).
- **L5.** The README has drifted from the code. It lists the domain as `@ictu-university.edu` (the code uses `ictuniversity.edu.cm`), "Flutter 3.9.2", and Supabase vars while `env.example` lists Cloudinary keys. It also claims data retention, account deletion and server validation, none of which exist in the repo.
- **L6.** The globally installed Flutter is 3.38.1 while FVM pins 3.35.6. Whoever runs plain `flutter` builds with a different SDK.

### Rules sketch for C1 and C2

A starting point that closes the role escalation. Roles and school come from custom claims set by a Cloud Function, never from fields the user can write.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function signedIn()  { return request.auth != null; }
    function school()    { return request.auth.token.schoolId; }
    function isStaff()   { return signedIn() && request.auth.token.role in ['staff', 'admin']; }
    function isAdmin()   { return signedIn() && request.auth.token.role == 'admin'; }
    function sameSchool(d) { return d.schoolId == school(); }

    match /users/{uid} {
      allow read: if request.auth.uid == uid || (isStaff() && sameSchool(resource.data));
      allow create: if request.auth.uid == uid && (
        (request.resource.data.role == 'student' && request.resource.data.status == 'verified') ||
        (request.resource.data.role == 'staff'   && request.resource.data.status == 'pending'));
      allow update: if request.auth.uid == uid &&
        !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['role', 'status', 'schoolId']);
      // role/status changes: Cloud Function only (Admin SDK bypasses rules)
    }

    match /subscriptions/{id} {
      allow read:   if resource.data.studentId == request.auth.uid || (isStaff() && sameSchool(resource.data));
      allow create: if request.resource.data.studentId == request.auth.uid
                    && request.resource.data.status == 'pending';
      // approve / reject: Cloud Function only
    }

    match /scannings/{id} {
      allow read:   if resource.data.studentId == request.auth.uid || (isStaff() && sameSchool(resource.data));
      allow create: if isStaff() && request.resource.data.scannedBy == request.auth.uid
                    && sameSchool(request.resource.data);
    }
  }
}
```

---

## 4. Configuration and secrets (the .env question)

**Short answer: the concern is correct.** `.env` is listed under `flutter: assets:` in `pubspec.yaml`, so it ships as a plain file at `assets/flutter_assets/.env` inside the APK. Anyone can unzip it. Switching to `--dart-define` doesn't fix that: the values are compiled into the binary and come out with `strings`. **No method keeps a secret inside a mobile app.**

Nothing shipped today is actually secret:

- **Supabase publishable (anon) key.** It is designed to be public. Bucket policies and Row Level Security protect your data, not the key. That is why C3 matters.
- **Firebase `apiKey` in `firebase_options.dart`.** It is an identifier, not a password. Security comes from rules and App Check. Do restrict it in Google Cloud Console to your Android package and SHA-1 and your iOS bundle ID.

What to do:

1. Remove `.env` from assets and drop `flutter_dotenv`. Put non-secret config in `config/dev.json` and `config/prod.json`, and build with `--dart-define-from-file`. You get per-flavor config with no file inside the APK.
2. Real secrets (a Gemini or Maps server key, a payment provider key, the QR HMAC secret) live only in Cloud Functions, through `defineSecret()` and Secret Manager. The app calls the function, and the function calls the API.
3. Turn on [App Check](https://firebase.google.com/docs/app-check) (Play Integrity on Android, App Attest on iOS) for Firestore, Storage and Functions. Firebase AI Logic will require App Check from 2 November 2026.

```dart
// lib/config.dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const appEnv      = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
```

```bash
fvm flutter build appbundle --release --dart-define-from-file=config/prod.json
```

---

## 5. Flutter upgrade

**Recommendation: upgrade.** The project is pinned to **3.35.6** (October 2025). Current stable is **3.47.x with Dart 3.13**. A year of releases brings:

- **Store compliance.** Google Play raises the required target SDK every year, and newer Flutter templates and plugins track it. Staying a year behind eventually blocks updates.
- **iOS builds.** Since 3.44, Swift Package Manager replaces CocoaPods by default. That is useful when you fix H7.
- **Pub workspaces.** They are mature now and are what the monorepo split relies on.
- **Material moving out of the framework.** `material_ui` and `cupertino_ui` reached 1.0 as packages. Better to adapt while the app is 25k lines than at 60k.

Do it on its own branch, after the security fixes (roadmap stop 1) and before the split:

```bash
fvm install 3.47.7 && fvm use 3.47.7
fvm flutter pub upgrade --major-versions
fvm flutter analyze && fvm flutter test
# then: replace flutter_markdown → flutter_markdown_plus, bump AGP / Kotlin /
# google-services plugin (currently 4.3.15), rebuild Android + iOS,
# smoke-test sign-in and scanning
```

Remove the global 3.38.1 from PATH, or set the IDE to the FVM SDK, so everyone builds with the pinned version.

---

## 6. Opening BusIn to other schools

Three separate things tie the system to ICT University. Each has its own fix.

| What locks it | Where | Change |
|---|---|---|
| Hard-coded email domain | `BaseUser.isAllowedOrgEmail` in `lib/models/actors/base_user.dart` | Look up the school by email domain in a `schools` collection. Enforce it on the server. |
| Google sign-in limited to the university's Workspace (OAuth consent screen set to *Internal*) | Google Cloud Console → Google Auth Platform → Audience | Switch the audience to *External* and publish. You only request `email`, `profile` and `openid`, which don't need Google's sensitive-scope review. Only the branding is verified. |
| The Firebase project sits under the university's Google Cloud organization | Project parent = ictuniversity.edu.cm org | The university's IT admins effectively own the product. Create your own organization (free Cloud Identity on a domain you own) and ask them to [move the project](https://cloud.google.com/resource-manager/docs/project-migration). If they refuse, create a new project and migrate data with an export. |

### Data model: add a tenant key, don't restructure

Keep the existing top-level collections and add a `schoolId` field to every document. That is far less disruptive than moving everything under `schools/{id}/…`.

```
schools/{schoolId}
  name, shortName, allowedDomains: ["ictuniversity.edu.cm"],
  timezone: "Africa/Douala", branding, settings, status

users/{uid}            + schoolId
subscriptions/{id}     + schoolId
scannings/{id}         + schoolId
stops/{id}             + schoolId
semesters/{id}         + schoolId
buses/{id}, trips/{id} + schoolId     (new, see section 8)
```

**Auth.** When a user is created, a Cloud Function reads their email domain, finds the school, and sets custom claims `{schoolId, role}`. Rules compare `request.auth.token.schoolId` with `resource.data.schoolId`. To reject unknown domains *before* the account exists, use a `beforeUserCreated` blocking function. That needs the Identity Platform upgrade, which has a free tier. Full Identity Platform *tenants* are only worth it when a school wants its own SSO (SAML or Azure AD).

### Rollout order that keeps ICTU running

1. **Additive.** Deploy rules that treat a missing `schoolId` as `"ictu"`. Ship an app version that writes `schoolId` on new documents.
2. **Backfill.** A one-off Admin SDK script sets `schoolId: "ictu"` on every existing document and sets claims for existing users.
3. **Force update.** Use Remote Config with `min_supported_build` so old app versions show an update screen.
4. **Enforce.** Remove the "missing = ictu" fallback from the rules. Onboard school #2.

> Cloud Functions require the **Blaze** (pay-as-you-go) plan. Its free quotas cover a campus-sized app. Set a budget alert at a few dollars. Blaze is the precondition for most fixes in this report.

---

## 7. Splitting the apps

There are really **three** audiences with different devices and needs. The staff scanner has to stay on a phone, because it needs the camera and GPS on the bus. That makes it a natural home for the "driver mode" that solves tracking ([section 9](#9-bus-tracking-before-hardware)).

| App | Platform | Contents |
|---|---|---|
| **Student** | Flutter · Android and iOS | Subscribe, pay, rotating QR, scan history, live bus map, ETA, notifications. No admin code. |
| **Ops** | Flutter · Android | QR scanner (works offline), driver mode (start/end trip, live GPS), today's trip manifest. |
| **Admin portal** | Web, separate app | Approvals, people, stops, semesters, density heatmaps, route suggestions, exports, audit log, school settings. |

### Proposed repository layout

```
busin/
├─ apps/
│  ├─ student/          Flutter (Android, iOS)
│  ├─ ops/              Flutter (Android): scanner + driver mode
│  └─ admin_web/        web portal
├─ packages/
│  ├─ busin_core/       models, enums, Firestore converters, validation (pure Dart)
│  └─ busin_ui/         theme, shared widgets, l10n ARB files
├─ firebase/
│  ├─ firestore.rules · firestore.indexes.json · storage.rules
│  └─ functions/        TypeScript: claims, approvals, aggregates, QR secrets, AI
├─ docs/
├─ firebase.json
└─ pubspec.yaml         workspace: [apps/student, apps/ops, packages/*]
```

### Admin portal stack

| Option | Strengths | Costs |
|---|---|---|
| **Next.js (React) + Firebase JS SDK** (recommended) | Large sortable tables, heatmaps (MapLibre or deck.gl), CSV export, fast first load, shareable URLs. Releases independently of the mobile apps. | Models written a second time in TypeScript. Keep that small by putting business logic in Cloud Functions. |
| **Flutter Web** | Reuses `busin_core` and `busin_ui` directly. One language for a solo developer. | Weaker on data-dense UIs and map layers. Heavier first load. |

### Migration path, no big bang

1. Extract `busin_core` inside the current app, with no behaviour change.
2. Build the portal against the same Firestore and move admin screens over one at a time.
3. Once the portal has full parity, cut the admin screens from the mobile app and rename it `student`. Build `ops` from the scanner screens.

---

## 8. Turning scans into decisions

To suggest pickup points and routes, the data first has to record *where*, *when* and *on which bus*. Today it doesn't. These additions come before any analysis or AI:

| Add | Why |
|---|---|
| `stops.location: GeoPoint` + `geohash` | Every map, distance and cluster needs it. Backfill by parsing coordinates from the existing `mapEmbedUrl`. New stops get a map pin picker. |
| `buses` (plate, capacity) and `trips` (bus, driver, direction, start/end, route) | Gives you ridership per trip, capacity alerts and the tracking key. |
| On each scan: `tripId`, `busId`, `direction`, `nearestStopId`, `accuracyM`, server time | Turns a GPS dot into "boarded at Obili, 07:12, Bus 2, inbound". |
| Subscribed stop vs. actual boarding stop | Shows the gap between what students declared and what they actually do. |

> **Important:** scan GPS is the *staff phone's* position. It is a pickup location only if staff scan as students board. If scanning happens at the campus gate, every point lands on campus, and you need the student's selected stop or an in-bus scan instead.

### 8.1 Student density by location (pending task)

- A scheduled function, run nightly, groups the day's scans by `nearestStopId` and by geohash-7 cell (~150 m), split into 30-minute slots. It writes `stats/density/{date}`.
- Portal views: a heatmap of boardings, a per-stop bar chart by hour of the week, and "declared vs. actual" per stop.
- This is cheap: one small document per day, read by the portal instead of raw scans.

### 8.2 Pickup point suggestions

Cluster the boarding coordinates from the last N weeks (DBSCAN, eps ≈ 300 m). Flag clusters whose centre is more than ~400 m from any stop and that have enough weekly boardings, and propose them as new stops. Also flag stops with almost no boardings for removal or merging. It is plain statistics: explainable, and checkable on a map.

### 8.3 Optimized routes (pending task)

This is a **vehicle routing problem** (demand per stop, bus capacity, fleet size, arrive on campus by 07:30). Solvers handle it well. Language models don't: an LLM will produce plausible but unchecked routes. Use:

- [Google OR-Tools](https://developers.google.com/optimization/routing) (free, open source) in a Python Cloud Run job, with travel times from OSRM on OpenStreetMap (free) or the Google Routes API (paid).
- Or the managed [Route Optimization API](https://developers.google.com/maps/documentation/route-optimization) if you'd rather pay than run a solver.

### 8.4 Where Gemini (Firebase AI Logic) actually helps

Use the model to *explain and query* the numbers, not to compute them:

- Weekly digest for admins: "Boardings at Carrefour Obili up 23%. Bus 2 full on 4 of 5 mornings. Consider a second pass at 07:05."
- Natural-language questions over the precomputed stats: "Which stops were busiest during exams?"
- Plain-language explanations of the solver's route and pickup suggestions.

Two cautions. On the free Gemini Developer API tier, Google may use prompts to improve its products, so send **only aggregated, anonymized stats**, never names, emails or individual GPS traces. And call it from a Cloud Function (Genkit works well here) rather than from the client, so prompts and data stay under your control.

---

## 9. Bus tracking before hardware

Build the tracking pipeline once, around a single record type, and let the source change underneath it:

```
live/{schoolId}/{busId}      // Realtime Database: cheap for frequent overwrites
  lat, lng, speed, heading, accuracyM, tripId,
  source: "scan" | "phone" | "device",
  recordedAt

trips/{tripId}/track/{auto}  // Firestore: thinned breadcrumbs (1 per ~30 s) for history + ETA
```

Realtime Database fits the live position: it bills by bandwidth and storage, not per write, while Firestore charges every write. Updating every 10 seconds on Firestore adds up quickly.

| Tier | When | Approach |
|---|---|---|
| **0 · Last seen from scans** | Now, free | Every scan already has GPS and a time. Once scans carry `busId`, show "Bus 2 last seen at Obili, 4 min ago". It's coarse, but it needs nothing new. |
| **1 · A phone that lives on the bus** (recommended) | With the ops app | Driver mode: "Start trip" begins an Android foreground-service location stream (supported by `geolocator`, with a persistent notification) every 10–15 s, and "End trip" stops it. For consistent results, use a **cheap dedicated Android phone mounted on a car charger**, not the driver's personal phone. Exempt it from battery optimization and keep it signed in to a "bus" account. |
| **2 · Staff phone fallback** | Optional | If the staff member who scans rides the bus, their scanner phone can publish position during a trip as a backup source. |
| **3 · Partner hardware tracker** | Later | The device posts to an HTTPS Cloud Function with a per-device token. The function writes to the same `live/{schoolId}/{busId}` path with `source: "device"`. The student app and portal don't change at all. |

**ETA:** start with "average travel time between consecutive stops for this time slot", learned from the breadcrumbs. It beats any map API on your own routes within a few weeks of data.

---

## 10. Recommended features

| Feature | Why it matters here |
|---|---|
| **Mobile Money payment** (MTN MoMo, Orange Money via an aggregator such as Campay, Notch Pay or Flutterwave) | Replaces uploading screenshots of receipts. Approval becomes automatic when the payment webhook confirms. This removes most of the admin review queue and the C3 privacy problem. |
| **Push notifications** (FCM) | Subscription approved or rejected, expiring in 3 days, bus 5 minutes from your stop, trip cancelled. |
| **Offline scanning** | Campus routes have patchy data coverage. The ops app caches today's valid subscribers and HMAC secrets, verifies locally, and syncs scans later. |
| **Trip manifest and capacity** | "Bus 2: 41/45 boarded." Alerts when buses run full, which is evidence for adding a trip. |
| **Audit log** | Functions record who approved, rejected, promoted or suspended whom, and when. The README already promises it. |
| **Account deletion flow** | Google Play requires in-app and web account deletion for apps that create accounts. The README claims it, but it doesn't exist yet. |
| **Data retention** | A scheduled job deletes raw scan GPS after one or two semesters and keeps only the aggregates. |
| **Crashlytics + Performance Monitoring** | Right now you learn about crashes from students. |
| **Dev / staging / prod flavors** | Separate Firebase projects, so testing never touches real student data. |
| **CI** (GitHub Actions) | Analyze, test and build on each PR. Run rules tests in the emulator. |
| **Feedback and incidents** | Students report a late or skipped bus with one tap. Combined with tracking, admins see reliability per route. |

---

## 11. Roadmap

The order matters: each stop depends on the ones before it. Durations assume one developer, part-time.

### Stop 1 · Lock it down (~2 weeks)

- [ ] Move to Blaze with a budget alert.
- [ ] Commit `firestore.rules` and `firestore.indexes.json`, and test them in the emulator.
- [ ] Roles via Cloud Function and custom claims (C1, C2).
- [ ] Private storage for payment proofs (C3).
- [ ] Fix H1, H3, H4, H5, H6.
- [ ] Remove `.env` from assets. Turn on App Check.

### Stop 2 · Foundations (~1–2 weeks)

- [ ] Upgrade Flutter to 3.47.x. Turn lints on (M3).
- [ ] Model and rules tests, CI, flavors.
- [ ] Server timestamps (M2), pagination (M4), aggregation queries for the dashboard (H2).
- [ ] Fix iOS sign-in (H7), or drop iOS from the README until it works.

### Stop 3 · Data model for decisions (~3 weeks)

- [ ] `schoolId` everywhere, plus a `schools` collection. Backfill ICTU.
- [ ] Stop coordinates, `buses`, `trips`, enriched scans.
- [ ] Rotating QR (C4).
- [ ] Nightly aggregates, then the **density map** (pending task).

### Stop 4 · Split the apps (~4–6 weeks)

- [ ] Pub workspace, extract `busin_core`.
- [ ] Admin web portal.
- [ ] Ops app with offline scanner and **driver mode** (tracking tier 1).
- [ ] Slim student app with live bus map.

### Stop 5 · Insights (ongoing)

- [ ] Pickup point suggestions.
- [ ] Route optimization with OR-Tools.
- [ ] Gemini weekly digest on aggregates.
- [ ] Push notifications, capacity alerts, feedback.

### Stop 6 · More schools (when ready)

- [ ] OAuth consent screen set to External. Project under your own organization.
- [ ] School onboarding in the portal.
- [ ] Mobile Money payments.
- [ ] Partner hardware trackers posting to the same live path.

---

## 12. Open questions

1. **Where does scanning happen?** At each stop as students board, inside the bus, or at the campus gate? This decides whether scan GPS can drive the density map.
2. **What rules are deployed right now?** Copy them from the Firebase console into the repo. Several findings go from "possible" to "confirmed" or "already mitigated" depending on them.
3. **How many buses, and are routes fixed?** One loop each morning, or several trips per day? This shapes the `trips` model and the route solver's inputs.
4. **Who controls the university's Google Cloud org?** Will they move the project, or does BusIn start fresh in a project you own?
5. **Is the Blaze plan acceptable?** Nearly every server-side fix depends on Cloud Functions.
6. **Admin portal stack.** Next.js, or Flutter Web to stay single-language?

---

### Sources

- [Flutter releases](https://flutterreleases.com/flutter-versions/)
- [Flutter 3.44 release notes summary](https://www.cmarix.com/blog/latest-flutter-version/)
- [Firebase AI Logic pricing](https://firebase.google.com/docs/ai-logic/pricing)
- [Firebase custom claims](https://firebase.google.com/docs/auth/admin/custom-claims)
- [Firebase App Check](https://firebase.google.com/docs/app-check)
- [Google Cloud project migration](https://cloud.google.com/resource-manager/docs/project-migration)
- [OR-Tools vehicle routing](https://developers.google.com/optimization/routing)
