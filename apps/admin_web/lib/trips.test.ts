import { describe, expect, it } from "vitest";

import {
  MAX_REASON_LENGTH,
  NO_DRIVER,
  formatMinutes,
  overdueById,
  applyTripFilters,
  parseTripFilters,
  tripsHref,
  isTripDone,
  isTripFormErrorKey,
  parseReason,
  parseStatusFilter,
  parseTripForm,
  tripStatusTone,
  tripTabCounts,
  tripActionErrorKey,
  tripSaveErrorKey,
} from "./trips";

const BUS = "a1000000-0000-4000-8000-000000000001";
const DRIVER = "a1000000-0000-4000-8000-000000000002";
const ASSISTANT = "a1000000-0000-4000-8000-000000000003";

function form(values: Record<string, string>) {
  return { get: (name: string) => values[name] ?? null };
}

const valid = { bus_id: BUS, driver_id: DRIVER, direction: "inbound", scheduled_start: "2026-11-02T07:30" };

describe("parseTripForm", () => {
  it("accepts a valid form and converts the start to an instant", () => {
    expect(parseTripForm(form(valid), "Africa/Douala")).toEqual({
      ok: true,
      value: { busId: BUS, driverId: DRIVER, assistantId: null, direction: "inbound", scheduledStart: "2026-11-02T06:30:00.000Z" },
    });
  });

  it("allows a trip without a driver yet", () => {
    const result = parseTripForm(form({ ...valid, driver_id: "" }), "UTC");
    expect(result.ok && result.value.driverId).toBeNull();
  });

  it("takes an optional assistant, who cannot be the driver", () => {
    const withAssistant = parseTripForm(form({ ...valid, assistant_id: ASSISTANT }), "UTC");
    expect(withAssistant.ok && withAssistant.value.assistantId).toBe(ASSISTANT);
    expect(parseTripForm(form({ ...valid, assistant_id: "" }), "UTC")).toMatchObject({ ok: true, value: { assistantId: null } });
    expect(parseTripForm(form({ ...valid, assistant_id: DRIVER }), "UTC")).toEqual({ ok: false, error: "crew" });
    expect(parseTripForm(form({ ...valid, assistant_id: "x" }), "UTC")).toEqual({ ok: false, error: "assistant" });
    // An assistant with no driver yet is fine.
    expect(parseTripForm(form({ ...valid, driver_id: "", assistant_id: ASSISTANT }), "UTC")).toMatchObject({ ok: true, value: { driverId: null, assistantId: ASSISTANT } });
  });

  it("rejects bad fields with the field name", () => {
    expect(parseTripForm(form({ ...valid, bus_id: "x" }), "UTC")).toEqual({ ok: false, error: "bus" });
    expect(parseTripForm(form({ ...valid, driver_id: "x" }), "UTC")).toEqual({ ok: false, error: "driver" });
    expect(parseTripForm(form({ ...valid, direction: "sideways" }), "UTC")).toEqual({ ok: false, error: "direction" });
    expect(parseTripForm(form({ ...valid, scheduled_start: "" }), "UTC")).toEqual({ ok: false, error: "start" });
  });
});

describe("parseStatusFilter", () => {
  it("falls back to all", () => {
    expect(parseStatusFilter("active")).toBe("active");
    expect(parseStatusFilter(["cancelled", "x"])).toBe("cancelled");
    expect(parseStatusFilter("archived")).toBe("archived");
    expect(parseStatusFilter("nope")).toBe("all");
    expect(parseStatusFilter(undefined)).toBe("all");
  });
});

describe("error codes and guards", () => {
  it("maps database codes", () => {
    expect(tripSaveErrorKey("23503")).toBe("bus_unavailable");
    expect(tripSaveErrorKey("PGRST116")).toBe("not_editable");
    expect(tripSaveErrorKey("23514")).toBe("invalid");
    expect(tripSaveErrorKey("42501")).toBe("generic");
  });

  it("recognises only known query values", () => {
    expect(isTripFormErrorKey("not_editable")).toBe(true);
    expect(isTripFormErrorKey("<b>")).toBe(false);
    expect(isTripDone("created")).toBe(true);
    for (const done of ["cancelled", "archived", "restored"]) expect(isTripDone(done)).toBe(true);
    expect(isTripDone("deleted")).toBe(false);
  });
});

describe("tripStatusTone", () => {
  it("gives each status its own tone", () => {
    expect(tripStatusTone("scheduled")).toBe("info");
    expect(tripStatusTone("active")).toBe("ok");
    expect(tripStatusTone("completed")).toBe("neutral");
    expect(tripStatusTone("cancelled")).toBe("bad");
  });
});

describe("tripTabCounts", () => {
  it("adds up the total and treats a missing count as zero", () => {
    expect(tripTabCounts({ scheduled: 4, active: 1, completed: 20, cancelled: null })).toEqual({
      all: 25,
      scheduled: 4,
      active: 1,
      completed: 20,
      cancelled: 0,
      archived: 0,
    });
  });
});

