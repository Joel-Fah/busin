import { getCountryCallingCode, isSupportedCountry, parsePhoneNumberFromString, type CountryCode } from "libphonenumber-js/max";

/**
 * Phone numbers in one format (ADR 0024), as the apps' `PhoneNumbers`: stored as E.164 (`+` then the country code and
 * the number, digits only, for example `+237677123456`), typed in the country's own way, shown in international form.
 */
export type PhoneProblem = "empty" | "invalid";

const E164 = /^\+[1-9][0-9]{6,14}$/;
const TYPED = /^\+?[0-9 .\-()]+$/;

export function isE164(value: string | null | undefined): value is string {
  return typeof value === "string" && E164.test(value);
}

function asCountry(country: string | null | undefined): CountryCode | undefined {
  const code = (country ?? "").toUpperCase();
  return isSupportedCountry(code) ? (code as CountryCode) : undefined;
}

/**
 * Reads what a person typed, for `country` (two letters, for example `CM`). A number that starts with `+` keeps its own
 * country. Gives the E.164 form, or why it cannot be used.
 */
export function parsePhone(input: string | null | undefined, country: string): { e164: string; problem: null } | { e164: null; problem: PhoneProblem } {
  const value = (input ?? "").trim();
  if (!value) return { e164: null, problem: "empty" };
  if (!TYPED.test(value)) return { e164: null, problem: "invalid" };
  const read = (text: string) => {
    const number = parsePhoneNumberFromString(text, text.startsWith("+") ? undefined : { defaultCountry: asCountry(country) });
    return number?.isValid() ? number.number : null;
  };
  // A leading 0 some people add out of habit where the country has no trunk prefix (Cameroon): tried once without it.
  const digits = value.replace(/[^0-9]/g, "");
  const e164 = read(value) ?? (!value.startsWith("+") && digits.startsWith("0") ? read(digits.slice(1)) : null);
  return e164 ? { e164, problem: null } : { e164: null, problem: "invalid" };
}

/** A stored number as people read it: `+237 6 77 12 34 56`. Anything that cannot be read is shown as it is. */
export function displayPhone(e164: string): string {
  return parsePhoneNumberFromString(e164)?.formatInternational() ?? e164;
}

/** The country of a stored number (two letters), or null. */
export function countryOfPhone(e164: string | null | undefined): string | null {
  return isE164(e164) ? (parsePhoneNumberFromString(e164)?.country ?? null) : null;
}

/** The dialling code of a country (`237` for `CM`), or null. */
export function callingCode(country: string): string | null {
  const code = asCountry(country);
  return code ? getCountryCallingCode(code) : null;
}

/**
 * The country a phone field starts on, never one fixed in the code: the saved number's, else the school's own number's,
 * else the browser's region, else `fallback`.
 */
export function defaultPhoneCountry({ saved, schoolPhone, region, fallback = "CM" }: { saved?: string | null; schoolPhone?: string | null; region?: string | null; fallback?: string }): string {
  return countryOfPhone(saved) ?? countryOfPhone(schoolPhone) ?? asCountry(region) ?? fallback;
}
