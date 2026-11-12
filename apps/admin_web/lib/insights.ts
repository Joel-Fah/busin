import type { LatLng } from "@/lib/geo";

/** How busy a stop makes the bus, from its share of the seats. */
export type LoadLevel = "quiet" | "fair" | "busy" | "full";

/** Under a quarter of the seats is quiet, under half fair, under 80% busy, then full. */
export function loadLevel(share: number): LoadLevel {
  if (share >= 0.8) return "full";
  if (share >= 0.5) return "busy";
  if (share >= 0.25) return "fair";
  return "quiet";
}

/** The views of the Insights page. */
export type InsightView = "load" | "proximity" | "graph" | "suggestions";

/** The view from the address; the stop load for anything else. */
export function parseInsightView(value: string | string[] | undefined): InsightView {
  const raw = Array.isArray(value) ? value[0] : value;
  return raw === "proximity" || raw === "graph" || raw === "suggestions" ? raw : "load";
}

/** The periods the page offers, in days. */
export const LOAD_PERIODS = [28, 56, 112] as const;
export type LoadPeriod = (typeof LOAD_PERIODS)[number];
export const DEFAULT_LOAD_PERIOD: LoadPeriod = 56;

/** The period from the address, or the default for anything else. */
export function parseLoadPeriod(value: string | string[] | undefined): LoadPeriod {
  const raw = Number(Array.isArray(value) ? value[0] : value);
  return (LOAD_PERIODS as readonly number[]).includes(raw) ? (raw as LoadPeriod) : DEFAULT_LOAD_PERIOD;
}

/** One row of `admin_stop_loads`. */
export type StopLoadRow = {
  stop_id: string;
  departures: number;
  boardings: number;
  per_departure: number;
  peak: number;
  load: number;
  peak_load: number;
  last_day: string;
  refreshed_at: string;
};

export type LoadStop = { id: string; name: string; active: boolean; position: LatLng | null; students: number };

/**
 * What the load of a stop is based on: real boardings (scans tagged with the stop), or, before any, the approved
 * subscribers of the stop against all the seats of the school's buses in service.
 */
export type LoadBasis = "boardings" | "subscribers";

export type StopLoad = {
  id: string;
  name: string;
  active: boolean;
  position: LatLng | null;
  /** Share of the seats, 0 to 1 (more when a bus is overfull). Null when nothing can be said (no seats known). */
  load: number | null;
  level: LoadLevel | null;
  /** Boardings basis only. */
  departures: number;
  boardings: number;
  perDeparture: number;
  peak: number;
  peakLoad: number;
  lastDay: string | null;
  /** Approved subscribers of the stop. */
  students: number;
};

export type StopLoads = {
  basis: LoadBasis;
  stops: StopLoad[];
  /** When the boardings were last counted (boardings basis), else null. */
  refreshedAt: string | null;
  /** Seats of the school's buses in service (subscribers basis). */
  seats: number;
};

/**
 * Joins the stops with their load, fullest first. With any boarding counted in the period the basis is boardings and
 * a stop without a row had none; otherwise the basis is subscribers.
 */
export function buildStopLoads(stops: readonly LoadStop[], rows: readonly StopLoadRow[], seats: number): StopLoads {
  const byStop = new Map(rows.map((row) => [row.stop_id, row]));
  const basis: LoadBasis = rows.length > 0 ? "boardings" : "subscribers";

  const list = stops.map((stop): StopLoad => {
    const row = byStop.get(stop.id);
    const load = basis === "boardings" ? (row?.load ?? 0) : seats > 0 ? stop.students / seats : null;
    return {
      id: stop.id,
      name: stop.name,
      active: stop.active,
      position: stop.position,
      load,
      level: load === null ? null : loadLevel(load),
      departures: row?.departures ?? 0,
      boardings: row?.boardings ?? 0,
      perDeparture: row?.per_departure ?? 0,
      peak: row?.peak ?? 0,
      peakLoad: row?.peak_load ?? 0,
      lastDay: row?.last_day ?? null,
      students: stop.students,
    };
  });

  list.sort((a, b) => (b.load ?? -1) - (a.load ?? -1) || a.name.localeCompare(b.name));
  const refreshedAt = rows.reduce<string | null>((latest, row) => (latest === null || row.refreshed_at > latest ? row.refreshed_at : latest), null);
  return { basis, stops: list, refreshedAt, seats };
}

/** "62%", rounded; "120%" for an overfull bus. */
export function formatShare(share: number): string {
  return `${Math.round(share * 100)}%`;
}

/** "3.5", or "4" when whole. */
export function formatAverage(value: number): string {
  const rounded = Math.round(value * 10) / 10;
  return Number.isInteger(rounded) ? String(rounded) : rounded.toFixed(1);
}

/**
 * The size of a stop's circle, 0 to 1: the square root of its share (so the area, not the radius, follows the load),
 * capped at a full bus.
 */
export function circleSize(load: number | null): number {
  if (load === null || load <= 0) return 0;
  return Math.sqrt(Math.min(load, 1));
}
