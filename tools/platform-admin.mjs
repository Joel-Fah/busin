// Lists or unlists an account as a platform admin (ADR 0027) in the LOCAL database, as the owner does with SQL on the
// hosted project. Local development only: it runs SQL inside the local database container.
//   npm run platform:admin -- <email>            list the account (it must have signed in once)
//   npm run platform:admin -- <email> --remove   unlist it
import { execFileSync } from 'node:child_process';

const email = (process.argv[2] ?? '').trim().toLowerCase();
const remove = process.argv.includes('--remove');

if (!/^[^@\s'"\\]+@[^@\s'"\\]+$/.test(email)) {
  console.error('Usage: npm run platform:admin -- <email> [--remove]');
  process.exit(1);
}

const statement = remove
  ? `delete from private.platform_admins a using auth.users u where u.id = a.user_id and lower(u.email) = lower(:'email') returning 1;`
  : `insert into private.platform_admins (user_id, note)
     select u.id, 'local, npm run platform:admin' from auth.users u where lower(u.email) = lower(:'email')
     on conflict (user_id) do update set note = excluded.note
     returning 1;`;

try {
  // The email goes in as a psql variable, quoted by psql.
  const out = execFileSync(
    'docker',
    ['exec', '-i', 'supabase_db_busin', 'psql', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-q', '-t', '-A', '-v', `email=${email}`, '-f', '-'],
    { encoding: 'utf8', input: statement, stdio: ['pipe', 'pipe', 'pipe'] },
  ).trim();
  if (!out) {
    console.error(remove ? 'That account was not a platform admin.' : 'No account with that email. Sign in once with it first.');
    process.exit(1);
  }
  console.log(remove ? 'Removed: that account no longer opens /platform.' : 'Done: that account now opens /platform.');
} catch (error) {
  console.error(error.stderr || error.message);
  process.exit(1);
}
