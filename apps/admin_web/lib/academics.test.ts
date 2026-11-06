import { describe, expect, it } from "vitest";

import { isUnitDoneKey, isUnitErrorKey, parseUnitForm, unitSaveErrorKey } from "./academics";

const form = (values: Record<string, string>) => ({ get: (k: string) => values[k] ?? null });

describe("parseUnitForm", () => {
  it("trims, squeezes spaces and turns an empty code into null", () => {
    expect(parseUnitForm(form({ name: "  Computer   Science ", code: " " }))).toEqual({ ok: true, value: { name: "Computer Science", code: null } });
  });
  it("keeps a code", () => {
    expect(parseUnitForm(form({ name: "Cybersecurity", code: "CYS" }))).toEqual({ ok: true, value: { name: "Cybersecurity", code: "CYS" } });
  });
  it("refuses a name that is missing, too short or too long", () => {
    expect(parseUnitForm(form({}))).toEqual({ ok: false, error: "name" });
    expect(parseUnitForm(form({ name: "A" }))).toEqual({ ok: false, error: "name" });
    expect(parseUnitForm(form({ name: "x".repeat(121) }))).toEqual({ ok: false, error: "name" });
  });
  it("refuses a code that is too long", () => {
    expect(parseUnitForm(form({ name: "Computer Science", code: "ABCDEFGHIJKLM" }))).toEqual({ ok: false, error: "code" });
  });
});

describe("error and done keys", () => {
  it("maps database codes", () => {
    expect(unitSaveErrorKey("23505")).toBe("taken");
    expect(unitSaveErrorKey("23503")).toBe("in_use");
    expect(unitSaveErrorKey("PGRST116")).toBe("not_found");
    expect(unitSaveErrorKey(undefined)).toBe("generic");
  });
  it("only accepts known keys from the address", () => {
    expect(isUnitErrorKey("taken")).toBe(true);
    expect(isUnitErrorKey("<script>")).toBe(false);
    expect(isUnitDoneKey("faculty_added")).toBe(true);
    expect(isUnitDoneKey("nope")).toBe(false);
  });
});
