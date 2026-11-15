import { cache } from "react";
import { notFound, redirect } from "next/navigation";

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

  // A student who reaches the portal (the root address, the portal's sign-in) belongs in the student web app (ADR 0021).
  if (current.profile?.role === "student") redirect("/app");

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

export type PlatformContext = {
  userId: string;
  email: string;
  fullName: string;
  avatarUrl: string | null;
  /** The school the account belongs to, if any (a platform admin may also be a member of a school). */
  schoolName: string | null;
  /** Also a verified administrator of a school, so the console offers the way back to that school's portal. */
  schoolAdmin: boolean;
};

/**
 * The signed-in platform admin (ADR 0027), or null for anyone else. Signed-out visitors go to the login page. The list is
 * read live on the server (`am_platform_admin`), never from the token. Cached per request so the layout and the page
 * share one check. The console's layout uses it to decide whether to show its navigation at all.
 */
export const platformContext = cache(async (): Promise<PlatformContext | null> => {
  const current = await getCurrentUser();
  if (!current) redirect("/login");

  const supabase = await createClient();
  const { data: allowed, error } = await supabase.rpc("am_platform_admin");
  if (error || allowed !== true) return null;

  const { user, profile } = current;
  return {
    userId: user.id,
    email: profile?.email ?? user.email ?? "",
    fullName: profile?.full_name ?? "",
    avatarUrl: profile?.avatar_url ?? null,
    schoolName: profile?.schools?.name ?? null,
    schoolAdmin: decideAccess(profile) === "admin" && Boolean(profile?.school_id),
  };
});

/**
 * Guard for every platform console page and server action: everyone who is not a platform admin gets "not found", so the
 * console does not show that it exists. Call it again in each action: never rely on the layout or the proxy.
 */
export async function requirePlatformAdmin(): Promise<PlatformContext> {
  const context = await platformContext();
  if (!context) notFound();
  return context;
}
