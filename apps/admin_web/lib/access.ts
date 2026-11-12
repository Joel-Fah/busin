/** Who may use the portal. Kept as a pure function so the rule is unit tested. */
export type AccessProfile = { role: string; status: string } | null | undefined;

export type AccessDecision = "admin" | "forbidden";

/** Only a verified administrator may enter. Suspended or pending accounts never do. */
export function decideAccess(profile: AccessProfile): AccessDecision {
  if (profile && profile.role === "admin" && profile.status === "verified") {
    return "admin";
  }
  return "forbidden";
}
