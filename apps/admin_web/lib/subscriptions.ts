/** Pure helpers for the subscription review pages. Kept separate so they are unit tested. */

import type { ChipTone } from "@/components/ui/Chip";

import { first } from "./pagination";

// Shared helpers live in their own modules; they are re-exported so existing imports keep working.
export { MAX_PAGE, PAGE_SIZE, pageRange, parsePage } from "./pagination";
export { isUuid } from "./ids";

export const MAX_REASON_LENGTH = 500;

export const STATUSES = ["pending", "approved", "rejected", "expired"] as const;
export type SubscriptionStatus = (typeof STATUSES)[number];
export type StatusFilter = SubscriptionStatus | "all";
export const FILTERS: readonly StatusFilter[] = ["pending", "approved", "rejected", "expired", "all"];

/** The status shown in the list. Anything unknown falls back to the review queue. */
export function parseStatusFilter(value: string | string[] | undefined): StatusFilter {
  const candidate = first(value);
  return FILTERS.find((filter) => filter === candidate) ?? "pending";
}

/** The tone of a status chip. The label always comes with it, so colour is never the only signal. */
export function statusTone(status: SubscriptionStatus): ChipTone {
  switch (status) {
    case "approved":
      return "ok";
    case "rejected":
      return "bad";
    case "expired":
      return "neutral";
    default:
      return "warn";
  }
}

/** Number of subscriptions for each tab. "all" is the sum, and a missing count counts as zero. */
export function tabCounts(byStatus: Partial<Record<SubscriptionStatus, number | null>>): Record<StatusFilter, number> {
  const get = (status: SubscriptionStatus) => byStatus[status] ?? 0;
  return {
    pending: get("pending"),
    approved: get("approved"),
    rejected: get("rejected"),
    expired: get("expired"),
    all: STATUSES.reduce((sum, status) => sum + get(status), 0),
  };
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
