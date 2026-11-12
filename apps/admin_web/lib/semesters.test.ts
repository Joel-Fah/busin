import { describe, expect, it } from "vitest";

import {
  isIsoDate,
  isSemesterDone,
  isSemesterFormErrorKey,
  isSemesterName,
  parseSemesterForm,
  semesterPhase,
  semesterSaveErrorKey,
  todayIso,
} from "./semesters";

function form(values: Record<string, string>) {
  return { get: (name: string) => values[name] ?? null };
}

const valid = { name: "fall", year: "2026", start_date: "2026-09-01", end_date: "2026-12-20" };

describe("isIsoDate", () => {
  it("accepts real dates only", () => {
    expect(isIsoDate("2026-09-01")).toBe(true);
    expect(isIsoDate("2028-02-29")).toBe(true);
    expect(isIsoDate("2026-02-29")).toBe(false);
    expect(isIsoDate("2026-13-01")).toBe(false);
    expect(isIsoDate("01/09/2026")).toBe(false);
    expect(isIsoDate("")).toBe(false);
    expect(isIsoDate(null)).toBe(false);
  });
});

describe("isSemesterName", () => {
  it("accepts the three names", () => {
    expect(isSemesterName("fall")).toBe(true);
    expect(isSemesterName("spring")).toBe(true);
    expect(isSemesterName("summer")).toBe(true);
    expect(isSemesterName("winter")).toBe(false);
    expect(isSemesterName(undefined)).toBe(false);
  });
});

describe("parseSemesterForm", () => {
  it("accepts a valid form", () => {
    expect(parseSemesterForm(form(valid))).toEqual({
      ok: true,
      value: { name: "fall", year: 2026, startDate: "2026-09-01", endDate: "2026-12-20" },
    });
  });

  it("rejects an unknown name", () => {
    expect(parseSemesterForm(form({ ...valid, name: "winter" }))).toEqual({ ok: false, error: "name" });
  });

  it("rejects years that are not four digits or are out of range", () => {
    for (const year of ["", "26", "1999", "2101", "20x6", "2026.5"]) {
      expect(parseSemesterForm(form({ ...valid, year }))).toEqual({ ok: false, error: "year" });
    }
  });

  it("rejects bad dates", () => {
    expect(parseSemesterForm(form({ ...valid, start_date: "" }))).toEqual({ ok: false, error: "start_date" });
    expect(parseSemesterForm(form({ ...valid, end_date: "2026-02-30" }))).toEqual({ ok: false, error: "end_date" });
  });

  it("requires the end to be after the start", () => {
    expect(parseSemesterForm(form({ ...valid, end_date: "2026-09-01" }))).toEqual({ ok: false, error: "date_order" });
    expect(parseSemesterForm(form({ ...valid, end_date: "2026-08-01" }))).toEqual({ ok: false, error: "date_order" });
  });
});

describe("semesterSaveErrorKey", () => {
  it("maps database codes", () => {
    expect(semesterSaveErrorKey("23505")).toBe("taken");
    expect(semesterSaveErrorKey("23514")).toBe("invalid");
    expect(semesterSaveErrorKey("PGRST116")).toBe("not_found");
    expect(semesterSaveErrorKey("42501")).toBe("generic");
    expect(semesterSaveErrorKey(undefined)).toBe("generic");
  });
});

describe("query parameter guards", () => {
  it("recognises only known keys", () => {
    expect(isSemesterFormErrorKey("date_order")).toBe(true);
    expect(isSemesterFormErrorKey("taken")).toBe(true);
    expect(isSemesterFormErrorKey("<script>")).toBe(false);
    expect(isSemesterFormErrorKey(undefined)).toBe(false);
    expect(isSemesterDone("created")).toBe(true);
    expect(isSemesterDone("deleted")).toBe(false);
  });
});

describe("semesterPhase", () => {
  it("places today relative to the semester", () => {
    expect(semesterPhase("2026-09-01", "2026-12-20", "2026-08-31")).toBe("upcoming");
    expect(semesterPhase("2026-09-01", "2026-12-20", "2026-09-01")).toBe("current");
    expect(semesterPhase("2026-09-01", "2026-12-20", "2026-12-20")).toBe("current");
    expect(semesterPhase("2026-09-01", "2026-12-20", "2026-12-21")).toBe("past");
  });

  it("formats today", () => {
    expect(todayIso(new Date("2026-11-01T23:30:00Z"))).toBe("2026-11-01");
  });
});
