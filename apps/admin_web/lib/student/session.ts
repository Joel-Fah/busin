import { redirect } from "next/navigation";
import { cache } from "react";

import { createClient } from "@/lib/supabase/server";

import { GATE_PATHS, studentAccess, type StudentAccess } from "./access";

export type StudentContext = {
  userId: string;
  email: string;
  fullName: string;
  avatarUrl: string | null;
  matricule: string | null;
  phone: string | null;
  schoolId: string;
  schoolName: string;
  schoolTimezone: string;
  schoolLogoPath: string | null;
};

/**
 * The signed-in person's own profile, with the columns the student pages use and nothing else. `getUser` asks the auth
 * server, so a revoked session is refused. Cached per request so the layout and the page share one read.
 */
export const getStudentProfile = cache(async () => {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;
  const { data: profile, error } = await supabase
    .from("profiles")
    .select("id, email, full_name, avatar_url, role, status, school_id, matricule, phone, schools(name, timezone, logo_path)")
    .eq("id", user.id)
    .maybeSingle();
  return { user, profile, failed: Boolean(error) };
});

/** Where the person stands, for the gate pages. */
export async function currentAccess(): Promise<{ access: StudentAccess; profile: NonNullable<Awaited<ReturnType<typeof getStudentProfile>>>["profile"] }> {
  const current = await getStudentProfile();
  if (!current) return { access: { kind: "signedOut" }, profile: null };
  return { access: studentAccess(current.profile), profile: current.profile };
}

/**
 * A gate page stays on screen only while the person is in that state; anyone else is sent where they belong. Returns the
 * profile for the page to use.
 */
export async function requireGate(kind: Exclude<StudentAccess["kind"], "allowed" | "signedOut">) {
  const { access, profile } = await currentAccess();
  if (access.kind !== kind) redirect(access.kind === "allowed" ? "/app" : GATE_PATHS[access.kind]);
  return { access, profile: profile! };
}

/**
 * Guard for every page and server action of the app proper. Anyone who is not a verified student with their details in
 * is sent to their gate. Call it again in each action: the proxy only checks that a session exists.
 */
export async function requireStudent(): Promise<StudentContext> {
  const { access, profile } = await currentAccess();
  if (access.kind !== "allowed" || !profile?.school_id) redirect(access.kind === "allowed" ? GATE_PATHS.blocked : GATE_PATHS[access.kind]);
  const school = profile.schools;
  return {
    userId: profile.id,
    email: profile.email,
    fullName: profile.full_name,
    avatarUrl: profile.avatar_url,
    matricule: profile.matricule,
    phone: profile.phone,
    schoolId: profile.school_id,
    schoolName: school?.name ?? "",
    schoolTimezone: school?.timezone ?? "UTC",
    schoolLogoPath: school?.logo_path ?? null,
  };
}
