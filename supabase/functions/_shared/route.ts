// The road-routing logic of the route-directions function (ADR 0017), kept apart so it is tested without the network:
// splitting a long route into Mapbox Directions requests, building their URLs, and joining the answers into one road
// with a distance and a time for each leg between consecutive waypoints.

export type Waypoint = { seq: number; kind: "stop" | "extra" | "campus"; id: string | null; name: string; lat: number; lng: number };

/** Mapbox Directions accepts at most 25 waypoints per request. */
export const MAX_WAYPOINTS = 25;

/** Splits the waypoints into requests of at most [max], each starting where the previous one ended. */
export function chunk<T>(points: readonly T[], max = MAX_WAYPOINTS): T[][] {
  if (points.length < 2) return [];
  const chunks: T[][] = [];
  for (let start = 0; start < points.length - 1; start += max - 1) {
    chunks.push(points.slice(start, Math.min(start + max, points.length)));
  }
  return chunks;
}

/** The Directions request for one chunk: driving, the whole road as GeoJSON, no turn-by-turn steps. */
export function directionsUrl(points: readonly Waypoint[], token: string): string {
  const path = points.map((p) => `${round6(p.lng)},${round6(p.lat)}`).join(";");
  const query = new URLSearchParams({ geometries: "geojson", overview: "full", steps: "false", access_token: token });
  return `https://api.mapbox.com/directions/v5/mapbox/driving/${path}?${query}`;
}

function round6(n: number): number {
  return Math.round(n * 1e6) / 1e6;
}

/** The parts of a Directions answer used here. */
export type DirectionsAnswer = {
  code: string;
  message?: string;
  routes?: { distance: number; duration: number; geometry: { type: "LineString"; coordinates: [number, number][] }; legs: { distance: number; duration: number }[] }[];
};

export type Leg = { from: string; to: string; from_stop: string | null; to_stop: string | null; distance_m: number; duration_s: number };

export type Road = { geometry: { type: "LineString"; coordinates: [number, number][] }; distance_m: number; duration_s: number; legs: Leg[] };

export class RoutingError extends Error {
  readonly code: string;

  constructor(code: string) {
    super(code);
    this.code = code;
  }
}

/**
 * Joins the answers of consecutive chunks into one road. Each answer has one leg per pair of its waypoints; together they
 * give one leg per pair of consecutive waypoints of the whole route, named after them.
 */
export function joinRoad(points: readonly Waypoint[], answers: readonly DirectionsAnswer[]): Road {
  const coordinates: [number, number][] = [];
  const legs: Leg[] = [];
  let distance = 0;
  let duration = 0;
  let index = 0;
  for (const answer of answers) {
    const route = answer.routes?.[0];
    if (answer.code !== "Ok" || !route) throw new RoutingError(answer.code === "NoRoute" ? "no_road" : "routing_failed");
    const coords = route.geometry.coordinates;
    // A chunk starts where the previous ended: skip its first point so it is not repeated.
    coordinates.push(...(coordinates.length > 0 ? coords.slice(1) : coords));
    distance += route.distance;
    duration += route.duration;
    for (const leg of route.legs) {
      const from = points[index];
      const to = points[index + 1];
      if (!from || !to) throw new RoutingError("routing_failed");
      legs.push({
        from: from.name,
        to: to.name,
        from_stop: from.kind === "stop" ? from.id : null,
        to_stop: to.kind === "stop" ? to.id : null,
        distance_m: Math.round(leg.distance),
        duration_s: Math.round(leg.duration),
      });
      index++;
    }
  }
  if (legs.length !== points.length - 1) throw new RoutingError("routing_failed");
  return { geometry: { type: "LineString", coordinates }, distance_m: Math.round(distance), duration_s: Math.round(duration), legs };
}

/** Draws the road through [points] with [fetcher] (fetch, or a fake in tests), one request per chunk. */
export async function drawRoad(points: readonly Waypoint[], token: string, fetcher: (url: string) => Promise<{ ok: boolean; status: number; json(): Promise<unknown> }>): Promise<Road> {
  if (points.length < 2) throw new RoutingError("too_few_points");
  const answers: DirectionsAnswer[] = [];
  for (const part of chunk(points)) {
    const response = await fetcher(directionsUrl(part, token));
    if (response.status === 401 || response.status === 403) throw new RoutingError("bad_token");
    if (response.status === 429) throw new RoutingError("busy");
    if (!response.ok && response.status !== 422) throw new RoutingError("routing_failed");
    answers.push((await response.json()) as DirectionsAnswer);
  }
  return joinRoad(points, answers);
}
