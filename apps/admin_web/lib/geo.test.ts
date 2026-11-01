import { describe, expect, it } from "vitest";

import { centroid, formatLatLng, isValidLatLng, parsePoint, toEwkt } from "./geo";

/** Builds the hex form of a point the way PostGIS writes it. */
function ewkbHex(opts: { lng: number; lat: number; little?: boolean; srid?: number | null; baseType?: number }): string {
  const { lng, lat, little = true, srid = 4326, baseType = 1 } = opts;
  const type = srid === null ? baseType : (baseType | 0x20000000) >>> 0;
  const size = 1 + 4 + (srid === null ? 0 : 4) + 16;
  const view = new DataView(new ArrayBuffer(size));
  let offset = 0;
  view.setUint8(offset++, little ? 1 : 0);
  view.setUint32(offset, type, little);
  offset += 4;
  if (srid !== null) {
    view.setUint32(offset, srid, little);
    offset += 4;
  }
  view.setFloat64(offset, lng, little);
  view.setFloat64(offset + 8, lat, little);
  return Array.from(new Uint8Array(view.buffer), (b) => b.toString(16).padStart(2, "0")).join("").toUpperCase();
}

describe("parsePoint", () => {
  it("reads the real values the local backend returns", () => {
    expect(parsePoint("0101000020E6100000A9A44E401301274062105839B4C80E40")).toEqual({ lat: 3.848, lng: 11.5021 });
    const probe = parsePoint("0101000020E610000085EB51B81E052740E17A14AE47E10E40");
    expect(probe?.lng).toBeCloseTo(11.51, 9);
    expect(probe?.lat).toBeCloseTo(3.86, 9);
  });

  it("reads either byte order, with or without the SRID", () => {
    for (const little of [true, false]) {
      for (const srid of [4326, null]) {
        expect(parsePoint(ewkbHex({ lng: -122.4194, lat: 37.7749, little, srid }))).toEqual({
          lat: 37.7749,
          lng: -122.4194,
        });
      }
    }
  });

  it("reads lower case hex, WKT and GeoJSON", () => {
    expect(parsePoint(ewkbHex({ lng: 11.5, lat: 3.85 }).toLowerCase())).toEqual({ lat: 3.85, lng: 11.5 });
    expect(parsePoint("SRID=4326;POINT(11.5 3.85)")).toEqual({ lat: 3.85, lng: 11.5 });
    expect(parsePoint({ type: "Point", coordinates: [11.5, 3.85] })).toEqual({ lat: 3.85, lng: 11.5 });
  });

  it("returns null for anything it cannot trust", () => {
    expect(parsePoint(ewkbHex({ lng: 11.5, lat: 3.85, srid: 3857 }))).toBeNull();
    expect(parsePoint(ewkbHex({ lng: 11.5, lat: 3.85, baseType: 2 }))).toBeNull();
    expect(parsePoint(ewkbHex({ lng: 200, lat: 3.85 }))).toBeNull();
    const full = ewkbHex({ lng: 11.5, lat: 3.85 });
    expect(parsePoint(full.slice(0, -2))).toBeNull();
    expect(parsePoint("not a point")).toBeNull();
    expect(parsePoint(null)).toBeNull();
    expect(parsePoint(42)).toBeNull();
    expect(parsePoint({ type: "Line", coordinates: [] })).toBeNull();
  });
});

describe("toEwkt", () => {
  it("puts longitude first and uses seven decimals", () => {
    expect(toEwkt({ lat: 3.848, lng: 11.5021 })).toBe("SRID=4326;POINT(11.5021000 3.8480000)");
  });

  it("round-trips through parsePoint", () => {
    const point = { lat: -33.8688, lng: 151.2093 };
    const back = parsePoint(toEwkt(point));
    expect(back?.lat).toBeCloseTo(point.lat, 6);
    expect(back?.lng).toBeCloseTo(point.lng, 6);
  });
});

describe("isValidLatLng", () => {
  it("accepts the edges and refuses out of range or non-numbers", () => {
    expect(isValidLatLng(90, 180)).toBe(true);
    expect(isValidLatLng(-90, -180)).toBe(true);
    expect(isValidLatLng(90.0001, 0)).toBe(false);
    expect(isValidLatLng(0, 180.5)).toBe(false);
    expect(isValidLatLng(Number.NaN, 0)).toBe(false);
    expect(isValidLatLng(0, Number.POSITIVE_INFINITY)).toBe(false);
  });
});

describe("centroid and formatLatLng", () => {
  it("averages positions and handles an empty list", () => {
    expect(centroid([])).toBeNull();
    expect(centroid([{ lat: 2, lng: 10 }, { lat: 4, lng: 12 }])).toEqual({ lat: 3, lng: 11 });
  });

  it("formats with five decimals", () => {
    expect(formatLatLng({ lat: 3.848, lng: 11.5021 })).toBe("3.84800, 11.50210");
  });
});
