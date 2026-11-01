import { describe, expect, it } from "vitest";

import { busSaveErrorKey, isBusDone, isBusFormErrorKey, normalizePlate, parseBusForm } from "./buses";

function form(values: Record<string, string>) {
  return { get: (name: string) => values[name] ?? null };
}

describe("normalizePlate", () => {
  it("trims, collapses spaces and uses capitals", () => {
    expect(normalizePlate("  lt 123   ab ")).toBe("LT 123 AB");
    expect(normalizePlate(undefined)).toBe("");
  });
});

describe("parseBusForm", () => {
  it("accepts a valid form and reads the checkbox", () => {
    expect(parseBusForm(form({ plate: "lt 123 ab", capacity: "60", in_service: "on" }))).toEqual({
      ok: true,
      value: { plate: "LT 123 AB", capacity: 60, inService: true },
    });
    const off = parseBusForm(form({ plate: "LT 1", capacity: "30" }));
    expect(off.ok && off.value.inService).toBe(false);
  });

  it("rejects an empty or long plate", () => {
    expect(parseBusForm(form({ plate: "  ", capacity: "10" }))).toEqual({ ok: false, error: "plate" });
    expect(parseBusForm(form({ plate: "X".repeat(21), capacity: "10" }))).toEqual({ ok: false, error: "plate" });
  });

  it("rejects bad seat counts", () => {
    for (const capacity of ["", "0", "-5", "201", "12.5", "abc", "1e2"]) {
      expect(parseBusForm(form({ plate: "LT 1", capacity }))).toEqual({ ok: false, error: "capacity" });
    }
  });
});

describe("guards and error codes", () => {
  it("maps database codes", () => {
    expect(busSaveErrorKey("23505")).toBe("plate_taken");
    expect(busSaveErrorKey("23514")).toBe("invalid");
    expect(busSaveErrorKey("PGRST116")).toBe("not_found");
    expect(busSaveErrorKey("42501")).toBe("generic");
  });

  it("recognises only known query values", () => {
    expect(isBusFormErrorKey("plate_taken")).toBe(true);
    expect(isBusFormErrorKey("x")).toBe(false);
    expect(isBusDone("saved")).toBe(true);
    expect(isBusDone("deleted")).toBe(false);
  });
});
