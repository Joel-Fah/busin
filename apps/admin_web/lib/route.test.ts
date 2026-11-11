import { describe, expect, it } from "vitest";

import { compareRoutes, directions, formatKm, formatMinutes, insertExtras, move, parseSchoolRoute, routeLine, routeOverlay, type SchoolRouteRow } from "./route";

const row = (over: Partial<SchoolRouteRow> = {}): SchoolRouteRow => ({
  route_id: "r1",
  stops: [
    { id: "a", name: "First", lat: 3.8, lng: 11.5, active: true },
    { id: "b", name: "Second", lat: 3.82, lng: 11.5, active: true },
  ],
  campus_name: "Main campus",
  campus_lat: 3.86,
  campus_lng: 11.5,
  geometry: null,
  distance_m: null,
  duration_s: null,
  legs: null,
  computed_at: null,
  current: false,
  ...over,
});

describe("parseSchoolRoute", () => {
  it("reads stops in order and the campus, with no road until one is drawn", () => {
    const route = parseSchoolRoute(row());
    expect(route.stops.map((s) => s.name)).toEqual(["First", "Second"]);
    expect(route.campus).toEqual({ name: "Main campus", position: { lat: 3.86, lng: 11.5 } });
    expect(route.road).toBeNull();
    expect(route.current).toBe(false);
  });

  it("keeps the drawn road and legs only while current, and skips anything malformed", () => {
    const drawn = parseSchoolRoute(
      row({
        current: true,
        geometry: { type: "LineString", coordinates: [[11.5, 3.8], [11.5, 3.82], ["x", 1], [11.5, 3.86]] },
        distance_m: 7000,
        duration_s: 900,
        legs: [{ from: "First", to: "Second", distance_m: 2300, duration_s: 300 }, { from: "Second", to: "Main campus", distance_m: 4700, duration_s: 600 }, { bad: true }],
        stops: [{ id: "a", name: "First", lat: 3.8, lng: 11.5 }, { id: 5 }],
      }),
    );
    expect(drawn.road).toHaveLength(3);
    expect(drawn.legs).toHaveLength(2);
    expect(drawn.stops).toHaveLength(1);
    expect(drawn.distanceM).toBe(7000);
    expect(parseSchoolRoute(row({ current: false, geometry: { coordinates: [[11.5, 3.8], [11.5, 3.9]] }, distance_m: 7000 })).distanceM).toBeNull();
    expect(parseSchoolRoute(null)).toMatchObject({ id: null, stops: [], campus: null });
  });
});

describe("directions", () => {
  it("use the road's legs when current, ending at the campus", () => {
    const route = parseSchoolRoute(
      row({ current: true, geometry: { coordinates: [[11.5, 3.8], [11.5, 3.86]] }, legs: [{ from: "First", to: "Second", distance_m: 2300, duration_s: 300 }, { from: "Second", to: "Main campus", distance_m: 4700, duration_s: 600 }] }),
    );
    expect(directions(route)).toEqual([
      { from: "First", to: "Second", distanceM: 2300, durationS: 300, estimated: false },
      { from: "Second", to: "Main campus", distanceM: 4700, durationS: 600, estimated: false },
    ]);
  });

  it("are estimated from straight lines before the road is drawn, and say so", () => {
    const [first, last] = directions(parseSchoolRoute(row()));
    expect(first.estimated).toBe(true);
    // About 2.2 km in a straight line, times 1.3 for the roads.
    expect(first.distanceM).toBeGreaterThan(2800);
    expect(first.distanceM).toBeLessThan(3000);
    expect(last.to).toBe("Main campus");
  });

  it("draw straight between the stops to the campus until the road exists", () => {
    expect(routeLine(parseSchoolRoute(row()))).toEqual([{ lat: 3.8, lng: 11.5 }, { lat: 3.82, lng: 11.5 }, { lat: 3.86, lng: 11.5 }]);
  });
});

describe("helpers", () => {
  it("move one item, keeping the rest in order", () => {
    expect(move(["a", "b", "c"], 2, 0)).toEqual(["c", "a", "b"]);
    expect(move(["a", "b", "c"], 0, 1)).toEqual(["b", "a", "c"]);
    expect(move(["a", "b"], 0, 5)).toEqual(["a", "b"]);
  });

  it("write distances and times like a person would", () => {
    expect(formatKm(850)).toBe("850 m");
    expect(formatKm(1260)).toBe("1.3 km");
    expect(formatMinutes(20)).toBe("1 min");
    expect(formatMinutes(250)).toBe("4 min");
    expect(formatMinutes(3900)).toBe("1 h 05 min");
  });
});

describe("routeOverlay", () => {
  it("gives the Insights views the line, the stop order and the campus; nothing for a route too short to draw", () => {
    expect(routeOverlay(parseSchoolRoute(row()))).toMatchObject({ current: false, stopIds: ["a", "b"], campus: { name: "Main campus" } });
    expect(routeOverlay(parseSchoolRoute(row()))?.line).toHaveLength(3);
    expect(routeOverlay(parseSchoolRoute(row({ stops: [], campus_lat: null, campus_lng: null })))).toBeNull();
  });
});

describe("insertExtras", () => {
  const stops = parseSchoolRoute(row()).stops;
  it("puts each suggested stop after its stop, before the first when -1, nearest first when several", () => {
    const list = insertExtras(stops, [
      { name: "Far", position: { lat: 3.818, lng: 11.5 }, after: 0 },
      { name: "Start", position: { lat: 3.79, lng: 11.5 }, after: -1 },
      { name: "Near", position: { lat: 3.805, lng: 11.5 }, after: 0 },
      { name: "End", position: { lat: 3.84, lng: 11.5 }, after: 1 },
    ]);
    expect(list.map((s) => s.name)).toEqual(["Start", "First", "Near", "Far", "Second", "End"]);
    expect(list.filter((s) => s.suggested)).toHaveLength(4);
  });
});

describe("compareRoutes", () => {
  const overlay = routeOverlay(parseSchoolRoute(row()))!;
  const detour = { name: "Market", position: { lat: 3.81, lng: 11.52 }, after: 0 };

  it("estimates both routes the same way when the road is not drawn, and draws straight through the new stop", () => {
    const c = compareRoutes(overlay, [detour], null);
    expect(c.byRoad).toBe(false);
    expect(c.deltaD).toBeGreaterThan(0);
    expect(c.line).toHaveLength(4);
    expect(c.steps.map((s) => s.to)).toEqual(["Market", "Second", "Main campus"]);
  });

  it("compares road with road once both exist", () => {
    const drawn = { ...overlay, current: true, distanceM: 7000, durationS: 900 };
    const c = compareRoutes(drawn, [detour], { line: [{ lat: 3.8, lng: 11.5 }, { lat: 3.86, lng: 11.5 }], legs: [], distanceM: 8200, durationS: 1100 });
    expect(c).toMatchObject({ byRoad: true, deltaD: 1200, deltaT: 200 });
    expect(c.line).toHaveLength(2);
  });
});
