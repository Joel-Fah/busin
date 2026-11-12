// The best order for a suggested route (ADR 0017): every stop visited once, ending at the campus, for the shortest
// total drive. Travel times come from one Mapbox Matrix request; the order is then found here, exactly for routes of up
// to 13 stops and with a good local search beyond. The first stop may change, but only to a stop near today's first
// stop, and only when that is clearly quicker, so a suggestion never moves where the bus sets off for little gain.

/** Mapbox Matrix accepts at most 25 coordinates per request (driving). */
export const MAX_MATRIX_POINTS = 25;

/** How far the first stop may move from today's first stop. */
export const START_RADIUS_M = 1500;

/** A new first stop must save at least this share of the drive, or today's first stop is kept. */
export const START_GAIN = 0.03;

/** Up to this many stops (the campus aside) the order is exact. */
export const EXACT_LIMIT = 13;

export type MatrixPoint = { lat: number; lng: number };

/** The Matrix request: driving times and distances between every pair of points. */
export function matrixUrl(points: readonly MatrixPoint[], token: string): string {
  const path = points.map((p) => `${round6(p.lng)},${round6(p.lat)}`).join(";");
  const query = new URLSearchParams({ annotations: "duration,distance", access_token: token });
  return `https://api.mapbox.com/directions-matrix/v1/mapbox/driving/${path}?${query}`;
}

function round6(n: number): number {
  return Math.round(n * 1e6) / 1e6;
}

/** Straight-line distance in metres. */
export function haversine(a: MatrixPoint, b: MatrixPoint): number {
  const rad = Math.PI / 180;
  const dLat = (b.lat - a.lat) * rad;
  const dLng = (b.lng - a.lng) * rad;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(a.lat * rad) * Math.cos(b.lat * rad) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371008.8 * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** A cost matrix; null (no road found) counts as unreachable. */
export type Costs = readonly (readonly (number | null)[])[];

const cost = (costs: Costs, a: number, b: number) => costs[a]?.[b] ?? Number.POSITIVE_INFINITY;

/** The total cost of visiting [order] in turn. */
export function pathCost(costs: Costs, order: readonly number[]): number {
  let total = 0;
  for (let i = 1; i < order.length; i++) total += cost(costs, order[i - 1], order[i]);
  return total;
}

/**
 * The cheapest order through every point, starting at one of [starts] and ending at [end]. Exact (Held-Karp) for up to
 * EXACT_LIMIT points besides the end; beyond, nearest neighbour from each start improved by 2-opt. Null when no allowed
 * start reaches the end through every point.
 */
export function bestPath(costs: Costs, starts: readonly number[], end: number): number[] | null {
  const n = costs.length;
  const nodes = Array.from({ length: n }, (_, i) => i).filter((i) => i !== end);
  if (nodes.length === 0) return [end];
  const allowed = starts.filter((s) => s !== end && s >= 0 && s < n);
  if (allowed.length === 0) return null;
  const path = nodes.length <= EXACT_LIMIT ? exact(costs, nodes, allowed, end) : heuristic(costs, nodes, allowed, end);
  return path && Number.isFinite(pathCost(costs, path)) ? path : null;
}

function exact(costs: Costs, nodes: number[], starts: number[], end: number): number[] | null {
  const k = nodes.length;
  const full = (1 << k) - 1;
  const best = new Float64Array((1 << k) * k).fill(Number.POSITIVE_INFINITY);
  const prev = new Int16Array((1 << k) * k).fill(-1);
  for (let i = 0; i < k; i++) if (starts.includes(nodes[i])) best[(1 << i) * k + i] = 0;
  for (let mask = 1; mask <= full; mask++) {
    for (let last = 0; last < k; last++) {
      const here = best[mask * k + last];
      if (!(mask & (1 << last)) || !Number.isFinite(here)) continue;
      for (let next = 0; next < k; next++) {
        if (mask & (1 << next)) continue;
        const to = (mask | (1 << next)) * k + next;
        const value = here + cost(costs, nodes[last], nodes[next]);
        if (value < best[to]) {
          best[to] = value;
          prev[to] = last;
        }
      }
    }
  }
  let finish = -1;
  let total = Number.POSITIVE_INFINITY;
  for (let last = 0; last < k; last++) {
    const value = best[full * k + last] + cost(costs, nodes[last], end);
    if (value < total) {
      total = value;
      finish = last;
    }
  }
  if (finish < 0) return null;
  const order: number[] = [];
  let mask = full;
  let at = finish;
  while (at >= 0) {
    order.push(nodes[at]);
    const before = prev[mask * k + at];
    mask &= ~(1 << at);
    at = before;
  }
  return [...order.reverse(), end];
}

function heuristic(costs: Costs, nodes: number[], starts: number[], end: number): number[] | null {
  let best: number[] | null = null;
  let bestCost = Number.POSITIVE_INFINITY;
  for (const start of starts) {
    const left = new Set(nodes.filter((i) => i !== start));
    const order = [start];
    while (left.size > 0) {
      const from = order[order.length - 1];
      let pick = -1;
      for (const i of left) if (pick < 0 || cost(costs, from, i) < cost(costs, from, pick)) pick = i;
      order.push(pick);
      left.delete(pick);
    }
    order.push(end);
    twoOpt(costs, order);
    const value = pathCost(costs, order);
    if (value < bestCost) {
      bestCost = value;
      best = order;
    }
  }
  return best;
}

/** Reverses stretches of the path while that shortens it; the first and last points stay put. */
function twoOpt(costs: Costs, order: number[]) {
  let improved = true;
  while (improved) {
    improved = false;
    for (let i = 1; i < order.length - 2; i++) {
      for (let j = i + 1; j < order.length - 1; j++) {
        const candidate = [...order.slice(0, i), ...order.slice(i, j + 1).reverse(), ...order.slice(j + 1)];
        if (pathCost(costs, candidate) < pathCost(costs, order) - 1e-9) {
          order.splice(0, order.length, ...candidate);
          improved = true;
        }
      }
    }
  }
}

/**
 * The suggested order: the best path ending at [end], starting at today's first stop ([first]) unless a point within
 * START_RADIUS_M of it gives a path at least START_GAIN quicker.
 */
export function suggestedOrder(points: readonly MatrixPoint[], costs: Costs, first: number, end: number): number[] | null {
  const kept = bestPath(costs, [first], end);
  const near = points.flatMap((p, i) => (i !== end && haversine(p, points[first]) <= START_RADIUS_M ? [i] : []));
  const moved = bestPath(costs, near, end);
  if (!kept) return moved;
  if (!moved || moved[0] === first) return kept;
  return pathCost(costs, moved) <= pathCost(costs, kept) * (1 - START_GAIN) ? moved : kept;
}
