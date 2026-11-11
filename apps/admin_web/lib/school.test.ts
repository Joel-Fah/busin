import { describe, expect, it } from "vitest";

import { initialsOf } from "./landing/schools";
import { isValidDomain, isWebp, logoUrl, normalizeDomain, parseSchoolForm, schoolSaveError } from "./school";

const form = (values: Record<string, string>) => ({ get: (name: string) => values[name] ?? null });
const valid = { name: "  Hill   University ", short_name: "HU", website: "https://hill.example", contact_email: "Info@Hill.example", phone: "+237 6 00 00 00 00", city: "Yaounde" };

describe("school profile form", () => {
  it("reads and tidies the fields, and the switches", () => {
    const parsed = parseSchoolForm(form({ ...valid, accepts_open_signup: "on" }));
    expect(parsed.ok).toBe(true);
    if (!parsed.ok) return;
    expect(parsed.value.name).toBe("Hill University");
    expect(parsed.value.contactEmail).toBe("info@hill.example");
    expect(parsed.value.acceptsOpenSignup).toBe(true);
    expect(parsed.value.publicListing).toBe(false);
  });

  it("names the field that is wrong", () => {
    expect(parseSchoolForm(form({ ...valid, name: "H" }))).toEqual({ ok: false, field: "name" });
    expect(parseSchoolForm(form({ ...valid, website: "http://hill.example" }))).toEqual({ ok: false, field: "website" });
    expect(parseSchoolForm(form({ ...valid, contact_email: "nope" }))).toEqual({ ok: false, field: "contactEmail" });
    expect(parseSchoolForm(form({ ...valid, phone: "call me" }))).toEqual({ ok: false, field: "phone" });
    expect(parseSchoolForm(form({ ...valid, about: "x".repeat(281) }))).toEqual({ ok: false, field: "about" });
    expect(parseSchoolForm(form({ ...valid, short_name: "x".repeat(21) }))).toEqual({ ok: false, field: "shortName" });
  });

  it("maps database errors to a field or a reason", () => {
    expect(schoolSaveError("55000")).toBe("terms_first");
    expect(schoolSaveError("23514", 'new row violates check constraint "schools_website_check"')).toBe("website");
    expect(schoolSaveError("23514", 'violates check constraint "schools_contact_email_check"')).toBe("contactEmail");
    expect(schoolSaveError("23514", "something else")).toBe("generic");
    expect(schoolSaveError("22023")).toBe("name");
    expect(schoolSaveError(undefined)).toBe("generic");
  });
});

describe("allowed domains", () => {
  it("tidies and checks domains", () => {
    expect(normalizeDomain(" @Gmail.COM ")).toBe("gmail.com");
    expect(isValidDomain("gmail.com")).toBe(true);
    expect(isValidDomain("mail.school-a.edu.cm")).toBe(true);
    expect(isValidDomain("gmail")).toBe(false);
    expect(isValidDomain("not a domain")).toBe(false);
    expect(isValidDomain("-bad.com")).toBe(false);
  });

  it("reads the list from the form, without duplicates, and an empty list means any", () => {
    const parsed = parseSchoolForm(form({ ...valid, open_signup_domains: "gmail.com, @GMAIL.com yahoo.fr" }));
    expect(parsed.ok && parsed.value.openSignupDomains).toEqual(["gmail.com", "yahoo.fr"]);
    const empty = parseSchoolForm(form({ ...valid }));
    expect(empty.ok && empty.value.openSignupDomains).toEqual([]);
    expect(parseSchoolForm(form({ ...valid, open_signup_domains: "gmail" }))).toEqual({ ok: false, field: "openDomains" });
    expect(schoolSaveError("22023", "Invalid domain")).toBe("openDomains");
  });
});

describe("logos", () => {
  it("builds the public address of a logo", () => {
    expect(logoUrl("abc/logo-1.webp", "http://127.0.0.1:54321/")).toBe("http://127.0.0.1:54321/storage/v1/object/public/school-logos/abc/logo-1.webp");
    expect(logoUrl(null, "http://x")).toBeNull();
  });

  it("recognises a WebP file and nothing else", () => {
    const webp = new Uint8Array([...new TextEncoder().encode("RIFF"), 0, 0, 0, 0, ...new TextEncoder().encode("WEBPVP8 ")]);
    expect(isWebp(webp)).toBe(true);
    expect(isWebp(new TextEncoder().encode("<svg xmlns='http://www.w3.org/2000/svg'/>"))).toBe(false);
    expect(isWebp(new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0, 0, 0, 0, 0, 0, 0, 0, 0]))).toBe(false);
  });

  it("makes initials for a school without a logo", () => {
    expect(initialsOf("Hill University")).toBe("HU");
    expect(initialsOf("Université de la Colline")).toBe("UC");
    expect(initialsOf("ICT University", "ICTU")).toBe("ICTU");
    expect(initialsOf("Polytechnique")).toBe("PO");
  });
});
