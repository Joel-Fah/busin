import { buildStopLoads, type LoadPeriod, type StopLoads } from "@/lib/insights";
import { loadStops } from "@/lib/stops-data";
import { createClient } from "@/lib/supabase/server";

// A school runs a handful of buses; the cap only guards against surprises.
const MAX_BUSES = 200;

/**
 * The load of each stop over the period, from the nightly aggregate (never raw scans), with the stops and the seats
 * for the subscribers fallback. Row Level Security and the function's admin check scope everything to the school.
 */
export async function loadStopLoads(days: LoadPeriod): Promise<{ loads: StopLoads; failed: boolean }> {
  const supabase = await createClient();
  const [{ stops, failed }, rows, buses] = await Promise.all([
    loadStops(),
    supabase.rpc("admin_stop_loads", { p_days: days }),
    supabase.from("buses").select("capacity").eq("in_service", true).limit(MAX_BUSES),
  ]);
  const seats = (buses.data ?? []).reduce((sum, bus) => sum + bus.capacity, 0);
  return {
    loads: buildStopLoads(stops, rows.data ?? [], seats),
    failed: failed || rows.error !== null,
  };
}
