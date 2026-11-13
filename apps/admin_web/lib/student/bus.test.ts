import { describe, expect, it } from "vitest";

import { BusUpdateDetector, estimateEta, walkToStop, type BusUpdateKind, type Position, type StopPoint } from "./bus";

// The cases of apps/student/test/bus_updates_test.dart and eta_test.dart, so both clients say the same things.
const t0 = Date.UTC(2026, 10, 11, 7);
// Along a north-south road: 0.0009 degrees of latitude is about 100 m.
const north = (metres: number) => ({ lat: 3.8 + (metres / 100) * 0.0009, lng: 11.5 });
const stop = (id: string, name: string, atMetres: number): StopPoint => ({ id, name, position: north(atMetres) });
const at = (metres: number, seconds: number, speed: number | null = null, trip = "t1"): Position => ({ tripId: trip, position: north(metres), speedMps: speed, recordedAt: t0 + seconds * 1000 });
const run = (d: BusUpdateDetector, positions: Position[]): BusUpdateKind[] =>
  positions.map((p) => d.onPosition(p, p.recordedAt)?.kind).filter((k): k is BusUpdateKind => k !== undefined);

const a = stop("a", "Alpha", 1000);
const mine = stop("m", "Mine", 3000);

describe("estimated arrival", () => {
  it("is nothing without both points, and arriving within 80 m", () => {
    expect(estimateEta(null, north(0), 5)).toBeNull();
    expect(estimateEta(north(0), north(50), 5)?.minutes).toBe(0);
  });

  it("uses the bus's speed when it moves, else a city average, over the road", () => {
    // 1 km straight, 1.3 km by road: at 36 km/h about 2.2 min, at 20 km/h about 3.9 min.
    expect(estimateEta(north(0), north(1000), 10)?.minutes).toBe(3);
    expect(estimateEta(north(0), north(1000), 0)?.minutes).toBe(4);
    expect(estimateEta(north(0), north(1000), null)?.kilometres).toBeCloseTo(1.3, 1);
  });

  it("works out the walk to the stop at 4.8 km/h", () => {
    const walk = walkToStop(north(0), north(400));
    expect(walk.metres).toBeCloseTo(520, -1);
    expect(walk.minutes).toBe(7);
  });
});

describe("live updates of the followed bus", () => {
  it("says the bus is followed at the first position, then nothing new", () => {
    const d = new BusUpdateDetector([a, mine], null);
    expect(d.onPosition(at(0, 0, 8), t0)?.kind).toBe("following");
    expect(d.onPosition(at(80, 10, 8), t0 + 10_000)).toBeNull();
  });

  it("says arriving at a stop and leaving it, by name", () => {
    const d = new BusUpdateDetector([a, mine], null);
    const said = [at(0, 0, 8), at(960, 120, 2), at(1010, 130, 0), at(1200, 160, 8), at(2000, 260, 8)]
      .map((p) => d.onPosition(p, p.recordedAt))
      .filter((u) => u !== null)
      .map((u) => [u.kind, u.stopName]);
    expect(said).toEqual([["following", undefined], ["atStop", "Alpha"], ["leftStop", "Alpha"]]);
  });

  it("says stopped after 90 s still away from a stop, then moving again", () => {
    const d = new BusUpdateDetector([a], null);
    expect(run(d, [at(0, 0, 8), at(500, 60, 0), at(505, 100, 0.3), at(510, 150, 0), at(512, 170, 0), at(600, 190, 6)])).toEqual(["following", "stopped", "moving"]);
  });

  it("says nothing more while standing at a stop", () => {
    const d = new BusUpdateDetector([a], null);
    expect(run(d, [at(0, 0, 8), at(1000, 100, 0), at(1002, 200, 0), at(1003, 300, 0)])).toEqual(["following", "atStop"]);
  });

  it("says near my stop once, then at it, then passed it", () => {
    const d = new BusUpdateDetector([a, mine], mine);
    const said = [at(1500, 0, 10), at(2500, 60, 10), at(2600, 70, 10), at(2990, 110, 2), at(3200, 140, 8), at(3400, 160, 8)]
      .map((p) => d.onPosition(p, p.recordedAt))
      .filter((u) => u !== null);
    expect(said.map((u) => u.kind)).toEqual(["following", "nearMyStop", "atStop", "passedMyStop"]);
    expect(said[1].minutes).toBeLessThanOrEqual(3);
  });

  it("says no signal once after 2 minutes, and back with the next position", () => {
    const d = new BusUpdateDetector([a], null);
    d.onPosition(at(0, 0, 8), t0);
    expect(d.onTick(t0 + 100_000)).toBeNull();
    const lost = d.onTick(t0 + 130_000);
    expect(lost?.kind).toBe("signalLost");
    expect(lost?.since).toBe(t0);
    expect(d.onTick(t0 + 240_000)).toBeNull();
    expect(d.onPosition(at(300, 250, 8), t0 + 250_000)?.kind).toBe("signalBack");
  });

  it("starts over for a new trip and ignores an old or repeated position", () => {
    const d = new BusUpdateDetector([a], null);
    expect(d.onPosition(at(0, 0, 8), t0)?.kind).toBe("following");
    expect(d.onPosition(at(0, 0, 8), t0)).toBeNull();
    expect(d.onPosition(at(10, 20, 8, "t2"), t0 + 20_000)?.kind).toBe("following");
  });

  it("numbers every update and says when the trip ends", () => {
    const d = new BusUpdateDetector([a], null);
    const first = d.onPosition(at(0, 0, 8), t0)!;
    const end = d.onTripEnded(t0 + 1000);
    expect(end.kind).toBe("tripEnded");
    expect(end.seq).toBeGreaterThan(first.seq);
  });
});
