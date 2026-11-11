import type { LatLng } from "@/lib/geo";

/** Under 500 m, 500 m to 1 km, 1 to 2 km, over 2 km: how far a stop's typical student lives from it. */
export type Reach = "near" | "walk" | "far" | "remote";

export function reachOf(meters: number): Reach {
  if (meters < 500) return "near";
  if (meters < 1000) return "walk";
  if (meters < 2000) return "far";
  return "remote";
}

/** No figure is shown for fewer students with an area than this (the database applies the same rule). */
export const MIN_STUDENTS = 5;

/** One row of `admin_stop_proximity`. Figures are null under 5 students with an area. */
export type ProximityRow = {
  stop_id: string;
  subscribers: number;
  with_area: number;
  median_m: number | null;
  under_500: number | null;
  to_1k: number | null;
  to_2k: number | null;
  over_2k: number | null;
};

/** One row of `admin_desire_lines`: a cell of about 500 m where 5 or more subscribers of one stop live. */
export type DesireLineRow = { lat: number; lng: number; stop_id: string; students: number; distance_m: number };

export type ProximityStop = {
  id: string;
  name: string;
  position: LatLng | null;
  subscribers: number;
  withArea: number;
  /** Null under 5 students with an area. */
  median: number | null;
  reach: Reach | null;
  /** Counts per band, in the order near, walk, far, remote. Null under 5 students with an area. */
  bands: [number, number, number, number] | null;
  /** Share (0 to 1) living more than 1 km away. Null under 5. */
  overOneKm: number | null;
};

export type DesireLine = { id: string; from: LatLng; to: LatLng; students: number; distance: number };

export type Proximity = {
  stops: ProximityStop[];
  lines: DesireLine[];
  /** All subscribers, and those who gave an area: "based on 41 of 120". */
  subscribers: number;
  withArea: number;
};

export type ProximityStopInput = { id: string; name: string; position: LatLng | null };

/** Joins the stops with their figures: stops with figures first, farthest median first; the others by name. */
export function buildProximity(stops: readonly ProximityStopInput[], rows: readonly ProximityRow[], lineRows: readonly DesireLineRow[]): Proximity {
  const known = new Map(stops.map((stop) => [stop.id, stop]));
  const list: ProximityStop[] = rows.flatMap((row) => {
    const stop = known.get(row.stop_id);
    if (!stop) return [];
    const enough = row.with_area >= MIN_STUDENTS && row.median_m !== null;
    const bands: ProximityStop["bands"] = enough ? [row.under_500 ?? 0, row.to_1k ?? 0, row.to_2k ?? 0, row.over_2k ?? 0] : null;
    return [
      {
        id: stop.id,
        name: stop.name,
        position: stop.position,
        subscribers: row.subscribers,
        withArea: row.with_area,
        median: enough ? row.median_m : null,
        reach: enough && row.median_m !== null ? reachOf(row.median_m) : null,
        bands,
        overOneKm: bands ? (bands[2] + bands[3]) / row.with_area : null,
      },
    ];
  });
  list.sort((a, b) => (b.median ?? -1) - (a.median ?? -1) || a.name.localeCompare(b.name));

  const lines: DesireLine[] = lineRows.flatMap((row) => {
    const to = known.get(row.stop_id)?.position;
    if (!to || !Number.isFinite(row.lat) || !Number.isFinite(row.lng)) return [];
    return [{ id: `${row.stop_id}:${row.lat}:${row.lng}`, from: { lat: row.lat, lng: row.lng }, to, students: row.students, distance: row.distance_m }];
  });

  return {
    stops: list,
    lines,
    subscribers: list.reduce((sum, stop) => sum + stop.subscribers, 0),
    withArea: list.reduce((sum, stop) => sum + stop.withArea, 0),
  };
}

/** "about 400 m" style figures: under 1 km to the nearest 50 m, then to the nearest 100 m, as "1.4 km". */
export function roughDistance(meters: number): { value: string; unit: "m" | "km" } {
  if (meters < 975) return { value: String(Math.max(50, Math.round(meters / 50) * 50)), unit: "m" };
  const km = Math.round(meters / 100) / 10;
  return { value: Number.isInteger(km) ? String(km) : km.toFixed(1), unit: "km" };
}

/** Line thickness, 0 to 1, from the number of students behind it (5 is thin, 25 or more is the thickest). */
export function lineSize(students: number): number {
  return Math.min(Math.max((students - MIN_STUDENTS) / 20, 0), 1);
}
