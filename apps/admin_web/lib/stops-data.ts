import { parsePoint, type LatLng } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";

/** Students with an approved subscription, and requests still waiting, at a stop in a semester that has not ended. */
export type StopUsage = { students: number; pending: number };

export type StopRow = { id: string; name: string; active: boolean; position: LatLng | null } & StopUsage;

// A school has tens of stops, not thousands. The cap keeps the page light if that ever changes.
const MAX_STOPS = 500;

/** Stops of the admin's school, by name. Row Level Security limits the rows to that school. */
export async function loadStops(): Promise<{ stops: StopRow[]; failed: boolean }> {
  const supabase = await createClient();
  const [listed, usage] = await Promise.all([
    supabase.from("stops").select("id, name, active, location").order("name", { ascending: true }).limit(MAX_STOPS),
    supabase.rpc("admin_stop_usage"),
  ]);
  const { data, error } = listed;
  if (error || !data) return { stops: [], failed: true };

  // The counts are a nicety: if they cannot be read, the stops still show, with zero.
  const counts = new Map((usage.data ?? []).map((row) => [row.stop_id, { students: row.students, pending: row.pending }]));
  return {
    stops: data.map((row) => ({
      id: row.id,
      name: row.name,
      active: row.active,
      position: parsePoint(row.location),
      ...(counts.get(row.id) ?? { students: 0, pending: 0 }),
    })),
    failed: false,
  };
}

/** A zone of about 500 m with how many of the school's students live there (ADR 0013). */
export type AreaCount = { position: LatLng; students: number };

/**
 * Where the school's students live, as zones of about 500 m. The server returns only zones with at least 5 students
 * and only for administrators, so no single student can be placed. Empty when nothing can be read.
 */
export async function loadAreaCounts(): Promise<AreaCount[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("admin_area_counts");
  if (error || !data) return [];
  return data
    .filter((row) => Number.isFinite(row.lat) && Number.isFinite(row.lng))
    .map((row) => ({ position: { lat: row.lat, lng: row.lng }, students: row.students }));
}
