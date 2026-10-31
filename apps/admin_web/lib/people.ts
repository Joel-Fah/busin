/** Pure helpers for the people pages. Kept separate so they are unit tested. */

import { first } from "./pagination";

export const ROLES = ["student", "staff", "admin"] as const;
export type Role = (typeof ROLES)[number];
export type RoleFilter = Role | "all";
export const ROLE_FILTERS: readonly RoleFilter[] = ["all", "student", "staff", "admin"];

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

export function rolePill(role: Role): string {
  switch (role) {
    case "admin":
      return "pill pill-info";
    case "staff":
      return "pill pill-warn";
    default:
      return "pill";
  }
}

export function accountPill(status: AccountStatus): string {
  switch (status) {
    case "verified":
      return "pill pill-ok";
    case "suspended":
      return "pill pill-bad";
    default:
      return "pill pill-warn";
  }
}

export type PeopleErrorKey = "self" | "invalid" | "not_found" | "generic";

/**
 * Maps the database error code of `admin_set_user_role` and `admin_set_user_status`.
 * The portal only calls them for administrators, so 42501 means the admin tried to change themselves.
 */
export function peopleErrorKey(code: string | undefined): PeopleErrorKey {
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
  return value === "self" || value === "invalid" || value === "not_found" || value === "generic";
}

export type PeopleDone = "role" | "suspended" | "restored";

export function isPeopleDone(value: string | undefined): value is PeopleDone {
  return value === "role" || value === "suspended" || value === "restored";
}
