// Moves the bus of a running trip along the school's road route (or its stops), so the student app's "My bus" tab has something to follow.
// Local development only (it talks to the local database container).
//
//   npm run dev:bus                  # the bus of the most recently started running trip
//   npm run dev:bus -- DEMO-101      # a bus by plate (it need not be on a trip; the app lists running trips only)
//   npm run dev:bus -- --every 2     # seconds between positions (default 3)
//   npm run dev:bus -- --speed 50    # km/h along the road route (default 35)
//
// Stop it with Ctrl+C. The last position stays in the database.
import { execFileSync } from "node:child_process";

const args = process.argv.slice(2);
const everyIndex = args.indexOf("--every");
const everySeconds = everyIndex >= 0 ? Number(args[everyIndex + 1]) : 3;
const speedIndex = args.indexOf("--speed");
const speedKmh = speedIndex >= 0 ? Number(args[speedIndex + 1]) : 35;
const plate = args.find((a, i) => !a.startsWith("--") && i !== everyIndex + 1 && i !== speedIndex + 1) ?? null;
if (!Number.isFinite(everySeconds) || everySeconds < 1 || everySeconds > 60) {
  console.error("--every takes a number of seconds from 1 to 60.");
  process.exit(1);
}
if (!Number.isFinite(speedKmh) || speedKmh < 5 || speedKmh > 120) {
  console.error("--speed takes km/h from 5 to 120.");
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

// The school's route along roads when it has been drawn (Stops, Route in the portal): driven there and back at a town
// speed. Without it, a closed loop through the stops in straight lines.
const road = psql(
  `select extensions.st_asgeojson(r.geometry::extensions.geometry) from public.routes r where r.school_id = '${schoolId}' and r.geometry is not null order by r.created_at limit 1`,
);
const path = [];
if (road) {
  const line = JSON.parse(road).coordinates.map(([lng, lat]) => [lat, lng]);
  const step = (speedKmh / 3.6) * everySeconds;
  // Points every `step` metres along the line.
  let carried = 0;
  path.push(line[0]);
  for (let k = 1; k < line.length; k++) {
    const a = line[k - 1];
    const b = line[k];
    const length = metres(a, b);
    let at = step - carried;
    while (at <= length) {
      const f = at / length;
      path.push([a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f]);
      at += step;
    }
    carried = (carried + length) % step;
  }
  path.push(...path.slice(1, -1).reverse());
} else {
  const STEPS = 12;
  for (let i = 0; i < stops.length; i++) {
    const [aLat, aLng] = stops[i];
    const [bLat, bLng] = stops[(i + 1) % stops.length];
    for (let s = 0; s < STEPS; s++) path.push([aLat + ((bLat - aLat) * s) / STEPS, aLng + ((bLng - aLng) * s) / STEPS]);
  }
}
// The running trip of this bus, if any: its thinned history (about every 30 s) feeds the trail on the student's map.
const tripId = psql(`select id from public.trips where bus_id = '${busId}' and status = 'active' order by started_at desc nulls last limit 1`);

console.log(
  road
    ? `Driving ${busPlate} along the school's road route at ${speedKmh} km/h, a position every ${everySeconds} s. Ctrl+C to stop.`
    : `Driving ${busPlate} through ${stops.length} stops (no road route drawn), a position every ${everySeconds} s. Ctrl+C to stop.`,
);
let i = 0;
const tick = () => {
  const here = path[i % path.length];
  const next = path[(i + 1) % path.length];
  const speed = metres(here, next) / everySeconds;
  psql(`
    insert into public.live_positions (bus_id, school_id, trip_id, location, speed_mps, heading_deg, source, recorded_at)
    values ('${busId}', '${schoolId}', ${tripId ? `'${tripId}'` : "null"}, extensions.st_point(${here[1]}, ${here[0]})::extensions.geography, ${speed.toFixed(2)}, ${bearing(here, next).toFixed(0)}, 'device', now())
    on conflict (bus_id) do update set trip_id = excluded.trip_id, location = excluded.location, speed_mps = excluded.speed_mps,
      heading_deg = excluded.heading_deg, source = excluded.source, recorded_at = excluded.recorded_at;`);
  if (tripId && i % Math.max(1, Math.round(30 / everySeconds)) === 0) {
    psql(`insert into public.trip_positions (trip_id, school_id, location, speed_mps)
      values ('${tripId}', '${schoolId}', extensions.st_point(${here[1]}, ${here[0]})::extensions.geography, ${speed.toFixed(2)});`);
  }
  i++;
};
tick();
const timer = setInterval(tick, everySeconds * 1000);
process.on("SIGINT", () => {
  clearInterval(timer);
  console.log("\nStopped.");
  process.exit(0);
});
