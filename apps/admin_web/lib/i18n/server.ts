import { cookies, headers } from "next/headers";

import { catalogues, isLocale, type Locale, type Messages } from "@/lib/i18n/messages";
import { studentCatalogues, type StudentCopy } from "@/lib/i18n/student";

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

/** The student web app's words (ADR 0021), in the visitor's language. */
export async function getStudentCopy(): Promise<{ locale: Locale; s: StudentCopy }> {
  const locale = await getLocale();
  return { locale, s: studentCatalogues[locale] };
}
