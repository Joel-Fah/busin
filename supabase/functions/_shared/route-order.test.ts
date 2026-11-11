import assert from "node:assert/strict";
import { test } from "node:test";

import { bestPath, EXACT_LIMIT, haversine, matrixUrl, pathCost, suggestedOrder, type Costs } from "./route-order.ts";

/** Points on a line, 1 km apart going north; the cost is the distance between them. */
const line = (n: number) => Array.from({ length: n }, (_, i) => ({ lat: 3.8 + (i * 1000) / 111195, lng: 11.5 }));
const distances = (points: { lat: number; lng: number }[]): Costs => points.map((a) => points.map((b) => haversine(a, b)));

test("the Matrix request asks for driving times and distances between all points", () => {
  const url = new URL(matrixUrl([{ lat: 3.8, lng: 11.5 }, { lat: 3.9, lng: 11.6 }], "tok"));
  assert.equal(url.pathname, "/directions-matrix/v1/mapbox/driving/11.5,3.8;11.6,3.9");
  assert.equal(url.searchParams.get("annotations"), "duration,distance");
  assert.equal(url.searchParams.get("access_token"), "tok");
});

test("the exact order visits every stop once and ends at the campus", () => {
  const points = line(6);
  // Shuffled: the campus is the last point on the line, given as index 2.
  const shuffled = [points[0], points[3], points[5], points[1], points[4], points[2]];
  const path = bestPath(distances(shuffled), [0], 2);
  assert.deepEqual(path, [0, 3, 5, 1, 4, 2]);
});

test("the local search beyond the exact limit still finds the straight run", () => {
  const points = line(EXACT_LIMIT + 4);
  const order = points.map((_, i) => i).sort((a, b) => ((a * 7) % 17) - ((b * 7) % 17));
  const shuffled = order.map((i) => points[i]);
  const end = order.indexOf(points.length - 1);
  const start = order.indexOf(0);
  const path = bestPath(distances(shuffled), [start], end)!;
  assert.equal(path.length, points.length);
  assert.deepEqual(path.map((i) => order[i]), points.map((_, i) => i));
});

test("unreachable stops give no order", () => {
  const costs: Costs = [
    [0, null, 5],
    [null, 0, null],
    [5, null, 0],
  ];
  assert.equal(bestPath(costs, [0], 2), null);
});

test("today's first stop is kept unless a nearby one is clearly quicker", () => {
  // Today's first stop (0) sits 1 km south of stop 1; the campus is far north. Starting at 1 means doubling back.
  const points = line(5);
  const costs = distances(points);
  assert.deepEqual(suggestedOrder(points, costs, 0, 4), [0, 1, 2, 3, 4]);

  // A suggested stop (index 4) 1 km south of today's start, within the radius: from today's start the bus would go
  // south and come back, so starting at the new stop saves 2 km and it becomes the first stop.
  const south = [...points.slice(0, 4), { lat: 3.8 - 1000 / 111195, lng: 11.5 }, points[4]];
  const withSouth = distances(south);
  const order = suggestedOrder(south, withSouth, 0, 5)!;
  assert.equal(order[0], 4, "the stop further out starts the run, since visiting it later means doubling back");
  assert.ok(pathCost(withSouth, order) < pathCost(withSouth, [0, 4, 1, 2, 3, 5]));
});

test("a start beyond the radius is never chosen", () => {
  const points = line(4);
  // A stop 5 km south of today's start: starting there would be best, but it is too far from today's start.
  const far = [...points.slice(0, 3), { lat: 3.8 - 5000 / 111195, lng: 11.5 }, points[3]];
  const order = suggestedOrder(far, distances(far), 0, 4)!;
  assert.equal(order[0], 0);
  assert.equal(order.length, 5);
});
