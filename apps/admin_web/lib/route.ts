/** Pure helpers for the bus route (ADR 0017): reading it, the stop-by-stop directions, and reordering. Tested. */
import { distanceMeters, type LatLng } from "@/lib/geo";

export type RouteStop = { id: string; name: string; position: LatLng; active: boolean };
export type RouteLeg = { from: string; to: string; distanceM: number; durationS: number };

export type BusRoute = {
  id: string | null;
  stops: RouteStop[];
  campus: { name: string; position: LatLng } | null;
  /** The road, when drawn and still current; otherwise null. */
  road: LatLng[] | null;
  distanceM: number | null;
  durationS: number | null;
  legs: RouteLeg[];
  /** The road was drawn for exactly these stops and campus. */
  current: boolean;
  computedAt: string | null;
};

/** One row of `school_route()`. */
export type SchoolRouteRow = {
  route_id: string | null;
  stops: unknown;
  campus_name: string | null;
  campus_lat: number | null;
  campus_lng: number | null;
  geometry: unknown;
  distance_m: number | null;
  duration_s: number | null;
  legs: unknown;
  computed_at: string | null;
  current: boolean | null;
};

const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);

/** Reads the database row safely: anything malformed is left out rather than trusted. */
export function parseSchoolRoute(row: SchoolRouteRow | null | undefined): BusRoute {
  const stops: RouteStop[] = Array.isArray(row?.stops)
    ? row.stops.flatMap((s) => {
        const o = s as Record<string, unknown>;
        const lat = num(o.lat);
        const lng = num(o.lng);
        return typeof o.id === "string" && typeof o.name === "string" && lat !== null && lng !== null
          ? [{ id: o.id, name: o.name, position: { lat, lng }, active: o.active !== false }]
          : [];
      })
    : [];
  const campusLat = num(row?.campus_lat);
  const campusLng = num(row?.campus_lng);
  const campus = campusLat !== null && campusLng !== null ? { name: row?.campus_name || "Campus", position: { lat: campusLat, lng: campusLng } } : null;
  const current = row?.current === true;
  const coords = (row?.geometry as { coordinates?: unknown } | null)?.coordinates;
  const road =
    current && Array.isArray(coords)
      ? coords.flatMap((c) => (Array.isArray(c) && num(c[0]) !== null && num(c[1]) !== null ? [{ lat: c[1] as number, lng: c[0] as number }] : []))
      : null;
  const legs: RouteLeg[] =
    current && Array.isArray(row?.legs)
      ? row.legs.flatMap((l) => {
          const o = l as Record<string, unknown>;
          const d = num(o.distance_m);
          const t = num(o.duration_s);
          return typeof o.from === "string" && typeof o.to === "string" && d !== null && t !== null ? [{ from: o.from, to: o.to, distanceM: d, durationS: t }] : [];
        })
      : [];
  return {
    id: row?.route_id ?? null,
    stops,
    campus,
    road: road && road.length >= 2 ? road : null,
    distanceM: current ? num(row?.distance_m) : null,
    durationS: current ? num(row?.duration_s) : null,
    legs,
    current: current && road !== null,
    computedAt: row?.computed_at ?? null,
  };
}

/** A road is longer than a straight line, and a city bus averages about 20 km/h: an estimate until the road is drawn. */
export const ROAD_FACTOR = 1.3;
export const CITY_KMH = 20;

export type Direction = RouteLeg & { estimated: boolean };

/**
 * Stop-by-stop directions: from the drawn road's legs when current, otherwise estimated from straight lines (and said
 * so). The last leg ends at the campus.
 */
export function directions(route: Pick<BusRoute, "stops" | "campus" | "legs" | "current">): Direction[] {
  const points = [...route.stops.map((s) => ({ name: s.name, position: s.position })), ...(route.campus ? [route.campus] : [])];
  if (route.current && route.legs.length === points.length - 1) return route.legs.map((leg) => ({ ...leg, estimated: false }));
  return points.slice(1).map((to, i) => {
    const distanceM = Math.round(distanceMeters(points[i].position, to.position) * ROAD_FACTOR);
    return { from: points[i].name, to: to.name, distanceM, durationS: Math.round(distanceM / ((CITY_KMH * 1000) / 3600)), estimated: true };
  });
}

/** The line to draw: the road when current, else straight between the stops and on to the campus. */
export function routeLine(route: Pick<BusRoute, "stops" | "campus" | "road">): LatLng[] {
  if (route.road) return route.road;
  return [...route.stops.map((s) => s.position), ...(route.campus ? [route.campus.position] : [])];
}

