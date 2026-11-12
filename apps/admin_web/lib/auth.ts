import { cache } from "react";
import { redirect } from "next/navigation";

import { decideAccess } from "@/lib/access";
import { createClient } from "@/lib/supabase/server";

export type AdminContext = {
  userId: string;
  email: string;
  fullName: string;
  schoolId: string;
  schoolName: string;
  schoolTimezone: string;
  avatarUrl: string | null;
};

/**
 * The signed-in user and their profile, or null when nobody is signed in.
 * `getUser` asks the auth server to validate the token, so a revoked session is rejected.
 * Cached per request so layouts and pages can both call it.
 */
export const getCurrentUser = cache(async () => {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: profile } = await supabase
    .from("profiles")
    .select("id, email, full_name, avatar_url, role, status, school_id, schools(name, timezone)")
    .eq("id", user.id)
    .maybeSingle();

  return { user, profile };
});

/**
 * Guard for every admin page, server action and route handler.
 * Sends signed-out visitors to the login page and everyone who is not a verified
 * administrator to the no-access page. Call it again in each action: never rely on the proxy.
 */
export async function requireAdmin(): Promise<AdminContext> {
  const current = await getCurrentUser();
  if (!current) redirect("/login");

  // An administrator always has a school (the database allows no school only for a student waiting to join one).
  if (decideAccess(current.profile) !== "admin" || !current.profile?.school_id) {
    redirect("/no-access");
  }

  const { profile } = current;
  const school = profile.schools;
  return {
    userId: profile.id,
    email: profile.email,
    fullName: profile.full_name,
    schoolId: profile.school_id as string,
    schoolName: school?.name ?? "",
    schoolTimezone: school?.timezone ?? "UTC",
    avatarUrl: profile.avatar_url,
  };
}
