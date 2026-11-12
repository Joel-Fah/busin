// Fills the LOCAL database with demo data (supabase/seed-demo.sql) and prints sign-in details.
// Local development only: it runs SQL inside the local database container. Usage: npm run seed:demo
import { execFileSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sql = readFileSync(path.join(root, 'supabase/seed-demo.sql'), 'utf8');
const password = randomBytes(12).toString('hex');

function psql(args, input) {
  return execFileSync(
    'docker',
    ['exec', '-i', 'supabase_db_busin', 'psql', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-q', ...args],
    { encoding: 'utf8', input, stdio: ['pipe', 'pipe', 'pipe'] },
  );
}

try {
  const school = psql(['-t', '-A', '-c', "select count(*) from public.schools where id = '00000000-0000-4000-8000-000000000001'"]).trim();
  if (school !== '1') {
    console.error('The seed school is missing. Run npm run backend:reset once (it loads supabase/seed.sql), then try again.');
    process.exit(1);
  }
  // One transaction, so a failure leaves the database as it was.
  psql(['-1', '-v', `demo_password=${password}`, '-f', '-'], sql);
  const counts = psql([
    '-t', '-A', '-F', ' ',
    '-c',
    `select
       (select count(*) from public.profiles where email like 'demo.%'),
       (select count(*) from public.stops where school_id = '00000000-0000-4000-8000-000000000001'),
       (select count(*) from public.buses where id::text like 'de%'),
       (select count(*) from public.trips where bus_id::text like 'de%'),
       (select count(*) from public.subscriptions s join public.profiles p on p.id = s.student_id where p.email like 'demo.%'),
       (select count(*) from public.scans sc join public.profiles p on p.id = sc.student_id where p.email like 'demo.%')`,
  ]).trim().split(' ');
  const [people, stops, buses, trips, subscriptions, scans] = counts;
  console.log(`
Demo data ready: ${people} people, ${stops} stops, ${buses} buses, ${trips} trips, ${subscriptions} subscriptions, ${scans} boardings.

Sign in at http://127.0.0.1:3000/dev/login (development only). The password is new every run:

  administrator  demo.admin@ictuniversity.edu.cm
  driver         demo.driver1@ictuniversity.edu.cm
  student        demo.student01@ictuniversity.edu.cm
  password       ${password}

Run it again any time: it replaces the demo rows and moves the trips to today's dates.`);
} catch (error) {
  const detail = String(error.stderr ?? error.message);
  console.error(detail.includes('No such container') ? 'The local backend is not running. Start it with: npm run backend:start' : detail.trim());
  process.exit(1);
}
