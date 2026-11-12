import { describe, expect, it } from "vitest";

import { buildStopLoads, circleSize, formatAverage, formatShare, loadLevel, parseInsightView, parseLoadPeriod, type LoadStop, type StopLoadRow } from "./insights";

const stop = (id: string, name: string, students = 0): LoadStop => ({ id, name, active: true, position: { lat: 3.8, lng: 11.5 }, students });
const row = (stop_id: string, load: number, refreshed_at = "2026-11-10T01:30:00Z"): StopLoadRow => ({
  stop_id,
  departures: 4,
  boardings: 20,
  per_departure: 5,
  peak: 8,
  load,
  peak_load: load * 1.5,
  last_day: "2026-11-10",
  refreshed_at,
});

describe("loadLevel", () => {
  it("reads the share of the seats in four steps", () => {
    expect(loadLevel(0)).toBe("quiet");
    expect(loadLevel(0.249)).toBe("quiet");
    expect(loadLevel(0.25)).toBe("fair");
    expect(loadLevel(0.5)).toBe("busy");
    expect(loadLevel(0.8)).toBe("full");
    expect(loadLevel(1.3)).toBe("full");
  });
});

describe("parseInsightView", () => {
  it("knows the proximity view and falls back to the load", () => {
    expect(parseInsightView("proximity")).toBe("proximity");
    expect(parseInsightView(["proximity"])).toBe("proximity");
    expect(parseInsightView("load")).toBe("load");
    expect(parseInsightView("graph")).toBe("graph");
    expect(parseInsightView("suggestions")).toBe("suggestions");
    expect(parseInsightView("other")).toBe("load");
    expect(parseInsightView(undefined)).toBe("load");
  });
});

describe("parseLoadPeriod", () => {
  it("accepts only the offered periods", () => {
    expect(parseLoadPeriod("28")).toBe(28);
    expect(parseLoadPeriod(["112", "28"])).toBe(112);
    expect(parseLoadPeriod("30")).toBe(56);
    expect(parseLoadPeriod(undefined)).toBe(56);
    expect(parseLoadPeriod("abc")).toBe(56);
  });
});

describe("buildStopLoads", () => {
  it("uses boardings when any were counted, fullest first, a stop without a row at zero", () => {
    const result = buildStopLoads([stop("a", "Alpha"), stop("b", "Beta"), stop("c", "Gamma")], [row("a", 0.2), row("c", 0.9, "2026-11-11T01:30:00Z")], 100);
    expect(result.basis).toBe("boardings");
    expect(result.stops.map((s) => [s.id, s.level])).toEqual([
      ["c", "full"],
      ["a", "quiet"],
      ["b", "quiet"],
    ]);
    expect(result.stops[2]).toMatchObject({ load: 0, departures: 0, lastDay: null });
    expect(result.refreshedAt).toBe("2026-11-11T01:30:00Z");
  });

  it("falls back to subscribers against the seats before any boarding", () => {
    const result = buildStopLoads([stop("a", "Alpha", 10), stop("b", "Beta", 30)], [], 80);
    expect(result.basis).toBe("subscribers");
    expect(result.stops.map((s) => [s.id, s.load])).toEqual([
      ["b", 30 / 80],
      ["a", 10 / 80],
    ]);
    expect(result.refreshedAt).toBeNull();
  });

  it("says nothing without seats, and keeps the order by name", () => {
    const result = buildStopLoads([stop("b", "Beta", 3), stop("a", "Alpha", 5)], [], 0);
    expect(result.stops.map((s) => [s.name, s.load, s.level])).toEqual([
      ["Alpha", null, null],
      ["Beta", null, null],
    ]);
  });
});

describe("formatting", () => {
  it("shows shares as whole percents and averages with one decimal", () => {
    expect(formatShare(0.625)).toBe("63%");
    expect(formatShare(1.2)).toBe("120%");
    expect(formatAverage(3.46)).toBe("3.5");
    expect(formatAverage(4)).toBe("4");
  });

  it("sizes circles by area and caps them at a full bus", () => {
    expect(circleSize(null)).toBe(0);
    expect(circleSize(0)).toBe(0);
    expect(circleSize(0.25)).toBe(0.5);
    expect(circleSize(2)).toBe(1);
  });
});
