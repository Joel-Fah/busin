/** Pure helpers for the subscription review pages. Kept separate so they are unit tested. */

export const PAGE_SIZE = 20;
export const MAX_PAGE = 10_000;
export const MAX_REASON_LENGTH = 500;

export const STATUSES = ["pending", "approved", "rejected", "expired"] as const;
export type SubscriptionStatus = (typeof STATUSES)[number];
export type StatusFilter = SubscriptionStatus | "all";
export const FILTERS: readonly StatusFilter[] = ["pending", "approved", "rejected", "expired", "all"];

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isUuid(value: unknown): value is string {
  return typeof value === "string" && UUID.test(value);
}

function first(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

/** The status shown in the list. Anything unknown falls back to the review queue. */
export function parseStatusFilter(value: string | string[] | undefined): StatusFilter {
  const candidate = first(value);
  return FILTERS.find((filter) => filter === candidate) ?? "pending";
}

/** A 1-based page number, clamped to a sensible range. */
export function parsePage(value: string | string[] | undefined): number {
  const parsed = Number.parseInt(first(value) ?? "", 10);
  if (!Number.isFinite(parsed) || parsed < 1) return 1;
  return Math.min(parsed, MAX_PAGE);
}

/** Inclusive row range for PostgREST `range(from, to)`. */
export function pageRange(page: number, size: number = PAGE_SIZE): { from: number; to: number } {
  const from = (page - 1) * size;
  return { from, to: from + size - 1 };
}

export function pillClass(status: SubscriptionStatus): string {
  switch (status) {
    case "approved":
      return "pill pill-ok";
    case "rejected":
      return "pill pill-bad";
    case "expired":
      return "pill pill-info";
    default:
      return "pill pill-warn";
  }
}

/** Trimmed reason, or null when it is empty or too long. */
export function parseReason(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const value = raw.trim();
  if (value.length === 0 || value.length > MAX_REASON_LENGTH) return null;
  return value;
}

export type ReviewErrorKey = "already_reviewed" | "invalid" | "not_found" | "generic";

/** Maps the database error code of `admin_review_subscription` to a message key. */
export function reviewErrorKey(code: string | undefined): ReviewErrorKey {
  switch (code) {
    case "55000":
      return "already_reviewed";
    case "22023":
      return "invalid";
    case "P0002":
      return "not_found";
    default:
      return "generic";
  }
}

export function isReviewErrorKey(value: string | undefined): value is ReviewErrorKey {
  return value === "already_reviewed" || value === "invalid" || value === "not_found" || value === "generic";
}
