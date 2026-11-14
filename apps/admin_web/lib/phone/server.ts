import { headers } from "next/headers";

import { createClient } from "@/lib/supabase/server";

import { defaultPhoneCountry } from "./phone";

/** The browser's region from its preferred language (`fr-CM` gives `CM`), or null. */
export function regionOf(acceptLanguage: string | null): string | null {
  const first = (acceptLanguage ?? "").split(",")[0]?.trim() ?? "";
  const region = first.split(/[-_]/)[1];
  return region && /^[A-Za-z]{2}$/.test(region) ? region.toUpperCase() : null;
}

/** Where a phone field starts (ADR 0024): the saved number's country, else the school's number's, else the browser's. */
export async function phoneCountryFor(schoolId: string | null, saved: string | null): Promise<string> {
  const supabase = await createClient();
  const school = schoolId ? (await supabase.from("schools").select("phone").eq("id", schoolId).maybeSingle()).data : null;
  return defaultPhoneCountry({ saved, schoolPhone: school?.phone ?? null, region: regionOf((await headers()).get("accept-language")) });
}
