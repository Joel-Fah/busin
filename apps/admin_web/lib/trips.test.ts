import { describe, expect, it } from "vitest";

import {
  isTripDone,
  isTripFormErrorKey,
  parseStatusFilter,
  parseTripForm,
  statusPill,
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
    expect(isTripDone("deleted")).toBe(false);
  });

  it("has a pill for every status", () => {
    expect(statusPill("active")).toContain("pill-ok");
    expect(statusPill("completed")).toBe("pill");
  });
});
