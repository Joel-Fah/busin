import { describe, expect, it } from "vitest";

import {
  MAX_REASON_LENGTH,
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

function form(values: Record<string, string>) {
  return { get: (name: string) => values[name] ?? null };
}

const valid = { bus_id: BUS, driver_id: DRIVER, direction: "inbound", scheduled_start: "2026-11-02T07:30" };

describe("parseTripForm", () => {
  it("accepts a valid form and converts the start to an instant", () => {
    expect(parseTripForm(form(valid), "Africa/Douala")).toEqual({
      ok: true,
      value: { busId: BUS, driverId: DRIVER, direction: "inbound", scheduledStart: "2026-11-02T06:30:00.000Z" },
    });
  });

  it("allows a trip without a driver yet", () => {
    const result = parseTripForm(form({ ...valid, driver_id: "" }), "UTC");
    expect(result.ok && result.value.driverId).toBeNull();
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
