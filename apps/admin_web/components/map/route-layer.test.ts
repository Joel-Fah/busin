import { describe, expect, it, vi } from "vitest";

import type { AreaHost } from "./area-layer";
import { placeRoutes, routeFeatures } from "./route-layer";

const read = (token: string) => ({ "--info": "#1a56c4", "--muted": "#4d6a70", "--surface": "#ffffff", "--accent": "#f5951f" })[token] ?? "";

function host(loaded: boolean) {
  const sources = new Map<string, unknown>();
  const layers: string[] = [];
  let onLoad: (() => void) | undefined;
  const map: AreaHost = {
    isStyleLoaded: () => loaded,
    once: (_event, listener) => (onLoad = listener),
    getSource: (id) => sources.get(id),
    addSource: vi.fn((id: string, source: unknown) => sources.set(id, source)),
    removeSource: (id) => sources.delete(id),
    getLayer: (id) => (layers.includes(id) ? id : undefined),
    addLayer: vi.fn((layer: unknown) => layers.push((layer as { id: string }).id)),
    removeLayer: (id) => layers.splice(layers.indexOf(id), 1),
  };
  return { map, sources, layers, load: () => onLoad?.() };
}

describe("routes on the map", () => {
  it("are lines in longitude, latitude order with their emphasis and colours; a route of one point is left out", () => {
    const geo = routeFeatures(
      [
        { id: "a", emphasis: "primary", coordinates: [{ lat: 3.8, lng: 11.5 }, { lat: 3.9, lng: 11.6 }] },
        { id: "b", emphasis: "secondary", coordinates: [{ lat: 3.8, lng: 11.5 }, { lat: 3.85, lng: 11.55 }] },
        { id: "c", emphasis: "primary", coordinates: [{ lat: 3.8, lng: 11.5 }] },
        { id: "d", emphasis: "suggested", coordinates: [{ lat: 3.8, lng: 11.5 }, { lat: 3.86, lng: 11.56 }] },
      ],
      read,
    );
    expect(geo.features).toHaveLength(3);
    expect(geo.features[0].geometry.coordinates).toEqual([
      [11.5, 3.8],
      [11.6, 3.9],
    ]);
    expect(geo.features[0].properties).toMatchObject({ emphasis: "primary", color: "#1a56c4", casing: "#ffffff" });
    expect(geo.features[1].properties.color).toBe("#4d6a70");
    expect(geo.features[2].properties).toMatchObject({ emphasis: "suggested", color: "#f5951f" });
  });

  it("draw the secondary routes under the primary and a suggested one on top, each over a casing, and remove cleanly", () => {
    const h = host(true);
    const remove = placeRoutes(h.map, [{ id: "a", emphasis: "primary", coordinates: [{ lat: 3.8, lng: 11.5 }, { lat: 3.9, lng: 11.6 }] }]);
    expect(h.layers).toEqual([
      "busin-route-secondary-casing",
      "busin-route-secondary",
      "busin-route-primary-casing",
      "busin-route-primary",
      "busin-route-suggested-casing",
      "busin-route-suggested",
    ]);
    remove();
    expect(h.layers).toEqual([]);
    expect(h.sources.size).toBe(0);
  });
});
