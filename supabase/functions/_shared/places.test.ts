import assert from "node:assert/strict";
import { test } from "node:test";

import { cleanQuery, mapboxUrl, parsePlaces } from "./places.ts";

test("the search text is trimmed and bounded", () => {
  assert.equal(cleanQuery("  Bastos   carrefour "), "Bastos carrefour");
  assert.equal(cleanQuery("a"), null);
  assert.equal(cleanQuery("x".repeat(81)), null);
  assert.equal(cleanQuery(42), null);
});

test("the request is biased to the school and carries nothing about the student", () => {
  const url = new URL(
    mapboxUrl("Bastos", { centre_lng: 11.5, centre_lat: 3.85, min_lng: 11.2, min_lat: 3.5, max_lng: 11.8, max_lat: 4.1 }, "fr", "pk.test"),
  );
  assert.equal(url.origin + url.pathname, "https://api.mapbox.com/search/geocode/v6/forward");
  assert.equal(url.searchParams.get("q"), "Bastos");
  assert.equal(url.searchParams.get("proximity"), "11.5,3.85");
  assert.equal(url.searchParams.get("bbox"), "11.2,3.5,11.8,4.1");
  assert.equal(url.searchParams.get("language"), "fr");
  assert.deepEqual([...url.searchParams.keys()].sort(), ["access_token", "autocomplete", "bbox", "language", "limit", "proximity", "q", "types"]);
});

test("a school without stops searches without a bias", () => {
  const empty = { centre_lng: null, centre_lat: null, min_lng: null, min_lat: null, max_lng: null, max_lat: null };
  const url = new URL(mapboxUrl("Bastos", empty, "de", "pk.test"));
  assert.equal(url.searchParams.get("proximity"), null);
  assert.equal(url.searchParams.get("bbox"), null);
  assert.equal(url.searchParams.get("language"), "en");
});

test("only the name, the place and the point are passed on", () => {
  const places = parsePlaces({
    features: [
      { properties: { name: "Bastos", place_formatted: "Yaounde, Centre, Cameroon", coordinates: { latitude: 3.89, longitude: 11.51 }, mapbox_id: "x" } },
      { properties: { name: "No point" } },
      { properties: { name: 5, coordinates: { latitude: 1, longitude: 1 } } },
    ],
  });
  assert.deepEqual(places, [{ label: "Bastos", detail: "Yaounde, Centre, Cameroon", lat: 3.89, lng: 11.51 }]);
  assert.deepEqual(parsePlaces(null), []);
  assert.deepEqual(parsePlaces({ features: "no" }), []);
});
