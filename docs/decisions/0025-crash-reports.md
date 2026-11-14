# 0025: Crash reports

Status: accepted, 2026-11-14 (the owner asked for Crashlytics before the next release to `main`).

## Context
Crashes on students' and staff phones never reached us: the only signal was a student saying the app closed. The apps
run on modest Android phones, often offline, where the scanner and the boarding code matter most. [ADR 0001](0001-backend-supabase.md)
keeps Firebase for push notifications and optionally Crashlytics; the codebase audit listed crash reporting as a gap.

## Decision
1. **Firebase Crashlytics in the student and ops apps** (`firebase_crashlytics`, in `busin_app`), on the Firebase
   project the apps already use for push. No new vendor and no cost.
2. **Release builds only.** Collection is off in the Android manifest and turned on by the app only in a release build
   with Firebase configured. Debug runs and tests never send anything.
3. **No personal data.** A report carries the app (`student` or `ops`), the role (`student`, `staff`, `admin`) and what
   Crashlytics adds itself (app version, phone model, system version). Never a user id, name, email, code, position or
   token. Error texts are passed through a redaction step (emails, ids, tokens, boarding codes, long numbers and
   coordinates replaced) before they leave the phone, and the original error is not sent.
4. **Only real failures.** What the app expects is not reported: no connection, a server refusal, a conflict (the
   repository errors other than `Unexpected`, socket and time-out errors).
5. **Switching it on.** A release build made with `--dart-define=BUSIN_CRASH_TEST=true` sends one non-fatal test report
   at start-up; the first report turns the project's Crashlytics dashboard on. Normal builds never send it.
6. **The privacy policy says so** (student and staff texts, in the apps and on the web).

## Consequences
- The web apps are not covered (Crashlytics is mobile only). Browser errors would need another service such as Sentry,
  a new vendor and a separate decision.
- The Crashlytics Gradle plugin (which uploads Android's mapping file so Java and Kotlin lines read clearly) is left out
  for now: Dart code, nearly all of these apps, reads clearly without it, and the plugin's support for the Android Gradle
  Plugin these apps use (9.1) is to be checked first. If Dart code is ever obfuscated, its symbols must be uploaded with
  each release (`firebase crashlytics:symbols:upload`).
- An iPhone build of the student app needs the dSYM upload step when it ships.
- Performance Monitoring is not added: it collects more and is not needed yet.
