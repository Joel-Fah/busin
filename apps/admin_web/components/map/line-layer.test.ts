import { describe, expect, it, vi } from "vitest";

import type { AreaHost } from "./area-layer";
import { lineFeatures, placeLines } from "./line-layer";

const lines = [{ id: "l1", from: { lat: 3.87, lng: 11.5 }, to: { lat: 3.85, lng: 11.51 }, size: 2, color: "var(--accent)" }];

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

describe("lines on the map", () => {
  it("are GeoJSON line strings from one point to the other, longitude first", () => {
    const geo = lineFeatures(lines, (token) => (token === "--accent" ? "#f5951f" : ""));
    expect(geo.features[0].geometry.coordinates).toEqual([
      [11.5, 3.87],
      [11.51, 3.85],
    ]);
    expect(geo.features[0].properties).toEqual({ id: "l1", size: 1, color: "#f5951f" });
  });

  it("are drawn once the style is ready, and removed cleanly", () => {
    const h = host(false);
    const remove = placeLines(h.map, lines);
    expect(h.layers.size).toBe(0);
    h.load();
    expect(h.layers.size).toBe(1);
    remove();
    expect(h.sources.size).toBe(0);
    expect(h.layers.size).toBe(0);
  });
});
