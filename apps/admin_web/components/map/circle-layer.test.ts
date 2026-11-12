import { describe, expect, it, vi } from "vitest";

import type { AreaHost } from "./area-layer";
import { circleFeatures, cssColor, placeCircles } from "./circle-layer";

const circles = [
  { id: "a", position: { lat: 3.86, lng: 11.51 }, size: 0.5, color: "#0b7a43" },
  { id: "b", position: { lat: 3.9, lng: 11.55 }, size: 3, color: "#b3261e" },
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

describe("circles on the map", () => {
  it("are GeoJSON points in longitude, latitude order, their size kept between 0 and 1", () => {
    const geo = circleFeatures(circles);
    expect(geo.features[0].geometry.coordinates).toEqual([11.51, 3.86]);
    expect(geo.features[0].properties).toEqual({ id: "a", size: 0.5, color: "#0b7a43" });
    expect(geo.features[1].properties.size).toBe(1);
  });

  it("read theme tokens from the page, with a grey when the token is missing", () => {
    const read = (token: string) => (token === "--bad" ? " #ff0000 " : "");
    expect(cssColor("var(--bad)", read)).toBe("#ff0000");
    expect(cssColor("var(--nope)", read)).toBe("#8d8d8d");
    expect(cssColor("#0b7a43", read)).toBe("#0b7a43");
  });

  it("are drawn once the style is ready, and removed cleanly", () => {
    const h = host(false);
    const remove = placeCircles(h.map, circles);
    expect(h.sources.size).toBe(0);
    h.load();
    expect(h.layers.size).toBe(1);
    remove();
    expect(h.sources.size).toBe(0);
    expect(h.layers.size).toBe(0);
  });

  it("are drawn at once on a ready map, and not twice", () => {
    const h = host(true);
    placeCircles(h.map, circles);
    placeCircles(h.map, circles);
    expect(h.map.addLayer).toHaveBeenCalledTimes(1);
  });
});