/** What the Insights views need of the route: the line to draw, the stops in order and the campus. */
export type RouteOverlay = {
  line: LatLng[];
  current: boolean;
  stopIds: string[];
  stops: RouteStop[];
  campus: { name: string; position: LatLng } | null;
  legs: RouteLeg[];
  distanceM: number | null;
  durationS: number | null;
};

export function routeOverlay(route: BusRoute): RouteOverlay | null {
  const line = routeLine(route);
  if (line.length < 2) return null;
  return {
    line,
    current: route.current,
    stopIds: route.stops.map((s) => s.id),
    stops: route.stops,
    campus: route.campus,
    legs: route.legs,
    distanceM: route.distanceM,
    durationS: route.durationS,
  };
}

/** A suggested stop to insert: after the stop at [after] (-1 before the first). */
export type Extra = { name: string; position: LatLng; after: number };

/**
 * The route's stops with suggested ones put in: each after the stop at its position, several after the same stop
 * nearest first (as the database orders a preview).
 */
export function insertExtras(stops: readonly RouteStop[], extras: readonly Extra[]): (RouteStop & { suggested?: boolean })[] {
  const out: (RouteStop & { suggested?: boolean })[] = [];
  const at = (after: number) =>
    extras
      .map((e, i) => ({ ...e, i }))
      .filter((e) => Math.max(e.after, -1) === after)
      .sort((a, b) => {
        const ref = stops[Math.max(after, 0)]?.position;
        return ref ? distanceMeters(ref, a.position) - distanceMeters(ref, b.position) : a.i - b.i;
      })
      .map((e) => ({ id: `suggested:${e.i}`, name: e.name, position: e.position, active: true, suggested: true }));
  out.push(...at(-1));
  stops.forEach((s, i) => {
    out.push(s, ...at(i));
  });
  // Positions past the last stop (between it and the campus) were taken by the last index above.
  return out;
}

/** Moves the item at [from] to [to], keeping the others in order. */
export function move<T>(list: readonly T[], from: number, to: number): T[] {
  if (from < 0 || from >= list.length || to < 0 || to >= list.length || from === to) return [...list];
  const next = [...list];
  const [item] = next.splice(from, 1);
  next.splice(to, 0, item);
  return next;
}

/** "1.2 km" or "850 m". */
export function formatKm(meters: number): string {
  if (meters < 1000) return `${Math.max(10, Math.round(meters / 10) * 10)} m`;
  return `${(Math.round(meters / 100) / 10).toFixed(1)} km`;
}

/** "about 4 min", or "1 h 05 min" over an hour; at least a minute. */
export function formatMinutes(seconds: number): string {
  const minutes = Math.max(1, Math.round(seconds / 60));
  if (minutes < 60) return `${minutes} min`;
  return `${Math.floor(minutes / 60)} h ${String(minutes % 60).padStart(2, "0")} min`;
}

export type RoadPreview = { line: LatLng[]; legs: RouteLeg[]; distanceM: number; durationS: number };

/**
 * Today's route against the same route with suggested stops: the line to draw, its stop-by-stop directions, and the
 * difference in length and time. Road against road when both are drawn; otherwise estimate against estimate, so the
 * difference is fair either way.
 */
export function compareRoutes(route: RouteOverlay, extras: readonly Extra[], road: RoadPreview | null) {
  const withExtras = insertExtras(route.stops, extras);
  const estimatedNew = directions({ stops: withExtras, campus: route.campus, legs: [], current: false });
  const estimatedNow = directions({ stops: route.stops, campus: route.campus, legs: [], current: false });
  const sum = (list: readonly { distanceM: number; durationS: number }[]) => list.reduce((a, l) => ({ d: a.d + l.distanceM, t: a.t + l.durationS }), { d: 0, t: 0 });
  const byRoad = road !== null && route.current && route.distanceM !== null && route.durationS !== null;
  const now = byRoad ? { d: route.distanceM as number, t: route.durationS as number } : sum(estimatedNow);
  const next = byRoad && road ? { d: road.distanceM, t: road.durationS } : sum(estimatedNew);
  return {
    line: road ? road.line : [...withExtras.map((s) => s.position), ...(route.campus ? [route.campus.position] : [])],
    steps: road && road.legs.length > 0 ? road.legs : estimatedNew,
    byRoad,
    deltaD: next.d - now.d,
    deltaT: next.t - now.t,
    total: next,
  };
}
