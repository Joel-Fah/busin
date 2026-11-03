import { describe, expect, it } from "vitest";

import {
  addDays,
  addMonths,
  formatTime,
  inRange,
  joinDateTime,
  minuteOptions,
  monthGrid,
  parseIso,
  parseTime,
  splitDateTime,
  weekday,
} from "./calendar";

describe("parseIso", () => {
  it("accepts real dates only", () => {
    expect(parseIso("2026-11-02")).toEqual({ year: 2026, month: 11, day: 2 });
    expect(parseIso("2026-02-30")).toBeNull();
    expect(parseIso("2026-13-01")).toBeNull();
    expect(parseIso("02/11/2026")).toBeNull();
    expect(parseIso(undefined)).toBeNull();
  });

  it("knows leap years", () => {
    expect(parseIso("2028-02-29")).not.toBeNull();
    expect(parseIso("2027-02-29")).toBeNull();
  });
});

describe("addDays and addMonths", () => {
  it("crosses month and year ends", () => {
    expect(addDays("2026-12-31", 1)).toBe("2027-01-01");
    expect(addDays("2026-03-01", -1)).toBe("2026-02-28");
  });

  it("keeps the day, or the last day of a shorter month", () => {
    expect(addMonths("2026-01-31", 1)).toBe("2026-02-28");
    expect(addMonths("2028-01-31", 1)).toBe("2028-02-29");
    expect(addMonths("2026-12-15", 1)).toBe("2027-01-15");
    expect(addMonths("2026-01-15", -2)).toBe("2025-11-15");
  });
});

describe("monthGrid", () => {
  it("is always six full weeks", () => {
    expect(monthGrid(2026, 2, 1)).toHaveLength(42);
    expect(monthGrid(2026, 11, 0)).toHaveLength(42);
  });

  it("starts on the chosen weekday and contains the whole month", () => {
    const monday = monthGrid(2026, 11, 1);
    expect(weekday(monday[0])).toBe(1);
    const sunday = monthGrid(2026, 11, 0);
    expect(weekday(sunday[0])).toBe(0);
    for (const grid of [monday, sunday]) {
      expect(grid).toContain("2026-11-01");
      expect(grid).toContain("2026-11-30");
    }
  });

  it("starts exactly on the 1st when it falls on the first weekday", () => {
    expect(monthGrid(2026, 6, 1)[0]).toBe("2026-06-01");
  });
});

describe("inRange", () => {
  it("respects the bounds, inclusive", () => {
    expect(inRange("2026-11-05", "2026-11-05", "2026-11-10")).toBe(true);
    expect(inRange("2026-11-11", "2026-11-05", "2026-11-10")).toBe(false);
    expect(inRange("2026-11-04", "2026-11-05")).toBe(false);
    expect(inRange("2030-01-01")).toBe(true);
  });
});

describe("times", () => {
  it("parses and formats", () => {
    expect(parseTime("07:30")).toEqual({ hour: 7, minute: 30 });
    expect(parseTime("24:00")).toBeNull();
    expect(parseTime("7:30")).toBeNull();
    expect(formatTime(7, 5)).toBe("07:05");
  });

  it("offers minutes at a sensible step", () => {
    expect(minuteOptions(5)).toHaveLength(12);
    expect(minuteOptions(15)).toEqual([0, 15, 30, 45]);
    expect(minuteOptions(7)).toHaveLength(12);
    expect(minuteOptions(1)).toHaveLength(60);
  });

  it("joins and splits a date and time", () => {
    expect(joinDateTime("2026-11-02", "07:30")).toBe("2026-11-02T07:30");
    expect(joinDateTime("", "07:30")).toBe("");
    expect(joinDateTime("2026-11-02", "")).toBe("");
    expect(splitDateTime("2026-11-02T07:30")).toEqual({ date: "2026-11-02", time: "07:30" });
    expect(splitDateTime("")).toEqual({ date: "", time: "" });
  });
});
