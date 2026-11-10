import type { MapArea } from "./types";

/** What drawing the areas needs from a map library (MapLibre and Mapbox share these calls). */
export type AreaHost = {
  isStyleLoaded(): boolean | void;
  once(event: "load" | "styledata", listener: () => void): unknown;
  getSource(id: string): unknown;
  addSource(id: string, source: unknown): unknown;
  removeSource(id: string): unknown;
  getLayer(id: string): unknown;
  addLayer(layer: unknown): unknown;
  removeLayer(id: string): unknown;
};

const SOURCE = "busin-areas";
const LAYER = "busin-areas-fill";

/** The areas as GeoJSON points carrying their count. */
export function areaFeatures(areas: readonly MapArea[]) {
  return {
    type: "FeatureCollection" as const,
    features: areas.map((area) => ({
      type: "Feature" as const,
      properties: { students: area.students },
      geometry: { type: "Point" as const, coordinates: [area.position.lng, area.position.lat] },
    })),
  };
}

/**
 * Soft discs where students live (ADR 0013): one per zone of about 500 m, sized to the zone at every zoom (a disc
 * of about 250 m radius) and stronger where more students live. Drawn under the stop markers. Returns a function
 * that removes them.
 */
export function placeAreas(map: AreaHost, areas: readonly MapArea[], color: string): () => void {
  let removed = false;
  const draw = () => {
    if (removed || map.getSource(SOURCE)) return;
    map.addSource(SOURCE, { type: "geojson", data: areaFeatures(areas) });
    map.addLayer({
      id: LAYER,
      type: "circle",
      source: SOURCE,
      paint: {
        // About 250 m from zoom 14 on (250 / (156543 / 2^zoom) pixels, doubling with each level); never smaller than
        // 9 pixels, so zones still read when the whole city is in view.
        "circle-radius": ["interpolate", ["exponential", 2], ["zoom"], 10, 9, 13, 14, 14, 26, 18, 409],
        "circle-color": color,
        "circle-opacity": ["interpolate", ["linear"], ["get", "students"], 5, 0.35, 40, 0.7],
        "circle-stroke-width": 1.5,
        "circle-stroke-color": color,
        "circle-stroke-opacity": 0.9,
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

/** The info colour from the page's tokens, so the discs follow the theme and never look like the orange stops. */
export function areaColor(): string {
  const value = getComputedStyle(document.documentElement).getPropertyValue("--info").trim();
  return value || "#1a56c4";
}
