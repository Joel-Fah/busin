import { supabaseConfig } from "@/lib/env";
import { logoUrl } from "@/lib/school";
import { createClient } from "@/lib/supabase/server";

/**
 * The schools shown on the landing page's wall: those whose admins accepted the terms for schools and turned on "Show
 * our school publicly" (the database function `public_schools` returns only them, and only public fields).
 */
export type WallSchool = { id: string; name: string; initials: string; city: string | null; logo: string | null };

/** "Hill University" becomes "HU"; a short name, when the school has one, is used as it is. */
export function initialsOf(name: string, shortName?: string | null): string {
  if (shortName?.trim()) return shortName.trim().slice(0, 5).toUpperCase();
  const words = name.split(/\s+/).filter((word) => /^\p{L}/u.test(word) && !["of", "de", "du", "des", "la", "le", "the", "and", "et"].includes(word.toLowerCase()));
  return (words.length > 1 ? words.slice(0, 4).map((word) => word[0]) : [name.slice(0, 2)]).join("").toUpperCase();
}

export async function loadWallSchools(): Promise<WallSchool[]> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("public_schools");
  if (error || !data) return [];
  const { url } = supabaseConfig();
  return data.map((row) => ({ id: row.id, name: row.name, initials: initialsOf(row.name, row.short_name), city: row.city, logo: logoUrl(row.logo_path, url) }));
}
