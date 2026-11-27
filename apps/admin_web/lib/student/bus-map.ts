import { distanceMeters, type LatLng } from "@/lib/geo";

import type { BusUpdate, StopPoint } from "./bus";

/**
 * The My bus map's pure parts, ported from the student app (map_layers.dart, map_motion.dart, bus_providers.dart) so
 * both draw the same map: the marker colours, the GeoJSON the layers read, the glide between two positions, the ping
 * around a marker, the school's route and the trip's trail. The time is passed in, so every case is a unit test.
 */

/** The same in light and dark: they sit on the map, not on the page's surfaces. The legend uses them too. */
export const MAP_COLORS = {
  stop: "#8A9A9E",
  myStop: "#F5951F",
  bus: "#2F6FED",
  me: "#0F9D58",
  campus: "#0C5D6D",
  route: "#0C5D6D",
  trail: "#2F6FED",
} as const;

type Feature = { type: "Feature"; properties: Record<string, unknown>; geometry: { type: "Point"; coordinates: [number, number] } | { type: "LineString"; coordinates: [number, number][] } };
export type FeatureCollection = { type: "FeatureCollection"; features: Feature[] };

/** GeoJSON wants longitude first. */
const lngLat = (p: LatLng): [number, number] => [p.lng, p.lat];

const collection = (features: Feature[]): FeatureCollection => ({ type: "FeatureCollection", features });

const pointFeature = (p: LatLng, properties: Record<string, unknown> = {}): Feature => ({ type: "Feature", properties, geometry: { type: "Point", coordinates: lngLat(p) } });

/** The stops, each with its name (the label) and whether it is the student's own (orange instead of grey). */
export function stopsData(stops: StopPoint[], myStopId: string | null): FeatureCollection {
  return collection(stops.map((s) => pointFeature(s.position, { name: s.name, mine: s.id === myStopId })));
}

/** One point, or nothing. */
export function pointData(p: LatLng | null, properties: Record<string, unknown> = {}): FeatureCollection {
  return collection(p ? [pointFeature(p, properties)] : []);
}

/** A line through the points, or nothing when there are fewer than two. */
export function lineData(points: LatLng[]): FeatureCollection {
  return collection(points.length >= 2 ? [{ type: "Feature", properties: {}, geometry: { type: "LineString", coordinates: points.map(lngLat) } }] : []);
}

/** The rings that ping out of the bus and the student's stop; `kind` picks the colour and the size. */
export function pulseData(bus: LatLng | null, myStop: LatLng | null): FeatureCollection {
  const features: Feature[] = [];
  if (myStop) features.push(pointFeature(myStop, { kind: "stop" }));
  if (bus) features.push(pointFeature(bus, { kind: "bus" }));
  return collection(features);
}

/** The point a fraction `t` (0 to 1) of the way from `a` to `b`. */
export function lerpPoint(a: LatLng, b: LatLng, t: number): LatLng {
  const f = Math.min(1, Math.max(0, t));
  return { lat: a.lat + (b.lat - a.lat) * f, lng: a.lng + (b.lng - a.lng) * f };
}

/** Gentle at the end, so the dot settles instead of stopping dead. */
const easeOut = (t: number) => 1 - (1 - t) ** 2;

/**
 * A marker moving smoothly from where it is drawn to its newest position, instead of jumping. The bus reports every few
 * seconds; gliding over about the time between its last two reports keeps it moving almost all the time, at most one
 * report behind. A long gap (the signal came back) or a far jump (a bad fix corrected) is not glided.
 */
export class Glide {
  static readonly SHORTEST_MS = 800;
  static readonly LONGEST_MS = 6000;
  /** Further than this between two reports is a jump, not a movement (about 1.5 km). */
  static readonly JUMP_M = 1500;

  private constructor(
    readonly from: LatLng,
    readonly to: LatLng,
    readonly startedAt: number,
    readonly durationMs: number,
  ) {}

  /** Starts at `to` with nothing to glide. */
  static at(to: LatLng, now: number): Glide {
    return new Glide(to, to, now, 0);
  }

  /** Where to draw the marker at `now`. */
  positionAt(now: number): LatLng {
    if (this.durationMs === 0) return this.to;
    const t = (now - this.startedAt) / this.durationMs;
    return t >= 1 ? this.to : lerpPoint(this.from, this.to, easeOut(Math.max(0, t)));
  }

  /** Whether the marker is still on its way at `now`. */
  movingAt(now: number): boolean {
    return this.durationMs > 0 && now - this.startedAt < this.durationMs;
  }

