import type { AreaHost } from "./area-layer";
import { cssColor } from "./circle-layer";
import type { MapRoute } from "./types";

const SOURCE = "busin-routes";
// Drawn bottom up: the secondary routes under the primary, each over a light casing so it reads on any street, and a
// suggested route on top of all, thinner, so where it shares a road with the primary it reads as a line inside it.
const LAYERS = [
  "busin-route-secondary-casing",
  "busin-route-secondary",
  "busin-route-primary-casing",
  "busin-route-primary",
  "busin-route-suggested-casing",
  "busin-route-suggested",
] as const;

type Emphasis = MapRoute["emphasis"];
const DEFAULT_COLOR: Record<Emphasis, string> = { primary: "var(--info)", secondary: "var(--muted)", suggested: "var(--accent)" };
// Line widths at zoom 14, without and with the casing.
const WIDTH: Record<Emphasis, [number, number]> = { primary: [5.5, 9], secondary: [4, 7], suggested: [3, 5.5] };
const OPACITY: Record<Emphasis, [number, number]> = { primary: [0.95, 0.9], secondary: [0.75, 0.7], suggested: [1, 0.95] };

/** The routes as GeoJSON lines carrying their emphasis and colours (tokens already read from the page). */
export function routeFeatures(routes: readonly MapRoute[], read?: (token: string) => string) {
  return {
    type: "FeatureCollection" as const,
    features: routes
      .filter((route) => route.coordinates.length >= 2)
      .map((route) => ({
        type: "Feature" as const,
        properties: {
          id: route.id,
          emphasis: route.emphasis,
          color: cssColor(route.color ?? DEFAULT_COLOR[route.emphasis], read),
          casing: cssColor("var(--surface)", read),
        },
        geometry: { type: "LineString" as const, coordinates: route.coordinates.map((p) => [p.lng, p.lat]) },
      })),
  };
}

/**
 * Bus routes along the roads, Google Maps style: the primary bold and coloured over a light casing, secondary routes
 * thinner, grey and a little transparent beneath it, and a suggested route in its own colour over everything. Returns a
 * function that removes them.
 */
export function placeRoutes(map: AreaHost, routes: readonly MapRoute[]): () => void {
  let removed = false;
  const draw = () => {
    if (removed || map.getSource(SOURCE)) return;
    map.addSource(SOURCE, { type: "geojson", data: routeFeatures(routes) });
    for (const id of LAYERS) {
      const emphasis = id.split("-")[2] as Emphasis;
      const casing = id.endsWith("casing") ? 1 : 0;
      const base = WIDTH[emphasis][casing];
      map.addLayer({
        id,
        type: "line",
        source: SOURCE,
        filter: ["==", ["get", "emphasis"], emphasis],
        layout: { "line-cap": "round", "line-join": "round" },
        paint: {
          "line-width": ["interpolate", ["linear"], ["zoom"], 10, base * 0.6, 14, base, 17, base * 1.4],
          "line-color": casing ? ["get", "casing"] : ["get", "color"],
          "line-opacity": OPACITY[emphasis][casing],
        },
      });
    }
  };
  if (map.isStyleLoaded()) draw();
  else map.once("load", draw);
  return () => {
    removed = true;
    try {
      for (const id of [...LAYERS].reverse()) if (map.getLayer(id)) map.removeLayer(id);
      if (map.getSource(SOURCE)) map.removeSource(SOURCE);
    } catch {
      // The map itself is already gone.
    }
  };
}
