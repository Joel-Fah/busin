import { parsePoint } from "@/lib/geo";
import { buildStopLoads, type LoadPeriod, type StopLoads } from "@/lib/insights";
import { buildProximity, parseCorridor, type Corridor, type Proximity } from "@/lib/proximity";
import { parseSchoolRoute, routeOverlay, type RouteOverlay } from "@/lib/route";
import { loadStops } from "@/lib/stops-data";
import { buildSuggestions, type Suggestion, type SuggestionStop } from "@/lib/suggestions";
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

// A school has tens of stops, not thousands.
const MAX_STOPS = 500;

/**
 * How far each stop's subscribers live from it, and the desire lines, from the students' coarse areas. The database
 * returns figures and lines only for 5 or more students, and only to the school's admins.
 */
export async function loadProximity(): Promise<{ proximity: Proximity; corridor: Corridor | null; failed: boolean }> {
  const supabase = await createClient();
  const [stops, rows, lines, nearer, corridor] = await Promise.all([
    supabase.from("stops").select("id, name, location").eq("active", true).order("name").limit(MAX_STOPS),
    supabase.rpc("admin_stop_proximity"),
    supabase.rpc("admin_desire_lines"),
    supabase.rpc("admin_nearer_stops"),
    supabase.rpc("admin_route_corridor"),
  ]);
  const known = (stops.data ?? []).map((stop) => ({ id: stop.id, name: stop.name, position: parsePoint(stop.location) }));
  return {
    proximity: buildProximity(known, rows.data ?? [], lines.data ?? [], nearer.data ?? []),
    corridor: parseCorridor(corridor.data?.[0]),
    failed: stops.error !== null || rows.error !== null || lines.error !== null || nearer.error !== null,
  };
}

/**
 * The stop suggestions (new stops near named places, stops very close together, unused stops) with the active stops to
 * name and place them. Nothing is changed by reading them.
 */
export async function loadSuggestions(): Promise<{ suggestions: Suggestion[]; stops: SuggestionStop[]; failed: boolean }> {
  const supabase = await createClient();
  const [stops, rows] = await Promise.all([
    supabase.from("stops").select("id, name, location").eq("active", true).order("name").limit(MAX_STOPS),
    supabase.rpc("admin_stop_suggestions"),
  ]);
  const known = (stops.data ?? []).map((stop) => ({ id: stop.id, name: stop.name, position: parsePoint(stop.location) }));
  return { suggestions: buildSuggestions(rows.data ?? [], known), stops: known, failed: stops.error !== null || rows.error !== null };
}

/** The school's bus route as the Insights views draw it (road if drawn, else straight), or null without one. */
export async function loadRouteOverlay(): Promise<RouteOverlay | null> {
  const supabase = await createClient();
  const { data } = await supabase.rpc("school_route");
  return routeOverlay(parseSchoolRoute(data?.[0]));
}
