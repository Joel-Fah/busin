import { describe, expect, it } from "vitest";

import { DEFAULT_CENTER, DEFAULT_MAPBOX_STYLE_URL, DEFAULT_STYLE_URL, DEFAULT_ZOOM, isPublicMapboxToken, resolveMapConfig } from "./config";

describe("resolveMapConfig", () => {
  it("uses safe defaults when nothing is set", () => {
    expect(resolveMapConfig({})).toEqual({
      provider: "maplibre",
      styleUrl: DEFAULT_STYLE_URL,
      accessToken: "",
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

const PUBLIC = "pk.eyJ1IjoiYnVzaW4iLCJhIjoiYWJjMTIzIn0.abc-123_XYZ";

describe("isPublicMapboxToken", () => {
  it("accepts a public token and rejects everything else, above all a secret one", () => {
    expect(isPublicMapboxToken(PUBLIC)).toBe(true);
    expect(isPublicMapboxToken(` ${PUBLIC} `)).toBe(true);
    expect(isPublicMapboxToken("sk.eyJ1IjoiYnVzaW4iLCJhIjoiYWJj.secret-part")).toBe(false);
    expect(isPublicMapboxToken("pk.only-one-part")).toBe(false);
    expect(isPublicMapboxToken("")).toBe(false);
    expect(isPublicMapboxToken(undefined)).toBe(false);
  });
});

describe("resolveMapConfig with Mapbox", () => {
  it("uses Mapbox by default in production once a public token exists", () => {
    const config = resolveMapConfig({ MAPBOX_API_KEY: PUBLIC, NODE_ENV: "production" });
    expect(config.provider).toBe("mapbox");
    expect(config.accessToken).toBe(PUBLIC);
    expect(config.styleUrl).toBe(DEFAULT_MAPBOX_STYLE_URL);
  });

  it("keeps the free map in development and tests, so they never bill, unless Mapbox is asked for", () => {
    for (const NODE_ENV of ["development", "test", undefined]) {
      expect(resolveMapConfig({ MAPBOX_API_KEY: PUBLIC, NODE_ENV }).provider).toBe("maplibre");
    }
    expect(resolveMapConfig({ MAPBOX_API_KEY: PUBLIC, NODE_ENV: "development", MAP_PROVIDER: "mapbox" }).provider).toBe("mapbox");
  });

  it("falls back to the free map when Mapbox is asked for but there is no valid token", () => {
    for (const MAPBOX_API_KEY of [undefined, "", "sk.secret.value", "garbage"]) {
      const config = resolveMapConfig({ MAP_PROVIDER: "mapbox", MAPBOX_API_KEY });
      expect(config.provider).toBe("maplibre");
      expect(config.accessToken).toBe("");
      expect(config.styleUrl).toBe(DEFAULT_STYLE_URL);
    }
  });

  it("keeps MapLibre when it is chosen, and never hands its pages a token", () => {
    const config = resolveMapConfig({ MAP_PROVIDER: "maplibre", MAPBOX_API_KEY: PUBLIC, NODE_ENV: "production" });
    expect(config.provider).toBe("maplibre");
    expect(config.accessToken).toBe("");
  });

  it("accepts a mapbox:// style only for Mapbox", () => {
    expect(resolveMapConfig({ MAPBOX_API_KEY: PUBLIC, MAP_PROVIDER: "mapbox", MAP_STYLE_URL: "mapbox://styles/mapbox/dark-v11" }).styleUrl).toBe("mapbox://styles/mapbox/dark-v11");
    expect(resolveMapConfig({ MAP_STYLE_URL: "mapbox://styles/mapbox/dark-v11" }).styleUrl).toBe(DEFAULT_STYLE_URL);
  });
});