  /** The next glide: from where the marker is drawn now to `next`, over about the time since the previous report. */
  towards(next: LatLng, now: number, sinceLastReportMs: number, reduced = false): Glide {
    const here = this.positionAt(now);
    if (reduced || sinceLastReportMs > 30_000 || distanceMeters(here, next) > Glide.JUMP_M) return Glide.at(next, now);
    const ms = Math.min(Glide.LONGEST_MS, Math.max(Glide.SHORTEST_MS, Math.round(sinceLastReportMs * 0.9)));
    return new Glide(here, next, now, ms);
  }
}

/**
 * A ring growing out of a marker and fading, like a radar ping. `phase` runs from 0 to 1 over one ping; the ring starts
 * at the marker's `radius` and grows by `spread` while it fades from `opacity` to nothing.
 */
export function pulseAt(phase: number, radius: number, spread: number, opacity = 0.45): { radius: number; opacity: number } {
  const p = phase - Math.floor(phase);
  const grown = 1 - (1 - p) ** 3;
  return { radius: radius + spread * grown, opacity: opacity * (1 - p) };
}

/**
 * The points of a GeoJSON LineString, or of every part of a MultiLineString joined. Anything else, or a point out of
 * range, gives an empty list: the map then draws no line.
 */
export function lineFromGeoJson(json: unknown): LatLng[] {
  if (!json || typeof json !== "object") return [];
  const { type, coordinates } = json as { type?: unknown; coordinates?: unknown };
  if (!Array.isArray(coordinates)) return [];
  const parts = type === "LineString" ? [coordinates] : type === "MultiLineString" ? coordinates : [];
  const points: LatLng[] = [];
  for (const part of parts) {
    if (!Array.isArray(part)) return [];
    for (const c of part) {
      if (!Array.isArray(c) || c.length < 2 || typeof c[0] !== "number" || typeof c[1] !== "number") return [];
      const [lng, lat] = c as [number, number];
      if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180) return [];
      points.push({ lat, lng });
    }
  }
  return points;
}

/** The school's planned route along roads and its campus, as the map draws them. Null when there is neither. */
export type SchoolRoute = { line: LatLng[]; campus: LatLng | null; campusName: string | null };

/** Reads a row of `school_route()`: a GeoJSON LineString in `geometry`, the campus in `campus_lat`/`campus_lng`. */
export function routeFromRow(row: { geometry?: unknown; campus_lat?: unknown; campus_lng?: unknown; campus_name?: unknown } | null | undefined): SchoolRoute | null {
  if (!row) return null;
  const line = lineFromGeoJson(row.geometry);
  const lat = row.campus_lat;
  const lng = row.campus_lng;
  const campus = typeof lat === "number" && typeof lng === "number" ? { lat, lng } : null;
  if (line.length < 2 && !campus) return null;
  return { line, campus, campusName: typeof row.campus_name === "string" ? row.campus_name : null };
}

/** A new trail point only this far from the last one, so a bus standing at a stop does not pile points up. */
export const TRAIL_MIN_STEP_M = 15;
/** Never more than this many points: the oldest go first (a very long trip). */
export const TRAIL_MAX_POINTS = 600;

const capped = (points: LatLng[]) => (points.length <= TRAIL_MAX_POINTS ? points : points.slice(points.length - TRAIL_MAX_POINTS));

/** The trail with `p` added at its end, unless the bus has barely moved. The same list when nothing changed. */
export function addTrailPoint(trail: LatLng[], p: LatLng): LatLng[] {
  const last = trail[trail.length - 1];
  if (last && distanceMeters(last, p) < TRAIL_MIN_STEP_M) return trail;
  return capped([...trail, p]);
}

/** What the server kept first, then what arrived while it loaded. */
export function mergeTrail(kept: LatLng[], seen: LatLng[]): LatLng[] {
  return kept.length === 0 ? seen : capped([...kept, ...seen]);
}

/** Enough for a whole trip's stops to stay listed. */
export const KEPT_UPDATES = 25;

/** The trip's updates with `update` first, newest first, at most `KEPT_UPDATES`. */
export function keepUpdate(updates: BusUpdate[], update: BusUpdate): BusUpdate[] {
  return [update, ...updates.slice(0, KEPT_UPDATES - 1)];
}

/**
 * Whether a point on screen is inside the part of the map the student can see: on the map, clear of the edges, and
 * above whatever floats over its bottom.
 */
export function insideView(point: { x: number; y: number }, size: { width: number; height: number }, coveredBottom: number, margin = 24): boolean {
  return point.x >= margin && point.x <= size.width - margin && point.y >= margin && point.y <= size.height - coveredBottom - margin;
}
