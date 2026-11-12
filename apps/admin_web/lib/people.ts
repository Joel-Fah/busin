/** Pure helpers for the people pages. Kept separate so they are unit tested. */

import { first } from "./pagination";

export const ROLES = ["student", "staff", "admin"] as const;
export type Role = (typeof ROLES)[number];
/**
 * A tab of the people list: everyone, a role, "verify" (students without a school email who asked to join), or "invited"
 * (people added by email who have not signed in yet, ADR 0015).
 */
export type RoleFilter = Role | "all" | "verify" | "invited";
export const ROLE_FILTERS: readonly RoleFilter[] = ["all", "verify", "invited", "student", "staff", "admin"];

export type AccountStatus = "pending" | "verified" | "suspended";

export const MAX_SEARCH_LENGTH = 64;

export function isRole(value: unknown): value is Role {
  return typeof value === "string" && (ROLES as readonly string[]).includes(value);
}

/** The role filter shown in the list. Anything unknown means everyone. */
export function parseRoleFilter(value: string | string[] | undefined): RoleFilter {
  const candidate = first(value);
  return ROLE_FILTERS.find((filter) => filter === candidate) ?? "all";
}

/**
 * Cleans a search box value before it is placed in a PostgREST filter. Commas, brackets, quotes,
 * wildcards and backslashes have meaning in that syntax, so they are removed rather than escaped.
 * Returns an empty string when nothing searchable is left.
 */
export function parseSearch(value: string | string[] | undefined): string {
  const raw = first(value) ?? "";
  return raw
    .replace(/[,()"'%*\\]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, MAX_SEARCH_LENGTH)
    .trim();
}

/** The `or` filter that matches a name, an email or a matricule. `query` must come from parseSearch. */
export function searchFilter(query: string): string {
  return ["full_name", "email", "matricule"].map((column) => `${column}.ilike.%${query}%`).join(",");
}

/** Up to two capital letters for an avatar. */
export function initials(fullName: string | null | undefined, email: string | null | undefined): string {
  const source = (fullName ?? "").trim() || (email ?? "").trim();
  if (!source) return "?";
  const words = source.split(/[\s@._-]+/).filter(Boolean);
  if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
  const word = words[0] ?? source;
  return word.slice(0, 2).toUpperCase();
}

/** Tones for the role and account chips. The label always comes with the tone. */
export function roleTone(role: Role): "info" | "warn" | "neutral" {
  switch (role) {
    case "admin":
      return "info";
    case "staff":
      return "warn";
    default:
      return "neutral";
  }
}

export function accountTone(status: AccountStatus): "ok" | "bad" | "warn" {
  switch (status) {
    case "verified":
      return "ok";
    case "suspended":
      return "bad";
    default:
      return "warn";
  }
}

/** Number of people for each tab. "all" is the sum of the roles, and a missing count counts as zero. */
export function roleTabCounts(byRole: Partial<Record<Role, number | null>>, toVerify: number | null = 0, invited: number | null = 0): Record<RoleFilter, number> {
  const get = (role: Role) => byRole[role] ?? 0;
  return {
    all: ROLES.reduce((sum, role) => sum + get(role), 0),
    verify: toVerify ?? 0,
    invited: invited ?? 0,
    student: get("student"),
    staff: get("staff"),
    admin: get("admin"),
  };
}

export type PeopleErrorKey = "self" | "invalid" | "not_found" | "reason_too_short" | "reason_too_long" | "generic";

/**
 * Maps the database error code of `admin_set_user_role` and `admin_set_user_status`.
 * The portal only calls them for administrators, so 42501 means the admin tried to change themselves.
 */
export function peopleErrorKey(code: string | undefined, message?: string): PeopleErrorKey {
  if (code === "22023" && (message === "reason_too_short" || message === "reason_too_long")) return message;
  switch (code) {
    case "42501":
      return "self";
    case "22023":
      return "invalid";
    case "P0002":
      return "not_found";
    default:
      return "generic";
  }
}

export function isPeopleErrorKey(value: string | undefined): value is PeopleErrorKey {
  return value === "self" || value === "invalid" || value === "not_found" || value === "reason_too_short" || value === "reason_too_long" || value === "generic";
}

export type PeopleDone = "role" | "suspended" | "restored" | "verified" | "declined" | "withdrawn";

export function isPeopleDone(value: string | undefined): value is PeopleDone {
  return value === "role" || value === "suspended" || value === "restored" || value === "verified" || value === "declined" || value === "withdrawn";
}

/** The longest reason an admin can give when declining a request to join (the database keeps the same limit). */
export const MAX_DECLINE_REASON = 300;
