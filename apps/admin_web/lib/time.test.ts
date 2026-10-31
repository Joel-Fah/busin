import { describe, expect, it } from "vitest";

import { startOfDayInTimeZone } from "./time";

const iso = (date: Date) => date.toISOString();

describe("startOfDayInTimeZone", () => {
  it("is midnight UTC for UTC", () => {
    expect(iso(startOfDayInTimeZone("UTC", new Date("2026-10-30T10:00:00Z")))).toBe(
      "2026-10-30T00:00:00.000Z",
    );
  });

  it("uses the school's day, not the server's (Douala is UTC+1)", () => {
    // 23:30 UTC on the 30th is already 00:30 on the 31st in Douala.
    expect(iso(startOfDayInTimeZone("Africa/Douala", new Date("2026-10-30T23:30:00Z")))).toBe(
      "2026-10-30T23:00:00.000Z",
    );
    expect(iso(startOfDayInTimeZone("Africa/Douala", new Date("2026-10-30T10:00:00Z")))).toBe(
      "2026-10-29T23:00:00.000Z",
    );
  });

  it("handles a zone behind UTC", () => {
    // 02:00 UTC on the 30th is 22:00 on the 29th in New York (EDT, UTC-4).
    expect(iso(startOfDayInTimeZone("America/New_York", new Date("2026-10-30T02:00:00Z")))).toBe(
      "2026-10-29T04:00:00.000Z",
    );
  });

  it("is correct on daylight saving change days", () => {
    // Clocks go forward on 2026-03-08: midnight is still EST (UTC-5).
    expect(iso(startOfDayInTimeZone("America/New_York", new Date("2026-03-08T18:00:00Z")))).toBe(
      "2026-03-08T05:00:00.000Z",
    );
    // Clocks go back on 2026-11-01: midnight is still EDT (UTC-4).
    expect(iso(startOfDayInTimeZone("America/New_York", new Date("2026-11-01T18:00:00Z")))).toBe(
      "2026-11-01T04:00:00.000Z",
    );
  });
});
