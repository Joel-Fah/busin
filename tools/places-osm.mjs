// The OpenStreetMap side of the places import (tools/import-places.mjs), kept free of network calls so it can be
// tested (node --test tools/places-osm.test.mjs). ADR 0013: the data is (c) OpenStreetMap contributors, ODbL.

/** The Overpass query for every named place a student could live near, inside the box. */
export function overpassQuery({ south, west, north, east }) {
  const box = [south, west, north, east].map((value) => Number(value).toFixed(5)).join(",");
  return `[out:json][timeout:120];
(
  nwr["place"~"^(suburb|neighbourhood|quarter|city_block|village|hamlet|locality|isolated_dwelling)$"]["name"](${box});
  relation["boundary"="administrative"]["admin_level"~"^(9|10)$"]["name"](${box});
  way["highway"~"^(primary|secondary|tertiary|unclassified|residential|living_street|trunk)$"]["name"](${box});
  nwr["amenity"~"^(school|college|university|hospital|clinic|marketplace|place_of_worship|bus_station)$"]["name"](${box});
);
out center tags;`;
}

/** The same key the database compares names with (private.place_key), to merge pieces of one street. */
export function placeKey(name) {
  return String(name ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[\s'’-]+/g, " ")
    .trim();
}

function kindOf(tags) {
  const place = tags.place ?? "";
  if (["suburb", "neighbourhood", "quarter", "city_block"].includes(place)) return "area";
  if (tags.boundary === "administrative") return "area";
  if (["village", "hamlet", "locality", "isolated_dwelling"].includes(place)) return "village";
  if (tags.highway) return "street";
  if (tags.amenity) return "landmark";
  return null;
}

/** Distance in metres between two points, near enough for merging street pieces. */
function metres(a, b) {
  const rad = Math.PI / 180;
  const x = (b.lng - a.lng) * rad * Math.cos(((a.lat + b.lat) / 2) * rad);
  const y = (b.lat - a.lat) * rad;
  return Math.sqrt(x * x + y * y) * 6371000;
}

/**
 * The places to import from an Overpass answer: one row per named place with its kind and a point. A street mapped as
 * many pieces becomes one row per stretch (pieces with the same name within 1.5 km merge). Names in French are
 * preferred when the map has them.
 */
export function placesFrom(body) {
  const elements = Array.isArray(body?.elements) ? body.elements : [];
  const rows = [];
  const streets = new Map();
  for (const element of elements) {
    const tags = element.tags ?? {};
    const name = String(tags["name:fr"] ?? tags.name ?? "").trim().slice(0, 120);
    const kind = kindOf(tags);
    const lat = element.lat ?? element.center?.lat;
    const lng = element.lon ?? element.center?.lon;
    if (!name || !kind || !Number.isFinite(lat) || !Number.isFinite(lng)) continue;
    const row = { osm_id: `${element.type[0]}${element.id}`, name, kind, lat, lng };
    if (kind !== "street") {
      rows.push(row);
      continue;
    }
    const key = placeKey(name);
    const stretches = streets.get(key) ?? [];
    if (!stretches.some((kept) => metres(kept, row) < 1500)) stretches.push(row);
    streets.set(key, stretches);
  }
  for (const stretches of streets.values()) rows.push(...stretches);
  // One row per OSM object.
  const seen = new Set();
  return rows.filter((row) => (seen.has(row.osm_id) ? false : (seen.add(row.osm_id), true)));
}
