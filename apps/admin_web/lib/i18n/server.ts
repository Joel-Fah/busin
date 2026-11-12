import { cookies, headers } from "next/headers";

import { catalogues, isLocale, type Locale, type Messages } from "@/lib/i18n/messages";

export const LOCALE_COOKIE = "locale";

/** The visitor's language: their saved choice, else the browser's preference, else English. */
export async function getLocale(): Promise<Locale> {
  const saved = (await cookies()).get(LOCALE_COOKIE)?.value;
  if (isLocale(saved)) return saved;

  const accepted = (await headers()).get("accept-language") ?? "";
  return accepted.toLowerCase().startsWith("fr") ? "fr" : "en";
}

export async function getMessages(): Promise<{ locale: Locale; t: Messages }> {
  const locale = await getLocale();
  return { locale, t: catalogues[locale] };
}
