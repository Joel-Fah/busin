/**
 * The layout of the Insights graph, pure so it is tested: stops placed by where they really are (projected onto the
 * canvas), then pushed apart so no two overlap; the zones where 5 or more students of a stop live set around their stop,
 * in their real direction, further out the further they live. No student is ever a node.
 */
import type { LatLng } from "@/lib/geo";

export type GraphStopInput = { id: string; name: string; position: LatLng; riders: number };
export type GraphZoneInput = { id: string; stopId: string; position: LatLng; students: number; distance: number };
export type GraphFlowInput = { id: string; from: string; to: string; students: number };
/** A suggested new stop (never a student): drawn as a dashed ring where it would be. */
export type GraphSuggestedInput = { id: string; name: string; position: LatLng; students: number };

export type GraphNode =
  | { kind: "stop"; id: string; name: string; x: number; y: number; r: number }
  | { kind: "zone"; id: string; stopId: string; x: number; y: number; r: number; students: number; distance: number }
  | { kind: "suggested"; id: string; name: string; x: number; y: number; r: number; students: number };

export type GraphEdge = { id: string; kind: "zone" | "flow"; from: string; to: string; width: number };

export type GraphLayout = { width: number; height: number; nodes: GraphNode[]; edges: GraphEdge[] };

const PAD = 70;
/** Room kept between two stops for their names. */
const GAP = 34;

/** Projects positions onto [PAD, size - PAD], north up (a degree of longitude counts as shorter, as on a map). */
export function projector(points: readonly LatLng[], width: number, height: number): (p: LatLng) => { x: number; y: number } {
  if (points.length === 0) return () => ({ x: width / 2, y: height / 2 });
  const lat0 = points.reduce((s, p) => s + p.lat, 0) / points.length;
  const k = Math.cos((lat0 * Math.PI) / 180);
  const xs = points.map((p) => p.lng * k);
  const ys = points.map((p) => -p.lat);
  const minX = Math.min(...xs);
  const maxX = Math.max(...xs);
  const minY = Math.min(...ys);
  const maxY = Math.max(...ys);
  const spanX = maxX - minX || 1e-6;
  const spanY = maxY - minY || 1e-6;
  // A schematic, not a map: each direction may stretch up to 1.8 times the other, so a tall city still fills a wide screen.
  const fitX = (width - 2 * PAD) / spanX;
  const fitY = (height - 2 * PAD) / spanY;
  const scale = Math.min(fitX, fitY);
  const sx = Math.min(fitX, scale * 1.8);
  const sy = Math.min(fitY, scale * 1.8);
  const offX = (width - spanX * sx) / 2;
  const offY = (height - spanY * sy) / 2;
  return (p) => ({ x: offX + (p.lng * k - minX) * sx, y: offY + (-p.lat - minY) * sy });
}

/** Pushes circles apart until none overlap (with [gap] between them), within the canvas. A few dozen rounds suffice. */
export function separate<T extends { x: number; y: number; r: number }>(nodes: T[], width: number, height: number, gap = GAP, rounds = 120): T[] {
  for (let round = 0; round < rounds; round++) {
    let moved = false;
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const a = nodes[i];
        const b = nodes[j];
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        let d = Math.hypot(dx, dy);
        const need = a.r + b.r + gap;
        if (d >= need) continue;
        if (d < 1e-6) {
          // Same spot: split them along a fixed direction that depends on the pair, so the result is stable.
          const angle = ((i * 7 + j * 13) % 360) * (Math.PI / 180);
          dx = Math.cos(angle);
          dy = Math.sin(angle);
          d = 1;
        }
        const push = (need - d) / 2;
        a.x -= (dx / d) * push;
        a.y -= (dy / d) * push;
        b.x += (dx / d) * push;
        b.y += (dy / d) * push;
        moved = true;
      }
    }
    for (const n of nodes) {
      n.x = Math.min(Math.max(n.x, n.r + 8), width - n.r - 8);
      n.y = Math.min(Math.max(n.y, n.r + 8), height - n.r - 8);
    }
    if (!moved) break;
  }
  return nodes;
}

const round = (n: number) => Math.round(n * 100) / 100;

/** About half the width of a stop's name at 13 px, plus a little air. */
export function labelHalfWidth(name: string): number {
  return name.length * 3.6 + 8;
}

/** A stop's radius: 12 for none, up to 34 for the busiest (the area follows the riders). */
export function stopRadius(riders: number, most: number): number {
  return 12 + 22 * Math.sqrt(most > 0 ? Math.min(riders / most, 1) : 0);
}

