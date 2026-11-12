"use server";

import { cookies } from "next/headers";

import { isLocale } from "@/lib/i18n/messages";
import { LOCALE_COOKIE } from "@/lib/i18n/server";

/** Saves the chosen language. Anything that is not a known language is ignored. */
export async function setLocale(formData: FormData): Promise<void> {
  const value = formData.get("locale");
  if (typeof value !== "string" || !isLocale(value)) return;

  (await cookies()).set(LOCALE_COOKIE, value, {
    path: "/",
    maxAge: 60 * 60 * 24 * 365,
    sameSite: "lax",
  });
}
