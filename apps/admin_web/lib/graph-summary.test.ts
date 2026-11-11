import { describe, expect, it } from "vitest";

import { graphFacts } from "./graph-summary";
import type { StopLoads } from "./insights";
import type { Proximity, ProximityStop } from "./proximity";

const loadStop = (name: string, load: number | null, level: StopLoads["stops"][number]["level"]): StopLoads["stops"][number] => ({
  id: name,
  name,
  active: true,
  position: null,
  load,
  level,
  departures: 0,
  boardings: 0,
  perDeparture: 0,
  peak: 0,
  peakLoad: 0,
  lastDay: null,
  students: 0,
});
const proxStop = (name: string, median: number | null, nearer: ProximityStop["nearer"] = []): ProximityStop => ({
  id: name,
  name,
  position: null,
  subscribers: 6,
  withArea: median === null ? 2 : 6,
  median,
  reach: null,
  bands: null,
  overOneKm: null,
  nearer,
});
const proximity = (stops: ProximityStop[]): Proximity => ({ stops, lines: [], nearerLines: [], subscribers: 30, withArea: 20 });
const loads = (stops: StopLoads["stops"]): StopLoads => ({ basis: "boardings", stops, refreshedAt: null, seats: 100 });

describe("graphFacts", () => {
  it("says what matters: the fullest stop, the farthest students, nearer groups, suggestions and thin data", () => {
    const facts = graphFacts(
      loads([loadStop("Mvan", 0.9, "full"), loadStop("Etoudi", 0.1, "quiet")]),
      proximity([proxStop("Mvan", 2400, [{ toId: "e", toName: "Ekounou", students: 5, saved: 2300 }]), proxStop("Etoudi", 600), proxStop("Bastos", null)]),
      [{ kind: "new_stop", id: "n", place: "Market", position: { lat: 0, lng: 0 }, students: 8, metres: 1100 }],
    );
    expect(facts).toEqual([
      { kind: "stops", stops: 3, subscribers: 30, withArea: 20 },
      { kind: "fullest", stop: "Mvan", level: "full", share: 0.9 },
      { kind: "farthest", stop: "Mvan", metres: 2400 },
      { kind: "nearer", groups: 1, students: 5, from: "Mvan", to: "Ekounou" },
      { kind: "suggested", count: 1, first: "Market" },
      { kind: "notEnough", stops: 1 },
    ]);
  });

  it("says when no stop crowds the bus, and leaves out what is not worth saying", () => {
    const facts = graphFacts(loads([loadStop("A", 0.2, "quiet")]), proximity([proxStop("A", 400)]), []);
    expect(facts.map((f) => f.kind)).toEqual(["stops", "allQuiet"]);
  });
});
