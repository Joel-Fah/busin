// Builds a release of the student or ops app against production: an app bundle (.aab) for the Play Store by default,
// or an APK for Firebase App Distribution. Says which key signs it: the upload key from android/key.properties, or the
// debug key when that file is missing (fine for testers, refused by the Play Store). docs/guides/release-signing.md
//   npm run build:release -- student            the student app bundle
//   npm run build:release -- ops apk            the ops APK
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const [app, kind = 'appbundle'] = process.argv.slice(2);
if (!['student', 'ops'].includes(app) || !['appbundle', 'apk'].includes(kind)) {
  console.error('Usage: npm run build:release -- <student|ops> [appbundle|apk]');
  process.exit(1);
}
const appDir = path.join(root, 'apps', app);
const signed = existsSync(path.join(appDir, 'android', 'key.properties'));
if (!signed) {
  console.warn(`No apps/${app}/android/key.properties: this build is signed with the debug key.`);
  if (kind === 'appbundle') console.warn('The Play Store refuses it. See docs/guides/release-signing.md.');
}
if (!existsSync(path.join(root, 'config', 'prod.json'))) {
  console.error('config/prod.json is missing (the production values, kept out of git).');
  process.exit(1);
}

const run = spawnSync('fvm', ['flutter', 'build', kind, '--release', '--dart-define-from-file=../../config/prod.json'], {
  cwd: appDir,
  stdio: 'inherit',
});
if (run.status !== 0) process.exit(run.status ?? 1);
const output = kind === 'apk' ? 'build/app/outputs/flutter-apk/app-release.apk' : 'build/app/outputs/bundle/release/app-release.aab';
console.log(`\nBuilt apps/${app}/${output}, signed with the ${signed ? 'upload' : 'debug'} key.`);
