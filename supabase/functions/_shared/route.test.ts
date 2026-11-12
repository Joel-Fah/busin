import assert from "node:assert/strict";
import { test } from "node:test";

import { chunk, directionsUrl, drawRoad, joinRoad, RoutingError, type DirectionsAnswer, type Waypoint } from "./route.ts";

const wp = (seq: number, kind: Waypoint["kind"] = "stop"): Waypoint => ({ seq, kind, id: kind === "stop" ? `s${seq}` : null, name: `P${seq}`, lat: 3.8 + seq / 100, lng: 11.5 });

/** A Directions answer for a chunk: a straight road through its points, 1000 m and 100 s per leg. */
function answer(points: Waypoint[]): DirectionsAnswer {
  return {
    code: "Ok",
    routes: [
      {
        distance: 1000 * (points.length - 1),
        duration: 100 * (points.length - 1),
        geometry: { type: "LineString", coordinates: points.map((p) => [p.lng, p.lat] as [number, number]) },
        legs: points.slice(1).map(() => ({ distance: 1000, duration: 100 })),
      },
    ],
  };
}

test("long routes are split into requests of 25 waypoints that meet end to start", () => {
  const points = Array.from({ length: 60 }, (_, i) => i);
  const parts = chunk(points);
  assert.equal(parts.length, 3);
  assert.deepEqual(parts.map((p) => p.length), [25, 25, 12]);
  assert.equal(parts[1][0], parts[0][24]);
  assert.equal(parts[2][0], parts[1][24]);
  assert.deepEqual(chunk([1]), []);
  assert.deepEqual(chunk([1, 2]), [[1, 2]]);
});

test("the request asks for driving, the full road as GeoJSON, no steps, longitude first", () => {
  const url = new URL(directionsUrl([wp(0), wp(1)], "tok"));
  assert.equal(url.pathname, "/directions/v5/mapbox/driving/11.5,3.8;11.5,3.81");
  assert.equal(url.searchParams.get("geometries"), "geojson");
  assert.equal(url.searchParams.get("overview"), "full");
  assert.equal(url.searchParams.get("steps"), "false");
  assert.equal(url.searchParams.get("access_token"), "tok");
});

test("chunks join into one road with one named leg per pair of waypoints, and no repeated point", () => {
  const points = [...Array.from({ length: 30 }, (_, i) => wp(i)), wp(30, "campus")];
  const parts = chunk(points);
  const road = joinRoad(points, parts.map(answer));
  assert.equal(road.legs.length, 30);
  assert.equal(road.distance_m, 30000);
  assert.equal(road.duration_s, 3000);
  assert.equal(road.geometry.coordinates.length, 31);
  assert.deepEqual(road.legs[0], { from: "P0", to: "P1", from_stop: "s0", to_stop: "s1", distance_m: 1000, duration_s: 100 });
  assert.equal(road.legs[29].to_stop, null, "the last leg ends at the campus");
});

test("a road that cannot be found, a bad token or a busy service are told apart", async () => {
  assert.throws(() => joinRoad([wp(0), wp(1)], [{ code: "NoRoute" }]), (e: unknown) => e instanceof RoutingError && e.code === "no_road");
  const fake = (status: number, body: unknown = {}) => async () => ({ ok: status < 300, status, json: async () => body });
  await assert.rejects(drawRoad([wp(0), wp(1)], "t", fake(401)), (e: unknown) => e instanceof RoutingError && e.code === "bad_token");
  await assert.rejects(drawRoad([wp(0), wp(1)], "t", fake(429)), (e: unknown) => e instanceof RoutingError && e.code === "busy");
  await assert.rejects(drawRoad([wp(0)], "t", fake(200)), (e: unknown) => e instanceof RoutingError && e.code === "too_few_points");
});

test("drawRoad asks once per chunk and returns the joined road", async () => {
  const points = Array.from({ length: 26 }, (_, i) => wp(i));
  const asked: string[] = [];
  const road = await drawRoad(points, "t", async (url) => {
    asked.push(url);
    const parts = chunk(points);
    return { ok: true, status: 200, json: async () => answer(parts[asked.length - 1]) };
  });
  assert.equal(asked.length, 2);
  assert.equal(road.legs.length, 25);
});
