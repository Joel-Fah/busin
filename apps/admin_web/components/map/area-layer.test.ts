import { describe, expect, it, vi } from "vitest";

import { areaFeatures, placeAreas, type AreaHost } from "./area-layer";

const areas = [
  { position: { lat: 3.86, lng: 11.51 }, students: 7 },
  { position: { lat: 3.9, lng: 11.55 }, students: 12 },
];

function host(loaded: boolean) {
  const sources = new Map<string, unknown>();
  const layers = new Map<string, unknown>();
  let onLoad: (() => void) | undefined;
  const map: AreaHost = {
    isStyleLoaded: () => loaded,
    once: (_event, listener) => (onLoad = listener),
    getSource: (id) => sources.get(id),
    addSource: vi.fn((id: string, source: unknown) => sources.set(id, source)),
    removeSource: (id) => sources.delete(id),
    getLayer: (id) => layers.get(id),
    addLayer: vi.fn((layer: unknown) => layers.set((layer as { id: string }).id, layer)),
    removeLayer: (id) => layers.delete(id),
  };
  return { map, sources, layers, load: () => onLoad?.() };
}

describe("student areas on the map", () => {
  it("are GeoJSON points in longitude, latitude order, with their count", () => {
    const geo = areaFeatures(areas);
    expect(geo.features[0].geometry.coordinates).toEqual([11.51, 3.86]);
    expect(geo.features[1].properties).toEqual({ students: 12 });
  });

  it("are drawn once the style is ready, and removed cleanly", () => {
    const h = host(false);
    const remove = placeAreas(h.map, areas, "#f5951f");
    expect(h.sources.size).toBe(0);
    h.load();
    expect(h.sources.size).toBe(1);
    expect(h.layers.size).toBe(1);
    remove();
    expect(h.sources.size).toBe(0);
    expect(h.layers.size).toBe(0);
  });

  it("are not drawn when removed before the style loads", () => {
    const h = host(false);
    placeAreas(h.map, areas, "#f5951f")();
    h.load();
    expect(h.sources.size).toBe(0);
  });
});
