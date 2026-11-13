import { describe, expect, it } from "vitest";

import type { StopLoad, StopLoads } from "./insights";
import { graphIsEmpty, loadIsEmpty, proximityIsEmpty, suggestionsAreEmpty } from "./insights-empty";
import type { Proximity, ProximityStop } from "./proximity";

const stop = (over: Partial<StopLoad> = {}): StopLoad => ({
  id: "s1", name: "Stop", active: true, position: null, load: null, level: null, departures: 0, boardings: 0,
  perDeparture: 0, peak: 0, peakLoad: 0, lastDay: null, students: 0, ...over,
});
const loads = (stops: StopLoad[]): StopLoads => ({ basis: "subscribers", stops, refreshedAt: null, seats: 0 });
const near = (median: number | null) => ({ id: "s1", name: "Stop", position: null, subscribers: 0, withArea: 0, median, reach: null, bands: null }) as unknown as ProximityStop;
const proximity = (stops: ProximityStop[]) => ({ stops, lines: [], nearerLines: [], subscribers: 0 }) as unknown as Proximity;

describe("when Insights has nothing to show yet", () => {
  it("stop load is empty while no stop has a boarding or a subscriber", () => {
    expect(loadIsEmpty(loads([stop(), stop({ id: "s2" })]))).toBe(true);
    expect(loadIsEmpty(loads([stop(), stop({ students: 2 })]))).toBe(false);
    expect(loadIsEmpty(loads([stop({ boardings: 1 })]))).toBe(false);
    expect(loadIsEmpty(loads([]))).toBe(true);
  });

  it("proximity is empty while no stop has enough students with an area", () => {
    expect(proximityIsEmpty(proximity([near(null), near(null)]))).toBe(true);
    expect(proximityIsEmpty(proximity([near(null), near(640)]))).toBe(false);
  });

  it("the graph is empty only while both are, suggestions while there are none", () => {
    expect(graphIsEmpty(loads([stop()]), proximity([near(null)]))).toBe(true);
    expect(graphIsEmpty(loads([stop({ students: 1 })]), proximity([near(null)]))).toBe(false);
    expect(suggestionsAreEmpty([])).toBe(true);
  });
});
