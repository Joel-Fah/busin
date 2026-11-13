/**
 * Who may use the student web app, and where everyone else goes. A port of the student app's `access.dart`, kept pure so
 * every case is a unit test. Only fields the server controls decide it (role, status, school); the setup check reads the
 * student's own details, which only change what they are asked to fill in.
 */
export type StudentProfile = {
  role: string;
  status: string;
  school_id: string | null;
  full_name: string | null;
  matricule: string | null;
  phone: string | null;
};

export type StudentAccess =
  | { kind: "signedOut" }
  | { kind: "blocked"; reason: "notStudent" | "suspended" }
  /** No school email and no request yet, or the last one was declined (ADR 0012): they choose a school. */
  | { kind: "needsSchool" }
  /** Asked to join, or put on hold by the school: they wait. */
  | { kind: "awaitingSchool" }
  /** Verified, but the school does not know who they are yet (student number, phone). */
  | { kind: "needsSetup" }
  | { kind: "allowed" };

/** Name, student number and phone, as `Profile.isSetupComplete`. */
export function isSetupComplete(profile: Pick<StudentProfile, "full_name" | "matricule" | "phone">): boolean {
  return Boolean(profile.full_name?.trim() && profile.matricule?.trim() && profile.phone?.trim());
}

/**
 * A staff or administrator account is turned away first, whatever its status, because those people have their own tools.
 * A missing profile (the sign-up trigger always makes one) is treated as signed out.
 */
export function studentAccess(profile: StudentProfile | null | undefined): StudentAccess {
  if (!profile) return { kind: "signedOut" };
  if (profile.role !== "student") return { kind: "blocked", reason: "notStudent" };
  switch (profile.status) {
    case "pending":
      return profile.school_id === null ? { kind: "needsSchool" } : { kind: "awaitingSchool" };
    case "verified":
      return isSetupComplete(profile) ? { kind: "allowed" } : { kind: "needsSetup" };
    default:
      return { kind: "blocked", reason: "suspended" };
  }
}

/** The page each state lives on. */
export const GATE_PATHS: Record<Exclude<StudentAccess["kind"], "allowed">, string> = {
  signedOut: "/app/sign-in",
  blocked: "/app/blocked",
  needsSchool: "/app/join",
  awaitingSchool: "/app/waiting",
  needsSetup: "/app/setup",
};
