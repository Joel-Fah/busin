import { describe, expect, it } from "vitest";

import type { BusUpdate } from "./bus";
import {
  Glide,
  KEPT_UPDATES,
  TRAIL_MAX_POINTS,
  addTrailPoint,
  insideView,
  keepUpdate,
  lerpPoint,
  lineData,
  lineFromGeoJson,
  mergeTrail,
  pointData,
  pulseAt,
  pulseData,
  routeFromRow,
  stopsData,
} from "./bus-map";

const A = { lat: 3.85, lng: 11.5 };
const B = { lat: 3.86, lng: 11.5 };

describe("the layers' data", () => {
  it("marks the student's own stop and names each stop", () => {
    const data = stopsData(
      [
        { id: "a", name: "Poste", position: A },
        { id: "b", name: "Mvan", position: B },
      ],
      "b",
    );
    expect(data.features.map((f) => f.properties)).toEqual([
      { name: "Poste", mine: false },
      { name: "Mvan", mine: true },
    ]);
    expect(data.features[0].geometry.coordinates).toEqual([11.5, 3.85]);
  });

  it("draws a point only when there is one, and a line only through two points or more", () => {
    expect(pointData(null).features).toHaveLength(0);
    expect(pointData(A, { name: "Campus" }).features[0].properties).toEqual({ name: "Campus" });
    expect(lineData([A]).features).toHaveLength(0);
    expect(lineData([A, B]).features[0].geometry).toEqual({ type: "LineString", coordinates: [[11.5, 3.85], [11.5, 3.86]] });
  });

  it("pings the student's stop and the bus", () => {
    expect(pulseData(B, A).features.map((f) => f.properties.kind)).toEqual(["stop", "bus"]);
    expect(pulseData(null, null).features).toHaveLength(0);
  });
});

describe("the glide", () => {
  it("goes straight between two points, settling at the end", () => {
    expect(lerpPoint(A, B, 0.5).lat).toBeCloseTo(3.855);
    expect(lerpPoint(A, B, 2)).toEqual(B);
    const glide = Glide.at(A, 0).towards(B, 0, 5000);
    expect(glide.durationMs).toBe(4500);
    expect(glide.movingAt(1000)).toBe(true);
    const half = glide.positionAt(2250).lat;
    expect(half).toBeGreaterThan(3.855); // eased: past the middle at half time
    expect(glide.positionAt(4500)).toEqual(B);
    expect(glide.movingAt(4500)).toBe(false);
  });

  it("keeps a glide between its shortest and longest", () => {
    expect(Glide.at(A, 0).towards(B, 0, 100).durationMs).toBe(Glide.SHORTEST_MS);
    expect(Glide.at(A, 0).towards(B, 0, 20_000).durationMs).toBe(Glide.LONGEST_MS);
  });

  it("jumps after a long silence, a far jump, or when motion is reduced", () => {
    expect(Glide.at(A, 0).towards(B, 0, 31_000).durationMs).toBe(0);
    expect(Glide.at(A, 0).towards({ lat: 3.9, lng: 11.5 }, 0, 5000).durationMs).toBe(0);
    expect(Glide.at(A, 0).towards(B, 0, 5000, true).durationMs).toBe(0);
  });

  it("starts the next glide from where the marker is drawn", () => {
    const first = Glide.at(A, 0).towards(B, 0, 4000);
    const next = first.towards({ lat: 3.87, lng: 11.5 }, 1800, 1800);
    expect(next.from).toEqual(first.positionAt(1800));
  });
});

describe("the ping", () => {
  it("grows from the marker and fades", () => {
    expect(pulseAt(0, 9, 14, 0.35)).toEqual({ radius: 9, opacity: 0.35 });
    const late = pulseAt(0.9, 9, 14, 0.35);
    expect(late.radius).toBeGreaterThan(22);
    expect(late.opacity).toBeCloseTo(0.035);
    expect(pulseAt(1.25, 9, 14)).toEqual(pulseAt(0.25, 9, 14));
  });
});

describe("the route and the trail", () => {
  it("reads a LineString and a MultiLineString, and nothing else", () => {
    expect(lineFromGeoJson({ type: "LineString", coordinates: [[11.5, 3.85], [11.5, 3.86]] })).toEqual([A, B]);
    expect(lineFromGeoJson({ type: "MultiLineString", coordinates: [[[11.5, 3.85]], [[11.5, 3.86]]] })).toEqual([A, B]);
    expect(lineFromGeoJson({ type: "Point", coordinates: [11.5, 3.85] })).toEqual([]);
    expect(lineFromGeoJson({ type: "LineString", coordinates: [[11.5, 95]] })).toEqual([]);
    expect(lineFromGeoJson(null)).toEqual([]);
  });

  it("reads the school's route with its campus, or nothing when neither is set", () => {
    expect(routeFromRow({ geometry: { type: "LineString", coordinates: [[11.5, 3.85], [11.5, 3.86]] }, campus_lat: 3.9, campus_lng: 11.6, campus_name: "Main" })).toEqual({
      line: [A, B],
      campus: { lat: 3.9, lng: 11.6 },
      campusName: "Main",
    });
    expect(routeFromRow({ geometry: null, campus_lat: 3.9, campus_lng: 11.6, campus_name: null })?.line).toEqual([]);
    expect(routeFromRow({ geometry: null, campus_lat: null, campus_lng: null })).toBeNull();
    expect(routeFromRow(null)).toBeNull();
  });

  it("adds a point only once the bus has moved, and keeps the newest", () => {
    const one = addTrailPoint([], A);
    expect(addTrailPoint(one, { lat: 3.85005, lng: 11.5 })).toBe(one);
    expect(addTrailPoint(one, B)).toEqual([A, B]);
    let long = Array.from({ length: TRAIL_MAX_POINTS }, (_, i) => ({ lat: 3 + i * 0.001, lng: 11.5 }));
    long = addTrailPoint(long, { lat: 4, lng: 11.5 });
    expect(long).toHaveLength(TRAIL_MAX_POINTS);
    expect(long[long.length - 1]).toEqual({ lat: 4, lng: 11.5 });
    expect(mergeTrail([A], [B])).toEqual([A, B]);
    expect(mergeTrail([], [B])).toEqual([B]);
  });
});

describe("the updates", () => {
  it("keeps the newest first, up to a trip's worth", () => {
    let list: BusUpdate[] = [];
    for (let i = 0; i < KEPT_UPDATES + 5; i++) list = keepUpdate(list, { kind: "moving", at: i, seq: i });
    expect(list).toHaveLength(KEPT_UPDATES);
    expect(list[0].seq).toBe(KEPT_UPDATES + 4);
  });
});

describe("the bus in view", () => {
  it("is inside the map, clear of the edges and above what covers its bottom", () => {
    const size = { width: 400, height: 600 };
    expect(insideView({ x: 200, y: 300 }, size, 0)).toBe(true);
    expect(insideView({ x: 10, y: 300 }, size, 0)).toBe(false);
    expect(insideView({ x: 200, y: 500 }, size, 200)).toBe(false);
  });
});
