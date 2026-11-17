// Erases one account now in the LOCAL backend, the way the nightly job does on the hosted project (ADR 0028), so the
// whole deletion can be tried without waiting 7 days. The account must have asked for its deletion first (from an app,
// or the platform console). It moves the due date to now, then runs the same steps as the delete-accounts function.
// Local development only.
//   npm run dev:erase -- <email>
import { execFileSync, execSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { createClient } from '@supabase/supabase-js';

import { eraseDue } from '../supabase/functions/_shared/erase.ts';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const email = (process.argv[2] ?? '').trim().toLowerCase();
if (!/^[^@\s'"\\]+@[^@\s'"\\]+$/.test(email)) {
  console.error('Usage: npm run dev:erase -- <email>');
  process.exit(1);
}

function psql(sql) {
  return execFileSync(
    'docker',
    ['exec', '-i', 'supabase_db_busin', 'psql', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-q', '-t', '-A', '-v', `email=${email}`, '-f', '-'],
    { encoding: 'utf8', input: sql, stdio: ['pipe', 'pipe', 'pipe'] },
  ).trim();
}

try {
  // The email goes in as a psql variable, quoted by psql.
  const id = psql(`update public.profiles set deletion_due_at = now() - interval '1 second'
    where lower(email) = lower(:'email') and deletion_due_at is not null and deleted_at is null returning id;`);
  if (!id) {
    console.error('That account has no deletion scheduled. Ask for it from an app (Profile, Delete my account) first.');
    process.exit(1);
  }

  const status = execSync('npx supabase status -o env', { cwd: root, encoding: 'utf8' });
  const read = (name) => status.match(new RegExp(`^${name}="?([^"\\r\\n]+)"?`, 'm'))?.[1];
  const supabase = createClient(read('API_URL'), read('SERVICE_ROLE_KEY'), { auth: { persistSession: false } });

  const { data, error } = await supabase.rpc('due_account_deletions');
  if (error) throw new Error(error.message);
  const due = (data ?? []).filter((row) => row.user_id === id);
  if (due.length === 0) {
    console.error('The deletion is waiting: the account is the last administrator of its school, or on a running trip.');
    process.exit(1);
  }
  const outcome = await eraseDue(due, {
    async removeFiles(paths) {
      const { error } = await supabase.storage.from('proofs').remove(paths);
      if (error) throw new Error(error.message);
    },
    async deleteSignIn(userId) {
      const { error } = await supabase.auth.admin.deleteUser(userId, true);
      if (error) throw new Error(error.message);
    },
    async eraseProfile(userId) {
      const { error } = await supabase.rpc('erase_account', { p_user_id: userId });
      if (error) throw new Error(error.message);
    },
  });
  if (outcome.failed.length > 0) {
    console.error(`Not erased: ${outcome.failed[0].step} failed (${outcome.failed[0].error}). Run it again.`);
    process.exit(1);
  }
  console.log(`Erased: ${due[0].files?.length ?? 0} proof files removed, the sign-in account deleted, the profile emptied.
The school keeps its records under "Deleted account". The same Google account can sign up again as new.`);
} catch (error) {
  console.error(error.stderr || error.message);
  process.exit(1);
}
