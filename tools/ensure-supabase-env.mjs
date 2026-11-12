// Makes sure supabase/.env exists so the local backend can start before Google keys are added.
// The placeholders are not secrets; Google sign-in simply fails at Google until real values are set.
import { existsSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const target = resolve('supabase/.env');
if (existsSync(target)) process.exit(0);

writeFileSync(
  target,
  [
    '# Local development only. Replace the placeholders with your Google OAuth client values.',
    '# See docs/guides/google-sign-in.md. This file is git-ignored; never commit it.',
    'SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID=not-configured',
    'SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET=not-configured',
    '',
  ].join('\n'),
);
console.log('Created supabase/.env with placeholders. Add your Google keys later (docs/guides/google-sign-in.md).');
