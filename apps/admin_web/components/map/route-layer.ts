import type { AreaHost } from "./area-layer";
import { cssColor } from "./circle-layer";
import type { MapRoute } from "./types";

const SOURCE = "busin-routes";
// Drawn bottom up: the secondary routes under the primary, each over a light casing so it reads on any street.
const LAYERS = ["busin-route-secondary-casing", "busin-route-secondary", "busin-route-primary-casing", "busin-route-primary"] as const;

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
          color: cssColor(route.color ?? (route.emphasis === "primary" ? "var(--info)" : "var(--muted)"), read),
          casing: cssColor("var(--surface)", read),
        },
        geometry: { type: "LineString" as const, coordinates: route.coordinates.map((p) => [p.lng, p.lat]) },
      })),
  };
}

/**
 * Bus routes along the roads, Google Maps style: the primary bold and coloured over a light casing, secondary routes
 * thinner, grey and a little transparent beneath it. A route not drawn along roads yet ("straight") is dashed. Returns a
 * function that removes them.
 */
export function placeRoutes(map: AreaHost, routes: readonly MapRoute[]): () => void {
  let removed = false;
  const draw = () => {
    if (removed || map.getSource(SOURCE)) return;
    map.addSource(SOURCE, { type: "geojson", data: routeFeatures(routes) });
    const width = (primary: boolean, casing: boolean) => {
      const base = primary ? (casing ? 9 : 5.5) : casing ? 7 : 4;
      return ["interpolate", ["linear"], ["zoom"], 10, base * 0.6, 14, base, 17, base * 1.4];
    };
    for (const id of LAYERS) {
      const primary = id.includes("primary");
      const casing = id.endsWith("casing");
      map.addLayer({
        id,
        type: "line",
        source: SOURCE,
        filter: ["==", ["get", "emphasis"], primary ? "primary" : "secondary"],
        layout: { "line-cap": "round", "line-join": "round" },
        paint: {
          "line-width": width(primary, casing),
          "line-color": casing ? ["get", "casing"] : ["get", "color"],
          "line-opacity": primary ? (casing ? 0.9 : 0.95) : casing ? 0.7 : 0.75,
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
