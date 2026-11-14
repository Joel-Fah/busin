import { COUNTRIES, type Country } from "./countries";

function plain(text: string): string {
  return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}

/** A country's name in the page's language. */
export function countryName(country: Country, locale: "en" | "fr"): string {
  return locale === "fr" ? country.fr : country.en;
}

/** The country a stored name or code stands for (English or French name, or two letters), if any. */
export function findCountry(value: string | null | undefined): Country | undefined {
  const v = plain((value ?? "").trim());
  if (!v) return undefined;
  return COUNTRIES.find((c) => c.code.toLowerCase() === v || plain(c.en) === v || plain(c.fr) === v);
}
