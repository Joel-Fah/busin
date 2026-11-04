import { describe, expect, it } from "vitest";

import { MAX_CLUSTER_ZOOM, clusterPoints, project } from "./cluster";

const near = (id: string, dLat = 0, dLng = 0, pinned = false) => ({ id, position: { lat: 3.848 + dLat, lng: 11.502 + dLng }, pinned });

describe("project", () => {
  it("puts the middle of the world in the middle of the map, and doubles each zoom", () => {
    expect(project({ lat: 0, lng: 0 }, 0)).toEqual({ x: 128, y: 128 });
    const a = project({ lat: 3.8, lng: 11.5 }, 10);
    const b = project({ lat: 3.8, lng: 11.5 }, 11);
    expect(b.x).toBeCloseTo(a.x * 2, 6);
    expect(b.y).toBeCloseTo(a.y * 2, 6);
  });

  it("grows eastward and southward", () => {
    expect(project({ lat: 0, lng: 10 }, 5).x).toBeGreaterThan(project({ lat: 0, lng: 0 }, 5).x);
    expect(project({ lat: -10, lng: 0 }, 5).y).toBeGreaterThan(project({ lat: 10, lng: 0 }, 5).y);
  });
});

describe("clusterPoints", () => {
  it("merges stops that would overlap and reports how many", () => {
    const groups = clusterPoints([near("a"), near("b", 0.0004, 0.0004), near("c", 0.0008, 0)], 12);
    expect(groups).toHaveLength(1);
    expect(groups[0].members).toEqual(["a", "b", "c"]);
  });

  it("keeps stops apart that are far from each other", () => {
    const groups = clusterPoints([near("a"), near("b", 0.2, 0.2)], 12);
    expect(groups.map((g) => g.members)).toEqual([["a"], ["b"]]);
  });

  it("splits a group gradually as the map zooms in", () => {
    const points = [near("a"), near("b", 0, 0.004), near("c", 0, 0.05)];
    const counts = [8, 11, 13, 15].map((zoom) => clusterPoints(points, zoom).length);
    expect(counts[0]).toBe(1);
    expect(counts[counts.length - 1]).toBe(3);
    for (let i = 1; i < counts.length; i++) expect(counts[i]).toBeGreaterThanOrEqual(counts[i - 1]);
  });

  it("shows every stop on its own at and beyond the highest cluster zoom, even stacked ones", () => {
    const groups = clusterPoints([near("a"), near("b")], MAX_CLUSTER_ZOOM);
    expect(groups).toHaveLength(2);
    expect(groups.every((g) => g.members.length === 1)).toBe(true);
  });

  it("never swallows a pinned point (the selected stop, or the visitor's position)", () => {
    const groups = clusterPoints([near("a"), near("pinned", 0.0001, 0.0001, true), near("b", 0.0002, 0)], 10);
    expect(groups.find((g) => g.id === "pinned")?.members).toEqual(["pinned"]);
    expect(groups.find((g) => g.members.length === 2)?.members).toEqual(["a", "b"]);
  });

  it("puts a group at the middle of its members and gives it the same id however they are ordered", () => {
    const [one] = clusterPoints([near("a"), near("b", 0, 0.001)], 9);
    const [two] = clusterPoints([near("b", 0, 0.001), near("a")], 9);
    expect(one.id).toBe(two.id);
    expect(one.position.lng).toBeCloseTo(11.5025, 6);
    expect(one.position.lat).toBeCloseTo(3.848, 6);
  });

  it("handles nothing, and one stop", () => {
    expect(clusterPoints([], 10)).toEqual([]);
    expect(clusterPoints([near("a")], 3)[0].members).toEqual(["a"]);
  });
});
