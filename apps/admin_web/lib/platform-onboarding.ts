/**
 * Creating a school from the platform console (ADR 0027, slice 4): the form read and checked the way the database
 * checks it, the time zones offered, and the refusals the page explains.
 */

import { isValidDomain, normalizeDomain } from "@/lib/school";

export const MAX_SCHOOL_DOMAINS = 10;

export type NewSchool = {
  name: string;
  shortName: string | null;
  timezone: string;
  country: string | null;
  city: string | null;
  domains: string[];
  adminEmail: string | null;
};

export const ONBOARDING_ERRORS = [
  "bad_name",
  "bad_short_name",
  "bad_timezone",
  "bad_country",
  "bad_city",
  "bad_domain",
  "too_many_domains",
  "name_taken",
  "domain_taken",
  "invalid_email",
  "other_school",
  "no_school",
  "generic",
] as const;
export type OnboardingError = (typeof ONBOARDING_ERRORS)[number];

export function onboardingErrorKey(message: string | null | undefined): OnboardingError {
  const key = (message ?? "").trim();
  return (ONBOARDING_ERRORS as readonly string[]).includes(key) ? (key as OnboardingError) : "generic";
}

export function isOnboardingError(value: unknown): value is OnboardingError {
  return typeof value === "string" && (ONBOARDING_ERRORS as readonly string[]).includes(value);
}

/** Every time zone this server knows, for the picker (the database checks the same names). */
export function timeZones(): string[] {
  try {
    return Intl.supportedValuesOf("timeZone");
  } catch {
    return ["UTC"];
  }
}

export type TimeZoneOption = { value: string; label: string; detail: string };

/**
 * The time zones as the picker lists them: the name as stored ("America/New_York"), read with spaces
 * ("America/New York"), and its offset from UTC on the given day ("UTC-5", "UTC+5:30", "UTC").
 */
export function timeZoneOptions(zones: string[], at: Date = new Date()): TimeZoneOption[] {
  return zones.map((zone) => {
    let offset = "";
    try {
      const part = new Intl.DateTimeFormat("en", { timeZone: zone, timeZoneName: "shortOffset" }).formatToParts(at).find((p) => p.type === "timeZoneName");
      offset = (part?.value ?? "").replace(/^GMT/, "UTC").replace(/^UTC[+-]0$/, "UTC");
    } catch {
      // A name this runtime cannot format: listed without its offset.
    }
    return { value: zone, label: zone.replaceAll("_", " "), detail: offset };
  });
}

const EMAIL =/^[^@\s]+@[^@\s]+\.[^@\s]+$/;

const text = (form: FormData, key: string) => {
  const value = form.get(key);
  return typeof value === "string" ? value.trim() : "";
};

/** The form as the database expects it, or the first problem found (the same rules the database applies). */
export function readNewSchool(form: FormData): { ok: true; value: NewSchool } | { ok: false; error: OnboardingError } {
  const name = text(form, "name");
  const shortName = text(form, "short_name");
  const timezone = text(form, "timezone");
  const domains = [...new Set(text(form, "domains").split(/[\s,;]+/).map(normalizeDomain).filter(Boolean))];
  const adminEmail = text(form, "admin_email").toLowerCase();

  if (name.length < 2 || name.length > 120) return { ok: false, error: "bad_name" };
  if (shortName.length > 20) return { ok: false, error: "bad_short_name" };
  if (!timeZones().includes(timezone)) return { ok: false, error: "bad_timezone" };
  if (domains.length > MAX_SCHOOL_DOMAINS) return { ok: false, error: "too_many_domains" };
  if (!domains.every(isValidDomain)) return { ok: false, error: "bad_domain" };
  if (adminEmail && (!EMAIL.test(adminEmail) || adminEmail.length > 254)) return { ok: false, error: "invalid_email" };

  return {
    ok: true,
    value: {
      name,
      shortName: shortName || null,
      timezone,
      country: text(form, "country") || null,
      city: text(form, "city") || null,
      domains,
      adminEmail: adminEmail || null,
    },
  };
}

export const ONBOARDING_DONE = ["created", "invited", "applied", "adminInvited", "adminApplied", "off", "on"] as const;
export type OnboardingDone = (typeof ONBOARDING_DONE)[number];

export function isOnboardingDone(value: unknown): value is OnboardingDone {
  return typeof value === "string" && (ONBOARDING_DONE as readonly string[]).includes(value);
}
