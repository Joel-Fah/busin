import { describe, expect, it } from "vitest";

import { edgeEnds, layoutGraph, projector, separate, stopRadius } from "./graph-layout";

const stop = (id: string, lat: number, lng: number, riders = 10) => ({ id, name: id.toUpperCase(), position: { lat, lng }, riders });

describe("projector", () => {
  it("keeps north up and east right, inside the padding", () => {
    const project = projector([{ lat: 3.8, lng: 11.4 }, { lat: 3.9, lng: 11.6 }], 1000, 640);
    const sw = project({ lat: 3.8, lng: 11.4 });
    const ne = project({ lat: 3.9, lng: 11.6 });
    expect(ne.x).toBeGreaterThan(sw.x);
    expect(ne.y).toBeLessThan(sw.y);
    for (const p of [sw, ne]) {
      expect(p.x).toBeGreaterThanOrEqual(70 - 1e-9);
      expect(p.x).toBeLessThanOrEqual(930 + 1e-9);
      expect(p.y).toBeGreaterThanOrEqual(70 - 1e-9);
      expect(p.y).toBeLessThanOrEqual(570 + 1e-9);
    }
  });

  it("puts a single point in the middle without dividing by zero", () => {
    const p = projector([{ lat: 3.8, lng: 11.4 }], 1000, 640)({ lat: 3.8, lng: 11.4 });
    expect(Number.isFinite(p.x) && Number.isFinite(p.y)).toBe(true);
  });
});

describe("separate", () => {
  it("leaves room between every pair, even ones on the same spot", () => {
    const nodes = separate(
      [
        { x: 500, y: 300, r: 20 },
        { x: 500, y: 300, r: 20 },
        { x: 510, y: 305, r: 30 },
      ],
      1000,
      640,
      10,
    );
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        expect(Math.hypot(nodes[i].x - nodes[j].x, nodes[i].y - nodes[j].y)).toBeGreaterThanOrEqual(nodes[i].r + nodes[j].r + 10 - 0.5);
      }
    }
  });
});

describe("layoutGraph", () => {
  it("sizes stops by riders, places zones around their stop in their real direction, and keeps flows between known stops", () => {
    const layout = layoutGraph(
      [stop("a", 3.85, 11.5, 40), stop("b", 3.9, 11.55, 10)],
      [{ id: "z1", stopId: "a", position: { lat: 3.87, lng: 11.5 }, students: 8, distance: 2200 }],
      [
        { id: "a>b", from: "a", to: "b", students: 6 },
        { id: "a>x", from: "a", to: "x", students: 9 },
      ],
    );
    const a = layout.nodes.find((n) => n.id === "a")!;
    const b = layout.nodes.find((n) => n.id === "b")!;
    const z = layout.nodes.find((n) => n.id === "z1")!;
    expect(a.r).toBeGreaterThan(b.r);
    expect(z.y, "the zone lies north of its stop").toBeLessThan(a.y);
    for (const stopNode of layout.nodes.filter((n) => n.kind === "stop")) {
      expect(Math.hypot(z.x - stopNode.x, z.y - stopNode.y), "never on a stop").toBeGreaterThan(stopNode.r + z.r);
    }
    expect(layout.edges.map((e) => e.id)).toEqual(["zone:z1", "flow:a>b"]);
  });

  it("is empty but valid with no stops", () => {
    expect(layoutGraph([], [], [])).toMatchObject({ nodes: [], edges: [] });
  });

  it("gives every stop a radius between 12 and 34", () => {
    expect(stopRadius(0, 40)).toBe(12);
    expect(stopRadius(40, 40)).toBe(34);
    expect(stopRadius(10, 0)).toBe(12);
  });
});

describe("names", () => {
  it("keep stops with long names further apart", () => {
    const layout = layoutGraph([stop("a", 3.85, 11.5, 1), { ...stop("b", 3.8501, 11.5, 1), name: "A rather long stop name" }], [], []);
    const [a, b] = layout.nodes;
    expect(Math.hypot(a.x - b.x, a.y - b.y)).toBeGreaterThan(80);
  });
});

describe("suggested stops", () => {
  it("are nodes of their own, kept apart from the real stops", () => {
    const layout = layoutGraph([stop("a", 3.85, 11.5, 10)], [], [], 1000, 640, [{ id: "new:0", name: "Market", position: { lat: 3.8502, lng: 11.5 }, students: 8 }]);
    const suggested = layout.nodes.find((n) => n.kind === "suggested")!;
    const a = layout.nodes.find((n) => n.id === "a")!;
    expect(suggested).toMatchObject({ name: "Market", students: 8 });
    expect(Math.hypot(suggested.x - a.x, suggested.y - a.y)).toBeGreaterThan(a.r + suggested.r);
  });
});

describe("the campus", () => {
  it("is a node of its own where the route ends", () => {
    const layout = layoutGraph([stop("a", 3.85, 11.5)], [], [], 1000, 640, [], { name: "ICT University", position: { lat: 3.9, lng: 11.5 } });
    const campus = layout.nodes.find((n) => n.kind === "campus")!;
    const a = layout.nodes.find((n) => n.id === "a")!;
    expect(campus).toMatchObject({ id: "campus", name: "ICT University" });
    expect(campus.y).toBeLessThan(a.y);
  });
});

describe("edgeEnds", () => {
  it("starts and ends on the rims", () => {
    const e = edgeEnds({ x: 0, y: 0, r: 10 }, { x: 100, y: 0, r: 20 }, 0);
    expect(e).toEqual({ x1: 10, y1: 0, x2: 80, y2: 0 });
  });
});
