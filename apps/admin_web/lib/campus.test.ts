import { describe, expect, it } from "vitest";

import { checkCampus, coordinateFields, parseCampusFields, parseCampusPoint } from "./campus";

describe("checkCampus", () => {
  it("accepts a point and tidies the name", () => {
    expect(checkCampus(3.915, 11.515, "  Main   campus ")).toEqual({ ok: true, value: { name: "Main campus", position: { lat: 3.915, lng: 11.515 } } });
  });

  it("refuses a point off the map or beyond what the database takes", () => {
    expect(checkCampus(91, 11, "Campus")).toEqual({ ok: false, error: "invalid_point" });
    expect(checkCampus(86, 11, "Campus")).toEqual({ ok: false, error: "invalid_point" });
    expect(checkCampus(3, 181, "Campus")).toEqual({ ok: false, error: "invalid_point" });
    expect(checkCampus(Number.NaN, 11, "Campus")).toEqual({ ok: false, error: "invalid_point" });
  });

  it("needs a name of 1 to 80 characters", () => {
    expect(checkCampus(3, 11, "   ")).toEqual({ ok: false, error: "invalid_name" });
    expect(checkCampus(3, 11, "x".repeat(81))).toEqual({ ok: false, error: "invalid_name" });
    expect(checkCampus(3, 11, "x".repeat(80)).ok).toBe(true);
  });
});

describe("parseCampusPoint", () => {
  it("reads typed coordinates, with a comma as the decimal mark", () => {
    expect(parseCampusPoint({ lat: "3,915", lng: " 11.515 " })).toEqual({ lat: 3.915, lng: 11.515 });
  });

  it("is null for empty, partial or out-of-range coordinates", () => {
    expect(parseCampusPoint({ lat: "", lng: "" })).toBeNull();
    expect(parseCampusPoint({ lat: "3.9", lng: "" })).toBeNull();
    expect(parseCampusPoint({ lat: "abc", lng: "11" })).toBeNull();
    expect(parseCampusPoint({ lat: "89", lng: "11" })).toBeNull();
  });
});

describe("parseCampusFields", () => {
  it("names the point problem before the name", () => {
    expect(parseCampusFields({ lat: "", lng: "", name: "" })).toEqual({ ok: false, error: "invalid_point" });
    expect(parseCampusFields({ lat: "3.9", lng: "11.5", name: "" })).toEqual({ ok: false, error: "invalid_name" });
    expect(parseCampusFields({ lat: "3.9", lng: "11.5", name: "Campus" })).toEqual({ ok: true, value: { name: "Campus", position: { lat: 3.9, lng: 11.5 } } });
  });
});

describe("coordinateFields", () => {
  it("writes six decimals, or empty fields when there is no point", () => {
    expect(coordinateFields({ lat: 3.9151234567, lng: 11.5 })).toEqual({ lat: "3.915123", lng: "11.500000" });
    expect(coordinateFields(null)).toEqual({ lat: "", lng: "" });
  });
});
