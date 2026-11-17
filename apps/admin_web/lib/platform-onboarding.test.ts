import { describe, expect, it } from "vitest";

import { onboardingErrorKey, readNewSchool, timeZones } from "./platform-onboarding";

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
