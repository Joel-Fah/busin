import type { AreaHost } from "./area-layer";
import type { MapCircle } from "./types";

const SOURCE = "busin-circles";
const LAYER = "busin-circles-fill";

// At street level: 11 pixels for an empty stop (a ring around its marker) to 38 for a full bus.
const RADIUS = ["+", 11, ["*", 27, ["get", "size"]]];

/** "var(--bad)" becomes the token's value on the page (with the fallback when it has none); any other colour is kept. */
export function cssColor(color: string, read: (token: string) => string = pageToken): string {
  const token = /^var\((--[\w-]+)\)$/.exec(color.trim());
  if (!token) return color;
  return read(token[1]).trim() || "#8d8d8d";
}

function pageToken(token: string): string {
  return typeof document === "undefined" ? "" : getComputedStyle(document.documentElement).getPropertyValue(token);
}

/** The circles as GeoJSON points carrying their size and colour (tokens already read from the page). */
export function circleFeatures(circles: readonly MapCircle[], read?: (token: string) => string) {
  return {
    type: "FeatureCollection" as const,
    features: circles.map((circle) => ({
      type: "Feature" as const,
      properties: { id: circle.id, size: Math.min(Math.max(circle.size, 0), 1), color: cssColor(circle.color, read) },
      geometry: { type: "Point" as const, coordinates: [circle.position.lng, circle.position.lat] },
    })),
  };
}

/**
 * Translucent circles under the markers, for example the load of each stop: from 22 pixels across for an empty one to
 * 76 for a full one at street level, a little smaller when zoomed out. Returns a function that removes them.
 */
export function placeCircles(map: AreaHost, circles: readonly MapCircle[]): () => void {
  let removed = false;
  const draw = () => {
    if (removed || map.getSource(SOURCE)) return;
    map.addSource(SOURCE, { type: "geojson", data: circleFeatures(circles) });
    map.addLayer({
      id: LAYER,
      type: "circle",
      source: SOURCE,
      paint: {
        // Zoom may only drive a top-level interpolation, so each stop's size sits inside every step.
        "circle-radius": ["interpolate", ["linear"], ["zoom"], 10, ["*", 0.6, RADIUS], 14, RADIUS, 17, ["*", 1.3, RADIUS]],
        "circle-color": ["get", "color"],
        "circle-opacity": 0.38,
        "circle-stroke-width": 2,
        "circle-stroke-color": ["get", "color"],
        "circle-stroke-opacity": 0.95,
      },
    });
  };
  if (map.isStyleLoaded()) draw();
  else map.once("load", draw);
  return () => {
    removed = true;
    try {
      if (map.getLayer(LAYER)) map.removeLayer(LAYER);
      if (map.getSource(SOURCE)) map.removeSource(SOURCE);
    } catch {
      // The map itself is already gone.
    }
  };
}
