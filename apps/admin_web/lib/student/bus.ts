import { distanceMeters, type LatLng } from "@/lib/geo";

/**
 * The My bus tab's rules, ported from the student app (eta.dart, bus_updates.dart, my_location.dart) and kept pure: the
 * time is passed in, so every case is a unit test.
 */

/** A road is longer than the straight line between two points. */
export const ROAD_FACTOR = 1.3;
/** Used when the bus is standing or slower than a walk (a red light must not read as "never"). */
export const CITY_AVERAGE_KMH = 20;
/** Below this the bus is taken to be at the stop. */
export const ARRIVED_WITHIN_M = 80;
/** A position older than this means the bus is out of signal. */
export const STALE_AFTER_MS = 2 * 60_000;

export type Eta = { minutes: number; kilometres: number };

/** About how long the bus takes to reach a stop: the straight line with a road allowance, at its own speed if moving. */
export function estimateEta(bus: LatLng | null, stop: LatLng | null, speedMps: number | null): Eta | null {
  if (!bus || !stop) return null;
  const straight = distanceMeters(bus, stop);
  if (straight <= ARRIVED_WITHIN_M) return { minutes: 0, kilometres: straight / 1000 };
  const road = straight * ROAD_FACTOR;
  const moving = speedMps !== null && speedMps * 3.6 >= 8;
  const metresPerSecond = moving ? speedMps : CITY_AVERAGE_KMH / 3.6;
  return { minutes: Math.max(1, Math.ceil(road / metresPerSecond / 60)), kilometres: road / 1000 };
}

/** Walking to the stop for Show me (ADR 0016): 4.8 km/h along roads 1.3 times the straight line. */
export function walkToStop(me: LatLng, stop: LatLng): { metres: number; minutes: number } {
  const metres = distanceMeters(me, stop) * ROAD_FACTOR;
  return { metres, minutes: Math.max(1, Math.round(metres / (4800 / 60))) };
}

export type StopPoint = { id: string; name: string; position: LatLng };
export type Position = { tripId: string | null; position: LatLng; speedMps: number | null; recordedAt: number };

export type BusUpdateKind = "following" | "atStop" | "leftStop" | "stopped" | "moving" | "nearMyStop" | "passedMyStop" | "signalLost" | "signalBack" | "tripEnded";
export type BusUpdate = { kind: BusUpdateKind; at: number; seq: number; stopName?: string; since?: number; minutes?: number };

const LEFT_STOP_AFTER_M = 120;
const STILL_BELOW_MPS = 1;
const STILL_WITHIN_M = 30;
const STOPPED_AFTER_MS = 90_000;
const NEAR_MY_STOP_MINUTES = 3;
const REACHED_MY_STOP_WITHIN_M = 150;
const PASSED_MY_STOP_AFTER_M = 300;

/**
 * Turns the positions of one bus into short updates, as the app's detector. Feed it each new position, tick it now and
 * then (for "no signal"), and tell it when the trip ends. Each returns the update to show, or null. When several things
 * happen at once the most useful is said: signal back, then passed or near my stop, then a stop, then stopped or moving,
 * then "following".
 */
export class BusUpdateDetector {
  private seq = 0;
  private tripId: string | null | undefined = undefined;
  private last: Position | null = null;
  private started = false;
  private signalLost = false;
  private atStop: StopPoint | null = null;
  private stillAnchor: LatLng | null = null;
  private stillSince: number | null = null;
  private stoppedSaid = false;
  private nearSaid = false;
  private reachedMine = false;
  private passedSaid = false;
  private lastMineDistance: number | null = null;

  constructor(
    private readonly stops: StopPoint[],
    private readonly myStop: StopPoint | null,
  ) {}

  private make(kind: BusUpdateKind, now: number, extra: Partial<BusUpdate> = {}): BusUpdate {
    return { kind, at: now, seq: ++this.seq, ...extra };
  }

