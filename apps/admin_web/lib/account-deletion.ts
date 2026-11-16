/**
 * Account deletion in the web apps (ADR 0028): what the database says about a scheduled deletion, the refusals the
 * pages explain, and where the forms may send the person back to.
 */

export type ScheduledDeletion = { dueAt: string; by: "self" | "platform" };

export function parseScheduled(rows: unknown): ScheduledDeletion | null {
  const row = Array.isArray(rows) ? rows[0] : null;
  if (!row || typeof row !== "object") return null;
  const r = row as Record<string, unknown>;
  if (typeof r.due_at !== "string" || r.due_at.trim() === "") return null;
  return { dueAt: r.due_at, by: r.requested_by === "platform" ? "platform" : "self" };
}

export const DELETION_ERRORS = ["last_admin", "active_trip", "generic"] as const;
export type DeletionError = (typeof DELETION_ERRORS)[number];

export function deletionErrorKey(message: string | null | undefined): DeletionError {
  const key = (message ?? "").trim();
  return key === "last_admin" || key === "active_trip" ? key : "generic";
}

export function isDeletionError(value: unknown): value is DeletionError {
  return typeof value === "string" && (DELETION_ERRORS as readonly string[]).includes(value);
}

/** The profile pages that hold the deletion card: a form may only send the person back to one of them. */
export const DELETION_PAGES = ["/profile", "/app/profile", "/platform/account"] as const;

export function deletionBack(value: unknown): (typeof DELETION_PAGES)[number] {
  return (DELETION_PAGES as readonly unknown[]).includes(value) ? (value as (typeof DELETION_PAGES)[number]) : "/app/profile";
}
