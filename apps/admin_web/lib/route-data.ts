import { parsePoint } from "@/lib/geo";
import { parseSchoolRoute, type BusRoute, type RouteStop } from "@/lib/route";
import { createClient } from "@/lib/supabase/server";

// A school has tens of stops, not thousands.
const MAX_STOPS = 500;

/** The school's route (stops in order, campus, road if drawn) and its active stops, to choose from. */
export async function loadRoute(): Promise<{ route: BusRoute; stops: RouteStop[]; failed: boolean }> {
  const supabase = await createClient();
  const [route, stops] = await Promise.all([
    supabase.rpc("school_route"),
    supabase.from("stops").select("id, name, location, active").eq("active", true).order("name").limit(MAX_STOPS),
  ]);
  const list: RouteStop[] = (stops.data ?? []).flatMap((s) => {
    const position = parsePoint(s.location);
    return position ? [{ id: s.id, name: s.name, position, active: s.active }] : [];
  });
  return { route: parseSchoolRoute(route.data?.[0]), stops: list, failed: route.error !== null || stops.error !== null };
}
