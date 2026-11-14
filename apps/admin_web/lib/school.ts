import { parsePhone } from "@/lib/phone/phone";
/** Pure helpers for the school profile page. Kept separate so they are unit tested. */

/** The version of the terms for schools in lib/legal/school-terms.ts. A new version asks the school to accept again. */
export const SCHOOL_TERMS_VERSION = "2026-11-11";

export const SCHOOL_LIMITS = { name: 120, shortName: 20, website: 200, email: 254, phone: 30, address: 200, city: 80, country: 80, about: 280 } as const;

/** The largest logo the server accepts, after the browser has shrunk it to 512 px. */
export const MAX_LOGO_BYTES = 1024 * 1024;
/** The longest side of a stored logo, in pixels. The logo keeps its own proportions. */
export const LOGO_SIZE = 512;

/** At most this many domains may be allowed to ask to join. */
export const MAX_OPEN_DOMAINS = 20;

/** "@Gmail.com " becomes "gmail.com". */
export function normalizeDomain(raw: string): string {
  return raw.trim().replace(/^@+/, "").toLowerCase();
}

/** Same rule as the database: letters, digits and hyphens in at least two dot-separated parts. */
export function isValidDomain(domain: string): boolean {
  return domain.length <= 253 && /^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/.test(domain);
}

export type SchoolProfileInput = {
  name: string;
  shortName: string;
  website: string;
  contactEmail: string;
  phone: string;
  address: string;
  city: string;
  country: string;
  about: string;
  acceptsOpenSignup: boolean;
  /** Domains allowed to ask to join; empty means any. */
  openSignupDomains: string[];
  publicListing: boolean;
};

export type SchoolField = "name" | "shortName" | "website" | "contactEmail" | "phone" | "address" | "city" | "country" | "about" | "openDomains";

const text = (form: { get(name: string): unknown }, key: string) => {
  const value = form.get(key);
  return typeof value === "string" ? value.trim().replace(/\s+/g, " ") : "";
};

/** Reads and checks the form. The database checks the same rules again; this gives a clear message per field. */
export function parseSchoolForm(form: { get(name: string): unknown }): { ok: true; value: SchoolProfileInput } | { ok: false; field: SchoolField } {
  const about = typeof form.get("about") === "string" ? String(form.get("about")).trim() : "";
  const value: SchoolProfileInput = {
    name: text(form, "name"),
    shortName: text(form, "short_name"),
    website: text(form, "website"),
    contactEmail: text(form, "contact_email").toLowerCase(),
    phone: text(form, "phone"),
    address: text(form, "address"),
    city: text(form, "city"),
    country: text(form, "country"),
    about,
    acceptsOpenSignup: form.get("accepts_open_signup") === "on",
    openSignupDomains: [...new Set(text(form, "open_signup_domains").split(/[\s,;]+/).map(normalizeDomain).filter(Boolean))],
    publicListing: form.get("public_listing") === "on",
  };
  if (value.name.length < 2 || value.name.length > SCHOOL_LIMITS.name) return { ok: false, field: "name" };
  if (value.shortName.length > SCHOOL_LIMITS.shortName) return { ok: false, field: "shortName" };
  if (value.website && (value.website.length > SCHOOL_LIMITS.website || !/^https:\/\/\S+$/.test(value.website))) return { ok: false, field: "website" };
  if (value.contactEmail && (value.contactEmail.length > SCHOOL_LIMITS.email || !/^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(value.contactEmail))) {
    return { ok: false, field: "contactEmail" };
  }
  // The school's number in its stored form, E.164 (ADR 0024), read for the country chosen in the field.
  if (value.phone) {
    const phone = parsePhone(value.phone, text(form, "phoneCountry") || "CM");
    if (!phone.e164) return { ok: false, field: "phone" };
    value.phone = phone.e164;
  }
  if (value.address.length > SCHOOL_LIMITS.address) return { ok: false, field: "address" };
  if (value.city.length > SCHOOL_LIMITS.city) return { ok: false, field: "city" };
  if (value.country.length > SCHOOL_LIMITS.country) return { ok: false, field: "country" };
  if (value.about.length > SCHOOL_LIMITS.about) return { ok: false, field: "about" };
  if (value.openSignupDomains.length > MAX_OPEN_DOMAINS || !value.openSignupDomains.every(isValidDomain)) return { ok: false, field: "openDomains" };
  return { ok: true, value };
}

export type SchoolSaveError = SchoolField | "terms_first" | "generic";

/** Maps a database error from saving: a failed column check names its field; 55000 is "accept the terms first". */
export function schoolSaveError(code: string | undefined, message = ""): SchoolSaveError {
  if (code === "55000") return "terms_first";
  if (code === "23514") {
    const field = (["website", "contact_email", "phone", "address", "city", "country", "about", "short_name"] as const).find((column) => message.includes(`schools_${column}_check`));
    const byColumn: Record<string, SchoolField> = { contact_email: "contactEmail", short_name: "shortName" };
    return field ? (byColumn[field] ?? (field as SchoolField)) : "generic";
  }
  if (code === "22023") return message.includes("domain") ? "openDomains" : "name";
  return "generic";
}

/** The public address of a logo in the `school-logos` bucket. */
export function logoUrl(path: string | null | undefined, supabaseUrl: string): string | null {
  if (!path) return null;
  return `${supabaseUrl.replace(/\/+$/, "")}/storage/v1/object/public/school-logos/${path.split("/").map(encodeURIComponent).join("/")}`;
}

/** A WebP file starts with "RIFF", four size bytes, then "WEBP". The browser converts every logo to WebP first. */
export function isWebp(bytes: Uint8Array): boolean {
  const ascii = (from: number, to: number) => String.fromCharCode(...bytes.slice(from, to));
  return bytes.length > 12 && ascii(0, 4) === "RIFF" && ascii(8, 12) === "WEBP";
}
