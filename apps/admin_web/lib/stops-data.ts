import { parsePoint, type LatLng } from "@/lib/geo";
import { createClient } from "@/lib/supabase/server";

export type StopRow = { id: string; name: string; active: boolean; position: LatLng | null };

// A school has tens of stops, not thousands. The cap keeps the page light if that ever changes.
const MAX_STOPS = 500;

/** Stops of the admin's school, by name. Row Level Security limits the rows to that school. */
export async function loadStops(): Promise<{ stops: StopRow[]; failed: boolean }> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("stops")
    .select("id, name, active, location")
    .order("name", { ascending: true })
    .limit(MAX_STOPS);

  if (error || !data) return { stops: [], failed: true };
  return {
    stops: data.map((row) => ({ id: row.id, name: row.name, active: row.active, position: parsePoint(row.location) })),
    failed: false,
  };
}
