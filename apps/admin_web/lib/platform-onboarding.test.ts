import { describe, expect, it } from "vitest";

import { onboardingErrorKey, readNewSchool, timeZoneOptions, timeZones } from "./platform-onboarding";

const form = (entries: Record<string, string>) => {
  const data = new FormData();
  for (const [key, value] of Object.entries(entries)) data.set(key, value);
  return data;
};

const base = { name: "New School", timezone: "Africa/Lagos", domains: "" };

describe("readNewSchool", () => {
  it("reads a school with its domains cleaned and its first administrator", () => {
    const result = readNewSchool(form({ ...base, short_name: " NS ", country: "NG", city: "Lagos", domains: "@New.edu, staff.new.edu new.edu", admin_email: " Registrar@New.edu " }));
    expect(result).toEqual({
      ok: true,
      value: { name: "New School", shortName: "NS", timezone: "Africa/Lagos", country: "NG", city: "Lagos", domains: ["new.edu", "staff.new.edu"], adminEmail: "registrar@new.edu" },
    });
  });

  it("finds the first problem, as the database would", () => {
    expect(readNewSchool(form({ ...base, name: "X" }))).toEqual({ ok: false, error: "bad_name" });
    expect(readNewSchool(form({ ...base, timezone: "Mars/Olympus" }))).toEqual({ ok: false, error: "bad_timezone" });
    expect(readNewSchool(form({ ...base, domains: "not a domain" }))).toEqual({ ok: false, error: "bad_domain" });
    expect(readNewSchool(form({ ...base, domains: Array.from({ length: 11 }, (_, i) => `d${i}.edu`).join(",") }))).toEqual({ ok: false, error: "too_many_domains" });
    expect(readNewSchool(form({ ...base, admin_email: "nope" }))).toEqual({ ok: false, error: "invalid_email" });
  });

  it("needs no domain and no administrator", () => {
    expect(readNewSchool(form(base))).toMatchObject({ ok: true, value: { domains: [], adminEmail: null, shortName: null } });
  });
});

describe("onboardingErrorKey and timeZones", () => {
  it("keeps the refusals it knows", () => {
    expect(onboardingErrorKey("domain_taken")).toBe("domain_taken");
    expect(onboardingErrorKey("something else")).toBe("generic");
  });
  it("lists real time zones", () => {
    expect(timeZones()).toContain("Africa/Douala");
  });
});

describe("timeZoneOptions", () => {
  it("reads each zone with spaces and its offset on the day", () => {
    const winter = new Date("2026-01-15T12:00:00Z");
    expect(timeZoneOptions(["America/New_York", "Asia/Kolkata", "Africa/Douala", "UTC"], winter)).toEqual([
      { value: "America/New_York", label: "America/New York", detail: "UTC-5" },
      { value: "Asia/Kolkata", label: "Asia/Kolkata", detail: "UTC+5:30" },
      { value: "Africa/Douala", label: "Africa/Douala", detail: "UTC+1" },
      { value: "UTC", label: "UTC", detail: "UTC" },
    ]);
    expect(timeZoneOptions(["America/New_York"], new Date("2026-07-15T12:00:00Z"))[0].detail).toBe("UTC-4");
  });
  it("keeps a zone it cannot format, without an offset", () => {
    expect(timeZoneOptions(["Mars/Olympus"])).toEqual([{ value: "Mars/Olympus", label: "Mars/Olympus", detail: "" }]);
  });
});
