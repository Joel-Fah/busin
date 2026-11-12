import assert from "node:assert/strict";
import { test } from "node:test";

import { overpassQuery, placeKey, placesFrom } from "./places-osm.mjs";

test("the query covers the box and only named places", () => {
  const query = overpassQuery({ south: 3.5, west: 11.2, north: 4.2, east: 11.8 });
  assert.match(query, /\(3\.50000,11\.20000,4\.20000,11\.80000\)/);
  assert.match(query, /out center tags;/);
  for (const line of query.split("\n").filter((l) => l.includes("(3.5"))) assert.match(line, /\["name"\]/);
});

test("keys match the database's: no case, accents, hyphens or apostrophes", () => {
  assert.equal(placeKey("  Éssos - Mvog’Ada "), "essos mvog ada");
});

test("places get a kind and a point, French names first, nameless ones dropped", () => {
  const rows = placesFrom({
    elements: [
      { type: "relation", id: 1, center: { lat: 3.894, lon: 11.511 }, tags: { boundary: "administrative", admin_level: "10", name: "Bastos" } },
      { type: "node", id: 2, lat: 3.835, lon: 11.473, tags: { place: "neighbourhood", name: "Mendong", "name:fr": "Mendong" } },
      { type: "node", id: 3, lat: 3.785, lon: 11.627, tags: { place: "village", name: "Mendong" } },
      { type: "way", id: 4, center: { lat: 3.86, lon: 11.505 }, tags: { amenity: "school", name: "Lycee de Ngoa-Ekelle" } },
      { type: "node", id: 5, lat: 3.8, lon: 11.4, tags: { place: "suburb" } },
      { type: "node", id: 6, lat: 3.8, lon: 11.4, tags: { natural: "peak", name: "Mont Febe" } },
    ],
  });
  assert.deepEqual(
    rows.map((r) => [r.osm_id, r.name, r.kind]),
    [
      ["r1", "Bastos", "area"],
      ["n2", "Mendong", "area"],
      ["n3", "Mendong", "village"],
      ["w4", "Lycee de Ngoa-Ekelle", "landmark"],
    ],
  );
});

test("pieces of one street merge, but the same name far away stays separate", () => {
  const piece = (id, lat, lon, name = "Rue 1750") => ({ type: "way", id, center: { lat, lon }, tags: { highway: "residential", name } });
  const rows = placesFrom({ elements: [piece(10, 3.86, 11.5), piece(11, 3.861, 11.501), piece(12, 3.86, 11.6, "rue  1750")] });
  assert.deepEqual(rows.map((r) => r.osm_id), ["w10", "w12"]);
});