export function layoutGraph(
  stops: readonly GraphStopInput[],
  zones: readonly GraphZoneInput[],
  flows: readonly GraphFlowInput[],
  width = 1000,
  height = 640,
  suggested: readonly GraphSuggestedInput[] = [],
): GraphLayout {
  const project = projector([...stops.map((s) => s.position), ...suggested.map((s) => s.position)], width, height);
  const most = Math.max(0, ...stops.map((s) => s.riders));
  // Pushed apart by their name's width too, so a label never runs into the next stop; then drawn at their own size.
  const spaced = separate(
    [
      ...stops.map((s) => {
        const r = stopRadius(s.riders, most);
        return { kind: "stop" as const, id: s.id, name: s.name, students: 0, ...project(s.position), r: Math.max(r, labelHalfWidth(s.name)), own: r };
      }),
      ...suggested.map((s) => ({ kind: "suggested" as const, id: s.id, name: s.name, students: s.students, ...project(s.position), r: Math.max(18, labelHalfWidth(s.name)), own: 18 })),
    ],
    width,
    height,
  );
  const placedAll: GraphNode[] = spaced.map(({ own, students, ...n }) =>
    n.kind === "stop" ? { kind: "stop", id: n.id, name: n.name, x: n.x, y: n.y, r: own } : { kind: "suggested", id: n.id, name: n.name, x: n.x, y: n.y, r: own, students },
  );
  const placed = placedAll.filter((n): n is Extract<GraphNode, { kind: "stop" }> => n.kind === "stop");
  const byId = new Map(placed.map((n) => [n.id, n]));

  // Each zone sits around its stop, in the direction it really lies, at a distance that grows with how far it is.
  const mostZone = Math.max(5, ...zones.map((z) => z.students));
  const zoneNodes: GraphNode[] = [];
  const edges: GraphEdge[] = [];
  zones.forEach((z, index) => {
    const stop = byId.get(z.stopId);
    const real = stops.find((s) => s.id === z.stopId);
    if (!stop || !real) return;
    const from = project(real.position);
    const to = project(z.position);
    let angle = Math.atan2(to.y - from.y, to.x - from.x);
    if (Math.hypot(to.x - from.x, to.y - from.y) < 1e-6) angle = (index * 137.5 * Math.PI) / 180;
    const reach = stop.r + 26 + 34 * Math.log2(1 + z.distance / 500);
    const r = 6 + 8 * Math.sqrt(z.students / mostZone);
    let x = stop.x + Math.cos(angle) * reach;
    let y = stop.y + Math.sin(angle) * reach;
    // Clear of every stop and its name (a few nudges outward from whichever it sits on).
    for (let round = 0; round < 12; round++) {
      let moved = false;
      for (const other of spaced) {
        const dx = x - other.x;
        const dy = y - other.y;
        const d = Math.hypot(dx, dy) || 1;
        const need = other.r + r + 6;
        if (d < need) {
          x += (dx / d) * (need - d);
          y += (dy / d) * (need - d);
          moved = true;
        }
      }
      if (!moved) break;
    }
    x = Math.min(Math.max(x, r + 8), width - r - 8);
    y = Math.min(Math.max(y, r + 8), height - r - 8);
    zoneNodes.push({ kind: "zone", id: z.id, stopId: z.stopId, x, y, r, students: z.students, distance: z.distance });
    edges.push({ id: `zone:${z.id}`, kind: "zone", from: z.id, to: z.stopId, width: 1.5 + 4 * Math.sqrt(z.students / mostZone) });
  });

  const mostFlow = Math.max(5, ...flows.map((f) => f.students));
  for (const f of flows) {
    if (!byId.has(f.from) || !byId.has(f.to)) continue;
    edges.push({ id: `flow:${f.id}`, kind: "flow", from: f.from, to: f.to, width: 2 + 5 * Math.sqrt(f.students / mostFlow) });
  }

  // Rounded to hundredths: the server and the browser can differ in the last digits of the same sum, and the page must
  // render the same text on both.
  const nodes = [...placedAll, ...zoneNodes].map((n) => ({ ...n, x: round(n.x), y: round(n.y), r: round(n.r) }));
  return { width, height, nodes, edges: edges.map((e) => ({ ...e, width: round(e.width) })) };
}

/** Where an edge starts and ends: on the rims of its two nodes, not their centres (arrows then stop at the circle). */
export function edgeEnds(a: { x: number; y: number; r: number }, b: { x: number; y: number; r: number }, inset = 2) {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const d = Math.hypot(dx, dy) || 1;
  return {
    x1: round(a.x + (dx / d) * (a.r + inset)),
    y1: round(a.y + (dy / d) * (a.r + inset)),
    x2: round(b.x - (dx / d) * (b.r + inset)),
    y2: round(b.y - (dy / d) * (b.r + inset)),
  };
}
