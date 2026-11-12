import { describe, expect, it } from "vitest";

import {
  isIsoDate,
  isSemesterDone,
  isSemesterFormErrorKey,
  isSemesterName,
  parseSemesterForm,
  semesterPhase,
  semesterSaveErrorKey,
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

describe("a semester in the past", () => {
  const today = "2026-11-12";

  it("is refused when its last day is before the school's today, and the one running or ahead is allowed", () => {
    expect(parseSemesterForm(form({ ...valid, start_date: "2026-01-01", end_date: "2026-06-30" }), { today })).toEqual({ ok: false, error: "end_past" });
    expect(parseSemesterForm(form({ ...valid, start_date: "2026-09-01", end_date: "2026-11-11" }), { today })).toEqual({ ok: false, error: "end_past" });
    expect(parseSemesterForm(form({ ...valid, start_date: "2026-09-01", end_date: "2026-11-12" }), { today })).toMatchObject({ ok: true });
    expect(parseSemesterForm(form({ ...valid, start_date: "2026-09-01", end_date: "2027-01-31" }), { today })).toMatchObject({ ok: true });
  });

  it("lets an old semester be edited when both dates are left as they were", () => {
    const old = { startDate: "2026-01-01", endDate: "2026-06-30" };
    const edited = form({ ...valid, year: "2026", start_date: old.startDate, end_date: old.endDate });
    expect(parseSemesterForm(edited, { today, unchanged: old })).toMatchObject({ ok: true });
    expect(parseSemesterForm(form({ ...valid, start_date: "2026-01-02", end_date: old.endDate }), { today, unchanged: old })).toEqual({ ok: false, error: "end_past" });
  });

  it("is not checked without a today (the database repeats the rule anyway)", () => {
    expect(parseSemesterForm(form({ ...valid, year: "2020", start_date: "2020-01-01", end_date: "2020-06-30" }))).toMatchObject({ ok: true });
  });

  it("is recognised from the database's reason", () => {
    expect(semesterSaveErrorKey("22023", "semester_in_past")).toBe("end_past");
    expect(semesterSaveErrorKey("22023", "something else")).toBe("generic");
  });
});

describe("a semester's length and year", () => {
  const today = "2026-11-12";

  it("must last 7 to 366 days: a five-year semester is refused (the case that was in the portal)", () => {
    expect(parseSemesterForm(form({ ...valid, year: "2021", start_date: "2021-02-04", end_date: "2026-04-04" }))).toEqual({ ok: false, error: "span" });
    expect(parseSemesterForm(form({ ...valid, start_date: "2026-09-01", end_date: "2026-09-05" }))).toEqual({ ok: false, error: "span" });
    expect(parseSemesterForm(form({ ...valid, start_date: "2026-09-01", end_date: "2026-09-08" }))).toMatchObject({ ok: true });
    expect(parseSemesterForm(form({ ...valid, start_date: "2026-09-01", end_date: "2027-09-02" }))).toMatchObject({ ok: true });
    expect(parseSemesterForm(form({ ...valid, start_date: "2026-09-01", end_date: "2027-09-03" }))).toEqual({ ok: false, error: "span" });
  });

  it("must have the year it starts or ends in", () => {
    expect(parseSemesterForm(form({ ...valid, year: "2030", start_date: "2026-09-01", end_date: "2027-01-31" }))).toEqual({ ok: false, error: "year_dates" });
    expect(parseSemesterForm(form({ ...valid, year: "2026", start_date: "2026-09-01", end_date: "2027-01-31" }))).toMatchObject({ ok: true });
    expect(parseSemesterForm(form({ ...valid, year: "2027", start_date: "2026-09-01", end_date: "2027-01-31" }))).toMatchObject({ ok: true });
  });

  it("is left alone when an old row is edited with its dates and year unchanged", () => {
    const old = { startDate: "2021-02-04", endDate: "2026-04-04", year: 2021 };
    const same = form({ ...valid, name: "summer", year: "2021", start_date: old.startDate, end_date: old.endDate });
    expect(parseSemesterForm(same, { today, unchanged: old })).toMatchObject({ ok: true });
    expect(parseSemesterForm(form({ ...valid, year: "2030", start_date: old.startDate, end_date: old.endDate }), { today, unchanged: old })).toEqual({ ok: false, error: "year_dates" });
  });

  it("is recognised from the database's reasons", () => {
    expect(semesterSaveErrorKey("22023", "semester_length")).toBe("span");
    expect(semesterSaveErrorKey("22023", "semester_year")).toBe("year_dates");
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
});
