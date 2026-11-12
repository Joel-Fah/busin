import { describe, expect, it } from "vitest";

import { isLocalDateTime, utcToZonedLocal, zonedLocalToUtc } from "./zoned";

describe("isLocalDateTime", () => {
  it("accepts real date and times only", () => {
    expect(isLocalDateTime("2026-11-02T07:30")).toBe(true);
    expect(isLocalDateTime("2026-11-02T24:00")).toBe(false);
    expect(isLocalDateTime("2026-02-30T07:30")).toBe(false);
    expect(isLocalDateTime("2026-11-02 07:30")).toBe(false);
    expect(isLocalDateTime("2026-11-02")).toBe(false);
    expect(isLocalDateTime(null)).toBe(false);
  });
});

describe("zonedLocalToUtc", () => {
  it("applies the offset of the school timezone", () => {
    // Douala is UTC+1 all year.
    expect(zonedLocalToUtc("2026-11-02T07:30", "Africa/Douala")?.toISOString()).toBe("2026-11-02T06:30:00.000Z");
    expect(zonedLocalToUtc("2026-11-02T07:30", "UTC")?.toISOString()).toBe("2026-11-02T07:30:00.000Z");
  });

  it("follows daylight saving where a zone has it", () => {
    expect(zonedLocalToUtc("2026-07-01T12:00", "Europe/Paris")?.toISOString()).toBe("2026-07-01T10:00:00.000Z");
    expect(zonedLocalToUtc("2026-01-01T12:00", "Europe/Paris")?.toISOString()).toBe("2026-01-01T11:00:00.000Z");
  });

  it("returns null for invalid input", () => {
    expect(zonedLocalToUtc("nonsense", "UTC")).toBeNull();
  });
});

describe("utcToZonedLocal", () => {
  it("is the inverse of zonedLocalToUtc", () => {
    expect(utcToZonedLocal("2026-11-02T06:30:00.000Z", "Africa/Douala")).toBe("2026-11-02T07:30");
    const local = "2026-03-29T09:15";
    const instant = zonedLocalToUtc(local, "Europe/Paris");
    expect(instant && utcToZonedLocal(instant, "Europe/Paris")).toBe(local);
  });

  it("rolls over midnight", () => {
    expect(utcToZonedLocal("2026-11-02T23:30:00.000Z", "Africa/Douala")).toBe("2026-11-03T00:30");
  });
});
