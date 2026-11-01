import { describe, expect, it } from "vitest";

import { MAX_STOP_NAME_LENGTH, parseCoordinate, parseStopForm, stopSaveErrorKey } from "./stops";

function form(values: Record<string, string>) {
  return { get: (name: string) => values[name] ?? null };
}

describe("parseCoordinate", () => {
  it("reads decimals, negatives and a comma as the decimal mark", () => {
    expect(parseCoordinate("3.848")).toBe(3.848);
    expect(parseCoordinate(" -11.5021 ")).toBe(-11.5021);
    expect(parseCoordinate("3,848")).toBe(3.848);
    expect(parseCoordinate("7")).toBe(7);
  });

  it("refuses anything that is not a plain number", () => {
    for (const bad of ["", " ", "abc", "1e3", "1.2.3", "--1", "3.", ".5", "NaN", "Infinity"]) {
      expect(parseCoordinate(bad), bad).toBeNull();
    }
    expect(parseCoordinate(null)).toBeNull();
    expect(parseCoordinate(5)).toBeNull();
  });
});

describe("parseStopForm", () => {
  it("accepts a valid stop and tidies the name", () => {
    const result = parseStopForm(form({ name: "  Carrefour   Obili ", lat: "3.85", lng: "11.5", active: "on" }));
    expect(result).toEqual({
      ok: true,
      value: { name: "Carrefour Obili", position: { lat: 3.85, lng: 11.5 }, active: true },
    });
  });

  it("treats a missing checkbox as inactive", () => {
    const result = parseStopForm(form({ name: "Mendong", lat: "3.8", lng: "11.4" }));
    expect(result).toMatchObject({ ok: true, value: { active: false } });
  });

  it("refuses an empty or too long name", () => {
    expect(parseStopForm(form({ name: "   ", lat: "3", lng: "11" }))).toEqual({ ok: false, error: "name" });
    expect(parseStopForm(form({ lat: "3", lng: "11" }))).toEqual({ ok: false, error: "name" });
    expect(parseStopForm(form({ name: "x".repeat(MAX_STOP_NAME_LENGTH + 1), lat: "3", lng: "11" }))).toEqual({
      ok: false,
      error: "name",
    });
    expect(parseStopForm(form({ name: "x".repeat(MAX_STOP_NAME_LENGTH), lat: "3", lng: "11" })).ok).toBe(true);
  });

  it("refuses a missing, malformed or out of range position", () => {
    for (const [lat, lng] of [["", "11"], ["3", ""], ["abc", "11"], ["91", "11"], ["3", "181"], ["-91", "0"]]) {
      expect(parseStopForm(form({ name: "Stop", lat, lng })), `${lat},${lng}`).toEqual({
        ok: false,
        error: "location",
      });
    }
  });
});

describe("stopSaveErrorKey", () => {
  it("maps the database error codes", () => {
    expect(stopSaveErrorKey("23505")).toBe("name_taken");
    expect(stopSaveErrorKey("23514")).toBe("invalid");
    expect(stopSaveErrorKey("PGRST116")).toBe("not_found");
    expect(stopSaveErrorKey("42501")).toBe("generic");
    expect(stopSaveErrorKey(undefined)).toBe("generic");
  });
});