  private resetTrip(tripId: string | null) {
    this.tripId = tripId;
    this.started = false;
    this.atStop = null;
    this.stillAnchor = null;
    this.stillSince = null;
    this.stoppedSaid = false;
    this.nearSaid = false;
    this.reachedMine = false;
    this.passedSaid = false;
    this.lastMineDistance = null;
  }

  private stopWithin(at: LatLng, metres: number): StopPoint | null {
    let best: StopPoint | null = null;
    let bestDistance = metres;
    for (const stop of this.stops) {
      const d = distanceMeters(at, stop.position);
      if (d <= bestDistance) {
        best = stop;
        bestDistance = d;
      }
    }
    return best;
  }

  onPosition(p: Position, now: number): BusUpdate | null {
    if (this.last && p.recordedAt <= this.last.recordedAt) return null;
    if (p.tripId !== this.tripId) this.resetTrip(p.tripId);
    this.last = p;
    const at = p.position;
    const candidates: (() => BusUpdate)[] = [];

    if (this.signalLost) {
      this.signalLost = false;
      candidates.push(() => this.make("signalBack", now));
    }

    const mine = this.myStop;
    if (mine) {
      const d = distanceMeters(at, mine.position);
      if (d <= REACHED_MY_STOP_WITHIN_M) this.reachedMine = true;
      const movingAway = this.lastMineDistance !== null && d > this.lastMineDistance;
      if (this.reachedMine && !this.passedSaid && d >= PASSED_MY_STOP_AFTER_M && movingAway) {
        this.passedSaid = true;
        candidates.push(() => this.make("passedMyStop", now, { stopName: mine.name }));
      }
      const eta = estimateEta(at, mine.position, p.speedMps);
      if (!this.nearSaid && !this.reachedMine && eta && eta.minutes > 0 && eta.minutes <= NEAR_MY_STOP_MINUTES) {
        this.nearSaid = true;
        const minutes = eta.minutes;
        candidates.push(() => this.make("nearMyStop", now, { stopName: mine.name, minutes }));
      }
      this.lastMineDistance = d;
    }

    const previous = this.atStop;
    if (previous && distanceMeters(at, previous.position) > LEFT_STOP_AFTER_M) {
      this.atStop = null;
      if (previous.id !== mine?.id) candidates.push(() => this.make("leftStop", now, { stopName: previous.name }));
    }
    const here = this.stopWithin(at, ARRIVED_WITHIN_M);
    if (here && here.id !== this.atStop?.id) {
      this.atStop = here;
      candidates.push(() => this.make("atStop", now, { stopName: here.name }));
    }

    const slow = (p.speedMps ?? 0) < STILL_BELOW_MPS;
    const anchor = this.stillAnchor;
    if (slow && anchor && distanceMeters(at, anchor) <= STILL_WITHIN_M) {
      if (!this.stoppedSaid && !this.atStop && this.stillSince !== null && now - this.stillSince >= STOPPED_AFTER_MS) {
        this.stoppedSaid = true;
        const since = this.stillSince;
        candidates.push(() => this.make("stopped", now, { since }));
      }
    } else {
      if (this.stoppedSaid) candidates.push(() => this.make("moving", now));
      this.stoppedSaid = false;
      this.stillAnchor = slow ? at : null;
      this.stillSince = slow ? p.recordedAt : null;
    }

    if (!this.started) {
      this.started = true;
      candidates.push(() => this.make("following", now));
    }
    return candidates.length ? candidates[0]() : null;
  }

  /** Says "no signal" once when the last position gets too old. */
  onTick(now: number): BusUpdate | null {
    if (!this.last || this.signalLost) return null;
    if (now - this.last.recordedAt < STALE_AFTER_MS) return null;
    this.signalLost = true;
    return this.make("signalLost", now, { since: this.last.recordedAt });
  }

  onTripEnded(now: number): BusUpdate {
    return this.make("tripEnded", now);
  }
}
