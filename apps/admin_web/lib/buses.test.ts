import { describe, expect, it } from "vitest";

import { busLabel, busSaveErrorKey, isBusDone, isBusFormErrorKey, normalizeName, normalizePlate, parseBusForm } from "./buses";

function form(values: Record<string, string>) {
  return { get: (name: string) => values[name] ?? null };
}

describe("normalizePlate", () => {
  it("trims, collapses spaces and uses capitals", () => {
    expect(normalizePlate("  lt 123   ab ")).toBe("LT 123 AB");
    expect(normalizePlate(undefined)).toBe("");
  });
});

describe("bus names", () => {
  it("trims a name and treats an empty one as no name", () => {
    expect(normalizeName("  Blue   Line ")).toBe("Blue Line");
    expect(normalizeName("   ")).toBeNull();
    expect(normalizeName(undefined)).toBeNull();
  });

  it("shows the name when there is one, otherwise the plate", () => {
    expect(busLabel({ name: "Blue Line", plate: "LT 1" })).toBe("Blue Line");
    expect(busLabel({ name: null, plate: "LT 1" })).toBe("LT 1");
    expect(busLabel({ name: "  ", plate: "LT 1" })).toBe("LT 1");
    expect(busLabel({ plate: "LT 1" })).toBe("LT 1");
  });

  it("reads the name from the form and refuses a long one", () => {
    const named = parseBusForm(form({ plate: "LT 1", name: " Blue Line ", capacity: "30" }));
    expect(named.ok && named.value.name).toBe("Blue Line");
    expect(parseBusForm(form({ plate: "LT 1", name: "x".repeat(41), capacity: "30" }))).toEqual({ ok: false, error: "name" });
  });

  it("tells a taken name from a taken plate", () => {
    expect(busSaveErrorKey("23505", 'duplicate key value violates unique constraint "buses_school_name_key"')).toBe("name_taken");
    expect(busSaveErrorKey("23505", 'duplicate key value violates unique constraint "buses_school_id_plate_key"')).toBe("plate_taken");
    expect(isBusFormErrorKey("name_taken")).toBe(true);
  });
});

describe("parseBusForm", () => {
  it("accepts a valid form and reads the checkbox", () => {
    expect(parseBusForm(form({ plate: "lt 123 ab", capacity: "60", in_service: "on" }))).toEqual({
      ok: true,
      value: { plate: "LT 123 AB", name: null, capacity: 60, inService: true },
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
