// Moves the bus of a running trip along the school's stops, so the student app's "My bus" tab has something to follow.
// Local development only (it talks to the local database container).
//
//   npm run dev:bus                  # the bus of the most recently started running trip
//   npm run dev:bus -- DEMO-101      # a bus by plate (it need not be on a trip; the app lists running trips only)
//   npm run dev:bus -- --every 2     # seconds between positions (default 3)
//
// Stop it with Ctrl+C. The last position stays in the database.
import { execFileSync } from "node:child_process";

const args = process.argv.slice(2);
const everyIndex = args.indexOf("--every");
const everySeconds = everyIndex >= 0 ? Number(args[everyIndex + 1]) : 3;
const plate = args.find((a, i) => !a.startsWith("--") && i !== everyIndex + 1) ?? null;
if (!Number.isFinite(everySeconds) || everySeconds < 1 || everySeconds > 60) {
  console.error("--every takes a number of seconds from 1 to 60.");
  process.exit(1);
}

const psql = (sql) =>
  execFileSync("docker", ["exec", "-i", "supabase_db_busin", "psql", "-U", "postgres", "-v", "ON_ERROR_STOP=1", "-tA", "-F", "|", "-c", sql], { encoding: "utf8" }).trim();

// Plates are letters, digits, dashes and spaces; refuse anything else before it reaches SQL.
if (plate !== null && !/^[A-Za-z0-9 -]{1,20}$/.test(plate)) {
  console.error("That does not look like a plate.");
  process.exit(1);
}

const bus = psql(
  plate
    ? `select b.id, b.school_id, b.plate from public.buses b where b.plate = '${plate}' limit 1`
    : `select b.id, b.school_id, b.plate from public.trips t join public.buses b on b.id = t.bus_id where t.status = 'active' order by t.started_at desc nulls last limit 1`,
);
if (!bus) {
  console.error(plate ? `No bus has the plate ${plate}.` : "No trip is running. Start one in the ops app (or set a trip's status to active in the database) and run this again.");
  process.exit(1);
}
const [busId, schoolId, busPlate] = bus.split("|");

const stops = psql(
  `select extensions.st_y(location::extensions.geometry), extensions.st_x(location::extensions.geometry) from public.stops where school_id = '${schoolId}' and active order by name`,
)
  .split("\n")
  .filter(Boolean)
  .map((row) => row.split("|").map(Number));
if (stops.length < 2) {
  console.error("The school needs at least two active stops to drive between.");
  process.exit(1);
}

// A closed loop through the stops, cut into small steps.
const STEPS = 12;
const path = [];
for (let i = 0; i < stops.length; i++) {
  const [aLat, aLng] = stops[i];
  const [bLat, bLng] = stops[(i + 1) % stops.length];
  for (let s = 0; s < STEPS; s++) path.push([aLat + ((bLat - aLat) * s) / STEPS, aLng + ((bLng - aLng) * s) / STEPS]);
}

const R = 6371000;
const rad = (d) => (d * Math.PI) / 180;
const metres = ([lat1, lng1], [lat2, lng2]) => {
  const a = Math.sin(rad(lat2 - lat1) / 2) ** 2 + Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(rad(lng2 - lng1) / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
};
const bearing = ([lat1, lng1], [lat2, lng2]) => {
  const y = Math.sin(rad(lng2 - lng1)) * Math.cos(rad(lat2));
  const x = Math.cos(rad(lat1)) * Math.sin(rad(lat2)) - Math.sin(rad(lat1)) * Math.cos(rad(lat2)) * Math.cos(rad(lng2 - lng1));
  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
};

console.log(`Driving ${busPlate} through ${stops.length} stops, a position every ${everySeconds} s. Ctrl+C to stop.`);
let i = 0;
const tick = () => {
  const here = path[i % path.length];
  const next = path[(i + 1) % path.length];
  const speed = metres(here, next) / everySeconds;
  psql(`
    insert into public.live_positions (bus_id, school_id, location, speed_mps, heading_deg, source, recorded_at)
    values ('${busId}', '${schoolId}', extensions.st_point(${here[1]}, ${here[0]})::extensions.geography, ${speed.toFixed(2)}, ${bearing(here, next).toFixed(0)}, 'device', now())
    on conflict (bus_id) do update set location = excluded.location, speed_mps = excluded.speed_mps,
      heading_deg = excluded.heading_deg, source = excluded.source, recorded_at = excluded.recorded_at;`);
  i++;
};
tick();
const timer = setInterval(tick, everySeconds * 1000);
process.on("SIGINT", () => {
  clearInterval(timer);
  console.log("\nStopped.");
  process.exit(0);
});
