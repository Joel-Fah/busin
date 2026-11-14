import { createClient } from "@/lib/supabase/server";

import { defaultPhoneCountry } from "./phone";

/** Where a phone field starts (ADR 0024): the saved number's country, else the school's number's, else its country. */
export async function phoneCountryFor(schoolId: string | null, saved: string | null): Promise<string> {
  const supabase = await createClient();
  const school = schoolId ? (await supabase.from("schools").select("phone, country").eq("id", schoolId).maybeSingle()).data : null;
  return defaultPhoneCountry({ saved, schoolPhone: school?.phone ?? null, schoolCountry: school?.country ?? null });
}
