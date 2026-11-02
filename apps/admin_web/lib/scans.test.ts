import { describe, expect, it } from "vitest";

import { dayBounds, parseScanFilters, scansHref } from "./scans";

const ID = "a1000000-0000-4000-8000-000000000001";
const OTHER = "a1000000-0000-4000-8000-000000000002";

describe("parseScanFilters", () => {
  it("reads valid filters", () => {
    expect(parseScanFilters({ trip: ID, stop: OTHER, date: "2026-11-02" })).toEqual({
      trip: ID,
      stop: OTHER,
      date: "2026-11-02",
    });
  });

  it("treats malformed values as no filter", () => {
    expect(parseScanFilters({ trip: "x", stop: "'; drop", date: "2026-02-30" })).toEqual({
      trip: null,
      stop: null,
      date: null,
    });
    expect(parseScanFilters({})).toEqual({ trip: null, stop: null, date: null });
  });

  it("uses the first value of a repeated parameter", () => {
    expect(parseScanFilters({ trip: [ID, OTHER] }).trip).toBe(ID);
  });
});

describe("dayBounds", () => {
  it("covers the calendar day in the school timezone", () => {
    // Douala is UTC+1, so its day starts at 23:00 UTC the evening before.
    expect(dayBounds("2026-11-02", "Africa/Douala")).toEqual({
      from: "2026-11-01T23:00:00.000Z",
      to: "2026-11-02T23:00:00.000Z",
    });
  });

  it("handles a month end", () => {
    expect(dayBounds("2026-11-30", "UTC")).toEqual({ from: "2026-11-30T00:00:00.000Z", to: "2026-12-01T00:00:00.000Z" });
  });

  it("handles a daylight saving change day", () => {
    const bounds = dayBounds("2026-03-29", "Europe/Paris");
    expect(bounds.from).toBe("2026-03-28T23:00:00.000Z");
    // The day is 23 hours long when the clocks go forward.
    expect(bounds.to).toBe("2026-03-29T22:00:00.000Z");
  });
});

describe("scansHref", () => {
  it("leaves out empty filters and the first page", () => {
    expect(scansHref({ trip: null, stop: null, date: null })).toBe("/scans");
    expect(scansHref({ trip: ID, stop: null, date: "2026-11-02" }, 3)).toBe(`/scans?trip=${ID}&date=2026-11-02&page=3`);
  });
});
