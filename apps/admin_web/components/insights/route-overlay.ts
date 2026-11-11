import type { MapMarker, MapRoute } from "@/components/map/types";
import type { RouteOverlay } from "@/lib/route";

/** The bus route as every Insights map shows it: the line (primary) and the campus marker. Nothing without a route. */
export function routeOnMap(route: RouteOverlay | null | undefined, campusBadge: string): { routes: MapRoute[]; campus: MapMarker[] } {
  if (!route) return { routes: [], campus: [] };
  return {
    routes: [{ id: "school-route", coordinates: route.line, emphasis: "primary" }],
    campus: route.campus ? [{ id: "campus", position: route.campus.position, label: route.campus.name, variant: "campus", badge: campusBadge }] : [],
  };
}
