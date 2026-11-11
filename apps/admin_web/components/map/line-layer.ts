import type { AreaHost } from "./area-layer";
import { cssColor } from "./circle-layer";
import type { MapLine } from "./types";

const SOURCE = "busin-lines";
const LAYER = "busin-lines-stroke";

/** The lines as GeoJSON line strings carrying their size and colour (tokens already read from the page). */
export function lineFeatures(lines: readonly MapLine[], read?: (token: string) => string) {
  return {
    type: "FeatureCollection" as const,
    features: lines.map((line) => ({
      type: "Feature" as const,
      properties: { id: line.id, size: Math.min(Math.max(line.size, 0), 1), color: cssColor(line.color, read) },
      geometry: {
        type: "LineString" as const,
        coordinates: [
          [line.from.lng, line.from.lat],
          [line.to.lng, line.to.lat],
        ],
      },
    })),
  };
}

// At street level: 3 pixels for the thinnest line, 14 for the thickest.
const WIDTH = ["+", 3, ["*", 11, ["get", "size"]]];

/**
 * Straight lines under the markers, for example from where students live to their stop ("desire lines"), thicker for
 * more students and a little thinner when zoomed out. Rounded ends, slightly see-through. Returns a function that
 * removes them.
 */
export function placeLines(map: AreaHost, lines: readonly MapLine[]): () => void {
  let removed = false;
  const draw = () => {
    if (removed || map.getSource(SOURCE)) return;
    map.addSource(SOURCE, { type: "geojson", data: lineFeatures(lines) });
    map.addLayer({
      id: LAYER,
      type: "line",
      source: SOURCE,
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        // Zoom may only drive a top-level interpolation, so each line's size sits inside every step.
        "line-width": ["interpolate", ["linear"], ["zoom"], 10, ["*", 0.6, WIDTH], 14, WIDTH, 17, ["*", 1.3, WIDTH]],
        "line-color": ["get", "color"],
        "line-opacity": 0.75,
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
