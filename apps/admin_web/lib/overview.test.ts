import { describe, expect, it } from "vitest";

import { firstName, greetingFor, niceMax, semesterProgress, shares, waitingAge, weekTrend, type DayCount } from "./overview";

const days = (values: number[]): DayCount[] => values.map((boardings, i) => ({ day: `2026-11-${String(i + 1).padStart(2, "0")}`, boardings }));

describe("niceMax", () => {
  it("rounds up to a tidy number", () => {
    expect(niceMax(0)).toBe(4);
    expect(niceMax(4)).toBe(4);
    expect(niceMax(7)).toBe(10);
    expect(niceMax(23)).toBe(25);
    expect(niceMax(26)).toBe(50);
    expect(niceMax(101)).toBe(200);
    expect(niceMax(Number.NaN)).toBe(4);
  });
});

describe("weekTrend", () => {
  it("compares the last seven days with the seven before", () => {
    const trend = weekTrend(days([...Array(7).fill(10), ...Array(7).fill(15)]));
    expect(trend).toEqual({ current: 105, previous: 70, change: 50 });
  });

  it("has no percentage without an earlier week", () => {
    expect(weekTrend(days([...Array(7).fill(0), ...Array(7).fill(3)])).change).toBeNull();
    expect(weekTrend(days([1, 2, 3])).previous).toBe(0);
  });

  it("reports a fall as negative", () => {
    expect(weekTrend(days([...Array(7).fill(10), ...Array(7).fill(5)])).change).toBe(-50);
  });
});

describe("shares", () => {
  it("adds up to 100", () => {
    expect(shares([1, 1, 1]).reduce((a, b) => a + b, 0)).toBe(100);
    expect(shares([2, 1, 0, 0])).toEqual([67, 33, 0, 0]);
  });

  it("is all zeros for nothing", () => {
    expect(shares([0, 0])).toEqual([0, 0]);
  });
});

describe("waitingAge", () => {
  const now = new Date("2026-11-04T12:00:00Z");
  it("uses hours under two days and days after", () => {
    expect(waitingAge("2026-11-04T09:30:00Z", now)).toEqual({ unit: "hours", value: 2 });
    expect(waitingAge("2026-11-02T13:00:00Z", now)).toEqual({ unit: "hours", value: 47 });
    expect(waitingAge("2026-10-30T12:00:00Z", now)).toEqual({ unit: "days", value: 5 });
  });

  it("never goes negative", () => {
    expect(waitingAge("2026-11-05T12:00:00Z", now)).toEqual({ unit: "hours", value: 0 });
  });
});

describe("semesterProgress", () => {
  it("counts days inclusively", () => {
    expect(semesterProgress("2026-09-01", "2026-09-10", "2026-09-01")).toEqual({ day: 1, total: 10, percent: 10 });
    expect(semesterProgress("2026-09-01", "2026-09-10", "2026-09-10")).toEqual({ day: 10, total: 10, percent: 100 });
  });

  it("clamps to the span", () => {
    expect(semesterProgress("2026-09-01", "2026-09-10", "2026-12-01").day).toBe(10);
    expect(semesterProgress("2026-09-01", "2026-09-10", "2026-08-01").day).toBe(1);
  });
});

describe("greetingFor", () => {
  it("follows the hour", () => {
    expect(greetingFor(0)).toBe("morning");
    expect(greetingFor(11)).toBe("morning");
    expect(greetingFor(12)).toBe("afternoon");
    expect(greetingFor(17)).toBe("afternoon");
    expect(greetingFor(18)).toBe("evening");
    expect(greetingFor(23)).toBe("evening");
  });
});

describe("firstName", () => {
  it("takes the first word", () => {
    expect(firstName("  Joel Fah ")).toBe("Joel");
    expect(firstName("")).toBe("");
  });
});
