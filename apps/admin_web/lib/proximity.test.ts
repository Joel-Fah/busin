import { describe, expect, it } from "vitest";

import { buildProximity, lineSize, reachOf, roughDistance, type ProximityRow } from "./proximity";

const stops = [
  { id: "a", name: "Alpha", position: { lat: 3.85, lng: 11.5 } },
  { id: "b", name: "Beta", position: { lat: 3.86, lng: 11.51 } },
  { id: "c", name: "Gamma", position: null },
];

const row = (stop_id: string, with_area: number, median_m: number | null, bands: (number | null)[] = [null, null, null, null]): ProximityRow => ({
  stop_id,
  subscribers: with_area + 2,
  with_area,
  median_m,
  under_500: bands[0],
  to_1k: bands[1],
  to_2k: bands[2],
  over_2k: bands[3],
});

describe("reachOf", () => {
  it("puts a distance in its band", () => {
    expect(reachOf(120)).toBe("near");
    expect(reachOf(500)).toBe("walk");
    expect(reachOf(1999)).toBe("far");
    expect(reachOf(2000)).toBe("remote");
  });
});

describe("buildProximity", () => {
  it("shows figures only from 5 students with an area, farthest first, and adds up the coverage", () => {
    const result = buildProximity(
      stops,
      [row("a", 6, 400, [4, 1, 1, 0]), row("b", 8, 1500, [1, 2, 3, 2]), row("c", 3, null)],
      [{ lat: 3.87, lng: 11.5, stop_id: "b", students: 6, distance_m: 1500 }],
    );
    expect(result.stops.map((s) => [s.id, s.reach])).toEqual([
      ["b", "far"],
      ["a", "near"],
      ["c", null],
    ]);
    expect(result.stops[0].overOneKm).toBe(5 / 8);
    expect(result.stops[2]).toMatchObject({ median: null, bands: null, overOneKm: null });
    expect(result.subscribers).toBe(8 + 10 + 5);
    expect(result.withArea).toBe(17);
    expect(result.lines).toEqual([{ id: "b:3.87:11.5", from: { lat: 3.87, lng: 11.5 }, to: { lat: 3.86, lng: 11.51 }, students: 6, distance: 1500 }]);
  });

  it("never shows a figure the database sent for too few students", () => {
    const result = buildProximity(stops, [row("a", 4, 300, [4, 0, 0, 0])], []);
    expect(result.stops[0]).toMatchObject({ median: null, bands: null });
  });

  it("drops lines to a stop without a position and rows of unknown stops", () => {
    const result = buildProximity(stops, [row("zzz", 9, 100, [9, 0, 0, 0])], [{ lat: 3.8, lng: 11.4, stop_id: "c", students: 5, distance_m: 900 }]);
    expect(result.stops).toEqual([]);
    expect(result.lines).toEqual([]);
  });
});

describe("students nearer another stop", () => {
  it("lists, per stop, the stops its students live nearer to, and draws a line between them", () => {
    const result = buildProximity(stops, [row("a", 6, 400, [4, 1, 1, 0])], [], [
      { from_stop: "a", to_stop: "b", students: 6, saved_m: 1400 },
      { from_stop: "a", to_stop: "c", students: 9, saved_m: 600 },
      { from_stop: "zzz", to_stop: "b", students: 7, saved_m: 900 },
    ]);
    expect(result.stops[0].nearer).toEqual([
      { toId: "c", toName: "Gamma", students: 9, saved: 600 },
      { toId: "b", toName: "Beta", students: 6, saved: 1400 },
    ]);
    // Gamma has no position, and zzz is unknown: only one line.
    expect(result.nearerLines).toEqual([{ id: "a>b", from: { lat: 3.85, lng: 11.5 }, to: { lat: 3.86, lng: 11.51 }, students: 6 }]);
  });
});

describe("formatting", () => {
  it("rounds distances like a person would say them", () => {
    expect(roughDistance(12)).toEqual({ value: "50", unit: "m" });
    expect(roughDistance(423)).toEqual({ value: "400", unit: "m" });
    expect(roughDistance(980)).toEqual({ value: "1", unit: "km" });
    expect(roughDistance(1361)).toEqual({ value: "1.4", unit: "km" });
  });

  it("sizes lines from 5 to 25 students", () => {
    expect(lineSize(5)).toBe(0);
    expect(lineSize(15)).toBe(0.5);
    expect(lineSize(40)).toBe(1);
  });
});
