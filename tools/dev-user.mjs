// Creates (or resets) a local account for the development-only sign-in page.
// Local development only: it runs SQL inside the local database container and prints a fresh
// random password each time. Usage: npm run dev:user [-- email [role]]
import { execFileSync } from 'node:child_process';
import { randomBytes, randomUUID } from 'node:crypto';

const email = (process.argv[2] ?? 'dev-admin@ictuniversity.edu.cm').toLowerCase();
const role = process.argv[3] ?? 'admin';

if (!/^[a-z0-9._+-]+@[a-z0-9.-]+\.[a-z]{2,}$/.test(email)) {
  console.error('That does not look like an email address.');
  process.exit(1);
}
if (!['student', 'staff', 'admin'].includes(role)) {
  console.error('The role must be student, staff or admin.');
  process.exit(1);
}

const id = randomUUID();
const password = randomBytes(12).toString('hex');
// Every interpolated value above is generated here or validated against a strict pattern.
const sql = `
do $$
declare v_id uuid;
begin
  select id into v_id from auth.users where email = '${email}';
  if v_id is null then
    v_id := '${id}';
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
      '${email}', extensions.crypt('${password}', extensions.gen_salt('bf')), now(),
      '{"provider":"google","providers":["google"]}',
      '{"full_name":"Local ${role}"}', now(), now(), '', '', '', ''
    );
    insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
    values (gen_random_uuid(), v_id, v_id::text, 'google',
      jsonb_build_object('sub', v_id::text, 'email', '${email}'), now(), now(), now());
  else
    update auth.users
    set encrypted_password = extensions.crypt('${password}', extensions.gen_salt('bf')),
        email_confirmed_at = coalesce(email_confirmed_at, now())
    where id = v_id;
  end if;
  update public.profiles set role = '${role}', status = 'verified' where id = v_id;
end
$$;
`;

try {
  execFileSync(
    'docker',
    ['exec', '-i', 'supabase_db_busin', 'psql', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-q', '-c', sql],
    { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] },
  );
} catch (error) {
  const detail = String(error.stderr ?? error.message);
  if (detail.includes('not enabled for BusIn')) {
    console.error('That email domain is not allowed by any school. Use the seeded domain ictuniversity.edu.cm.');
  } else if (detail.includes('No such container')) {
    console.error('The local backend is not running. Start it with: npm run backend:start');
  } else {
    console.error(detail.trim());
  }
  process.exit(1);
}

console.log(`
Local ${role} ready. Sign in at http://127.0.0.1:3000/dev/login (development only)

  email:    ${email}
  password: ${password}

The password is new every time you run this. It works only on this machine.`);
