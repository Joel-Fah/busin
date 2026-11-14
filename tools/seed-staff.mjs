// Gives one staff account a realistic schedule in the LOCAL database (supabase/seed-staff.sql): two weeks of trips with
// boardings, two trips today and a few ahead, all on the demo bus DEMO-107.
// Local development only: it runs SQL inside the local database container. Needs the demo data (npm run seed:demo).
//   npm run seed:staff -- <staff email>
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sql = readFileSync(path.join(root, 'supabase/seed-staff.sql'), 'utf8');
const email = (process.argv[2] ?? '').trim().toLowerCase();

if (!/^[^@\s'"\\]+@[^@\s'"\\]+$/.test(email)) {
  console.error('Usage: npm run seed:staff -- <staff email>');
  process.exit(1);
}

function psql(args, input) {
  return execFileSync(
    'docker',
    ['exec', '-i', 'supabase_db_busin', 'psql', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-q', ...args],
    { encoding: 'utf8', input, stdio: ['pipe', 'pipe', 'pipe'] },
  );
}

try {
  // One transaction, so a failure leaves the database as it was. The email goes in as a psql variable, quoted by psql.
  psql(['-1', '-v', `staff_email=${email}`, '-f', '-'], sql);
  const [past, cancelled, today, ahead, boardings] = psql([
    '-t', '-A', '-F', ' ', '-v', `staff_email=${email}`, '-f', '-',
  ], `select
       count(*) filter (where t.status = 'completed'),
       count(*) filter (where t.status = 'cancelled'),
       count(*) filter (where t.status = 'scheduled' and (t.scheduled_start at time zone 'Africa/Douala')::date = (now() at time zone 'Africa/Douala')::date),
       count(*) filter (where t.status = 'scheduled' and (t.scheduled_start at time zone 'Africa/Douala')::date > (now() at time zone 'Africa/Douala')::date),
       (select count(*) from public.scans sc join public.trips x on x.id = sc.trip_id join public.profiles q on q.id in (x.driver_id, x.assistant_id)
          where x.bus_id = 'de200000-0000-4000-8000-000000000007' and lower(q.email) = lower(:'staff_email'))
     from public.trips t join public.profiles p on p.id in (t.driver_id, t.assistant_id)
     where t.bus_id = 'de200000-0000-4000-8000-000000000007' and lower(p.email) = lower(:'staff_email');`).trim().split(' ');
  console.log(`
Staff schedule ready on bus DEMO-107: ${past} finished trips with ${boardings} boardings, ${cancelled} cancelled,
${today} today (one as driver in about 20 minutes, one as assistant later), ${ahead} in the days ahead.
Run it again any time: it replaces these trips and moves them to the current dates.`);
} catch (error) {
  console.error(error.stderr || error.message);
  process.exit(1);
}
