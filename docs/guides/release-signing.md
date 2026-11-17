# Release signing and app bundles

The Play Store only takes an app bundle (`.aab`) signed with your **upload key**. Google then signs what phones install
with its own app signing key (Play App Signing), so losing the upload key can be fixed; losing it is still a bother.
Firebase App Distribution takes an APK signed with any key.

## Make the upload key (owner, once per app)
On your machine, outside the repository:
```bash
mkdir -p ~/busin-keys && cd ~/busin-keys
keytool -genkeypair -v -keystore busin-student-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
keytool -genkeypair -v -keystore busin-ops-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```
Keep the `.jks` files and their passwords in your password manager and a backup. Never put them in git (`.gitignore`
already refuses `*.jks`, `*.keystore` and `key.properties`).

## Point each app at its key
Create `apps/student/android/key.properties` (and the same in `apps/ops/android/` with the ops key):
```
storeFile=/home/<you>/busin-keys/busin-student-upload.jks
storePassword=<the store password>
keyAlias=upload
keyPassword=<the key password>
```
With the file, release builds use the upload key; without it they fall back to the debug key, so builds never fail.
Check which key a build uses: `cd apps/student/android && ./gradlew -q :app:signingReport` (Variant: release, Config:
upload).

## Build
```bash
npm run build:release -- student        # apps/student/build/app/outputs/bundle/release/app-release.aab
npm run build:release -- ops apk        # an APK for App Distribution
```
Bump `version:` in the app's `pubspec.yaml` first: each upload needs a higher build number (the part after `+`).

## First upload to Play
Create the app in the Play Console, choose **Play App Signing** (Google manages the app signing key), and upload the
first bundle: the key that signed it becomes the app's upload key. Testers who installed builds signed with another key
(the debug key) uninstall those first.
