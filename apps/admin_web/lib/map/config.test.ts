import { describe, expect, it } from "vitest";

import { DEFAULT_CENTER, DEFAULT_STYLE_URL, DEFAULT_ZOOM, resolveMapConfig } from "./config";

describe("resolveMapConfig", () => {
  it("uses safe defaults when nothing is set", () => {
    expect(resolveMapConfig({})).toEqual({
      provider: "maplibre",
      styleUrl: DEFAULT_STYLE_URL,
      fallbackCenter: DEFAULT_CENTER,
      fallbackZoom: DEFAULT_ZOOM,
    });
  });

  it("accepts a valid https style, centre and zoom", () => {
    const config = resolveMapConfig({
      MAP_STYLE_URL: " https://tiles.example.org/style.json ",
      MAP_DEFAULT_LAT: "48.85",
      MAP_DEFAULT_LNG: "2.35",
      MAP_DEFAULT_ZOOM: "9",
    });
    expect(config.styleUrl).toBe("https://tiles.example.org/style.json");
    expect(config.fallbackCenter).toEqual({ lat: 48.85, lng: 2.35 });
    expect(config.fallbackZoom).toBe(9);
  });

  it("allows plain http only for a style served from this machine", () => {
    expect(resolveMapConfig({ MAP_STYLE_URL: "http://127.0.0.1:8080/style.json" }).styleUrl).toBe(
      "http://127.0.0.1:8080/style.json",
    );
    expect(resolveMapConfig({ MAP_STYLE_URL: "http://tiles.example.org/style.json" }).styleUrl).toBe(DEFAULT_STYLE_URL);
  });

  it("ignores values it cannot trust", () => {
    const config = resolveMapConfig({
      MAP_PROVIDER: "someone-else",
      MAP_STYLE_URL: "javascript:alert(1)",
      MAP_DEFAULT_LAT: "999",
      MAP_DEFAULT_LNG: "2",
      MAP_DEFAULT_ZOOM: "100",
    });
    expect(config.provider).toBe("maplibre");
    expect(config.styleUrl).toBe(DEFAULT_STYLE_URL);
    expect(config.fallbackCenter).toEqual(DEFAULT_CENTER);
    expect(config.fallbackZoom).toBe(DEFAULT_ZOOM);
  });

  it("needs both halves of the centre", () => {
    expect(resolveMapConfig({ MAP_DEFAULT_LAT: "10" }).fallbackCenter).toEqual(DEFAULT_CENTER);
  });
});
