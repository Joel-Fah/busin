// Imports the named places around a school's stops from OpenStreetMap, for My area's place search (ADR 0013).
//
//   npm run places:import -- <school id>          against the local backend
//   npm run places:import -- <school id> --dry    only count what would be imported
//
// Against a hosted project, set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in the environment first (the key is a
// secret: never commit it or paste it into a file in the repository). Running it there changes hosted data, so it is
// the owner's call.
//
// It asks the public Overpass service once (fair use: run it when a school starts or its stops move, not on a
// schedule), then replaces the school's places in one call. The data is (c) OpenStreetMap contributors, under the ODbL.
import { execFileSync } from "node:child_process";
import { setDefaultResultOrder } from "node:dns";
import { setDefaultAutoSelectFamilyAttemptTimeout } from "node:net";

import { overpassQuery, placesFrom } from "./places-osm.mjs";

// Slow or IPv4-only networks: try IPv4 first and give each address time to answer (Node's default is 250 ms).
setDefaultResultOrder("ipv4first");
setDefaultAutoSelectFamilyAttemptTimeout(15_000);

// Public Overpass servers, tried in order (each is a shared free service and is sometimes overloaded).
const OVERPASS = process.env.OVERPASS_URL
  ? [process.env.OVERPASS_URL]
  : ["https://overpass-api.de/api/interpreter", "https://overpass.private.coffee/api/interpreter", "https://maps.mail.ru/osm/tools/overpass/api/interpreter"];
const [schoolId, ...rest] = process.argv.slice(2);
const dry = rest.includes("--dry");

if (!/^[0-9a-f-]{36}$/i.test(schoolId ?? "")) {
  console.error("Usage: npm run places:import -- <school id> [--dry]");
  process.exit(1);
}

function backend() {
  if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return { url: process.env.SUPABASE_URL, key: process.env.SUPABASE_SERVICE_ROLE_KEY, local: false };
  }
  const env = Object.fromEntries(
    execFileSync("npx", ["supabase", "status", "-o", "env"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] })
      .split("\n")
      .map((line) => line.match(/^([A-Z_]+)="?(.*?)"?$/))
      .filter(Boolean)
      .map((m) => [m[1], m[2]]),
  );
  if (!env.API_URL || !env.SERVICE_ROLE_KEY) throw new Error("The local backend is not running (npm run backend:start).");
  return { url: env.API_URL, key: env.SERVICE_ROLE_KEY, local: true };
}

async function rpc(target, name, body) {
  const response = await fetch(`${target.url}/rest/v1/rpc/${name}`, {
    method: "POST",
    headers: { apikey: target.key, authorization: `Bearer ${target.key}`, "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!response.ok) throw new Error(`${name} failed: ${response.status} ${(await response.text()).slice(0, 200)}`);
  return response.json();
}

const target = backend();
console.log(`Backend: ${target.local ? "local" : target.url}`);

const [box] = await rpc(target, "place_import_box", { p_school_id: schoolId });
if (!box) {
  console.error("This school has no stops yet, so there is no area to import. Add its stops first.");
  process.exit(1);
}

console.log("Asking OpenStreetMap (Overpass) for the named places around the school's stops...");
let body = null;
for (const server of OVERPASS) {
  try {
    const response = await fetch(server, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded", "user-agent": "busin-places-import/1.0" },
      body: new URLSearchParams({ data: overpassQuery(box) }),
      signal: AbortSignal.timeout(180_000),
    });
    if (response.ok) {
      body = await response.json();
      break;
    }
    console.log(`${new URL(server).host} answered ${response.status}; trying the next server.`);
  } catch (error) {
    console.log(`${new URL(server).host} could not be reached (${error.cause?.code ?? error.name}); trying the next server.`);
  }
}
if (!body) {
  console.error("No Overpass server answered. They are shared free services: wait a few minutes and try again.");
  process.exit(1);
}
const places = placesFrom(body);
const byKind = places.reduce((counts, place) => ({ ...counts, [place.kind]: (counts[place.kind] ?? 0) + 1 }), {});
console.log(`Found ${places.length} places: ${Object.entries(byKind).map(([kind, n]) => `${n} ${kind}`).join(", ")}.`);

if (dry) {
  console.log("Dry run: nothing was changed.");
} else {
  const imported = await rpc(target, "import_places", { p_school_id: schoolId, p_places: places });
  console.log(`Imported ${imported} places for this school (the previous ones were replaced).`);
}
