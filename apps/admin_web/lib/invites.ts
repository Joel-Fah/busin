/** Pure helpers for adding staff by email (ADR 0015). The database checks everything again. */

import { first } from "./pagination";

export const INVITE_ROLES = ["staff", "admin"] as const;
export type InviteRole = (typeof INVITE_ROLES)[number];

export const MAX_EMAIL_LENGTH = 254;

export function isInviteRole(value: unknown): value is InviteRole {
  return value === "staff" || value === "admin";
}

/** The email as the database keeps it (trimmed, lower case), or null when it is not an email. Same rule as the database. */
export function normalizeInviteEmail(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const email = value.trim().toLowerCase();
  if (email.length > MAX_EMAIL_LENGTH || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return null;
  return email;
}

export type InviteErrorKey = "invalid_email" | "invalid_role" | "self" | "other_school" | "student_account" | "account_not_active" | "last_admin" | "generic";
export type InviteDone = "invited" | "applied" | "cancelled";

/** Maps an error of `admin_invite_staff` (its code and message) to the message shown. */
export function inviteErrorKey(code: string | undefined, message: string | undefined): InviteErrorKey {
  if (code === "55000" && (message === "other_school" || message === "student_account" || message === "account_not_active" || message === "last_admin")) return message;
  if (code === "22023") return message === "invalid_role" ? "invalid_role" : "invalid_email";
  if (code === "42501") return "self";
  return "generic";
}

export function parseInviteError(value: string | string[] | undefined): InviteErrorKey | null {
  const raw = first(value);
  return raw === "invalid_email" || raw === "invalid_role" || raw === "self" || raw === "other_school" || raw === "student_account" || raw === "account_not_active" || raw === "last_admin" || raw === "generic" ? raw : null;
}

export function parseInviteDone(value: string | string[] | undefined): InviteDone | null {
  const raw = first(value);
  return raw === "invited" || raw === "applied" || raw === "cancelled" ? raw : null;
}

/** Days left before an invite runs out, at least 0, rounded up ("expires in 1 day" until the last moment). */
export function daysLeft(expiresAt: string, now: Date): number {
  return Math.max(0, Math.ceil((new Date(expiresAt).getTime() - now.getTime()) / 86_400_000));
}