describe("cancelling and archiving", () => {
  it("maps database codes by action", () => {
    expect(tripActionErrorKey("55000", "cancel")).toBe("cannot_cancel");
    expect(tripActionErrorKey("55000", "archive")).toBe("cannot_archive");
    expect(tripActionErrorKey("22023", "cancel")).toBe("invalid");
    expect(tripActionErrorKey("42501", "archive")).toBe("generic");
    expect(isTripFormErrorKey("cannot_cancel")).toBe(true);
    expect(isTripFormErrorKey("cannot_archive")).toBe(true);
  });

  it("trims the reason, treats nothing as none and refuses one that is too long", () => {
    expect(parseReason("  in the garage ")).toBe("in the garage");
    expect(parseReason("   ")).toBeUndefined();
    expect(parseReason(null)).toBeUndefined();
    expect(parseReason("x".repeat(MAX_REASON_LENGTH))).toHaveLength(MAX_REASON_LENGTH);
    expect(parseReason("x".repeat(MAX_REASON_LENGTH + 1))).toBeNull();
  });

  it("counts archived trips on their own tab, outside the total", () => {
    expect(tripTabCounts({ scheduled: 2, active: 1, completed: 3, cancelled: 4 }, 5)).toEqual({
      all: 10,
      scheduled: 2,
      active: 1,
      completed: 3,
      cancelled: 4,
      archived: 5,
    });
    expect(tripTabCounts({}, null).archived).toBe(0);
  });
});

describe("trip filters", () => {
  it("reads valid filters and treats the rest as none", () => {
    expect(parseTripFilters({ status: "active", date: "2026-11-04", bus: BUS, direction: "outbound", driver: DRIVER })).toEqual({
      status: "active",
      date: "2026-11-04",
      bus: BUS,
      direction: "outbound",
      driver: DRIVER,
      size: 20,
    });
    expect(parseTripFilters({ date: "2026-02-30", bus: "x", direction: "up", driver: "y" })).toEqual({
      status: "all",
      date: null,
      bus: null,
      direction: null,
      driver: null,
      size: 20,
    });
    expect(parseTripFilters({ driver: NO_DRIVER }).driver).toBe(NO_DRIVER);
  });

  it("builds addresses without empty parts", () => {
    const none = parseTripFilters({});
    expect(tripsHref(none)).toBe("/trips");
    expect(tripsHref({ ...none, status: "completed", bus: BUS }, 2)).toBe(`/trips?status=completed&bus=${BUS}&page=2`);
  });

  it("narrows a query by each filter", () => {
    const calls: string[] = [];
    const recorder: Record<string, (...args: unknown[]) => unknown> = {};
    for (const name of ["eq", "is", "gte", "lt"]) {
      recorder[name] = (...args) => {
        calls.push(`${name} ${args.join(" ")}`);
        return recorder;
      };
    }
    applyTripFilters(recorder, parseTripFilters({ bus: BUS, direction: "inbound", driver: NO_DRIVER, date: "2026-11-04" }), "UTC");
    expect(calls).toEqual([
      `eq bus_id ${BUS}`,
      "eq direction inbound",
      "is driver_id ",
      "gte scheduled_start 2026-11-04T00:00:00.000Z",
      "lt scheduled_start 2026-11-05T00:00:00.000Z",
    ]);
  });
});

describe("overdue trips", () => {
  const now = new Date("2026-11-11T12:00:00Z");
  it("keeps known reasons and measures each from the right moment", () => {
    const map = overdueById(
      [
        { trip_id: "a", reason: "silent", started_at: "2026-11-11T10:00:00Z", last_position_at: "2026-11-11T11:15:00Z" },
        { trip_id: "b", reason: "long", started_at: "2026-11-11T08:30:00Z", last_position_at: "2026-11-11T11:59:00Z" },
        { trip_id: "c", reason: "earlier_day", started_at: "2026-11-10T07:00:00Z", last_position_at: null },
        { trip_id: "d", reason: "weird", started_at: "2026-11-11T07:00:00Z", last_position_at: null },
      ],
      now,
    );
    expect(map.get("a")).toEqual({ reason: "silent", startedAt: "2026-11-11T10:00:00Z", minutes: 45 });
    expect(map.get("b")?.minutes).toBe(210);
    expect(map.get("c")?.reason).toBe("earlier_day");
    expect(map.has("d")).toBe(false);
  });

  it("writes durations in hours and minutes", () => {
    expect(formatMinutes(45)).toBe("45 min");
    expect(formatMinutes(180)).toBe("3 h");
    expect(formatMinutes(185)).toBe("3 h 5 min");
  });

  it("maps a refused end to its message", () => {
    expect(tripActionErrorKey("55000", "end")).toBe("cannot_end");
    expect(isTripFormErrorKey("cannot_end")).toBe(true);
    expect(isTripDone("ended")).toBe(true);
  });
});
