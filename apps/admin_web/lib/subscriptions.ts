/** Pure helpers for the subscription review pages. Kept separate so they are unit tested. */

import type { ChipTone } from "@/components/ui/Chip";

import { listHref, uuidParam } from "./filters";
import { first, parsePageSize, sizeParam } from "./pagination";

// Shared helpers live in their own modules; they are re-exported so existing imports keep working.
export { MAX_PAGE, PAGE_SIZE, pageRange, parsePage } from "./pagination";
export { isUuid } from "./ids";

export const MAX_REASON_LENGTH = 500;

export const STATUSES = ["pending", "approved", "rejected", "expired", "revoked"] as const;
export type SubscriptionStatus = (typeof STATUSES)[number];
export type StatusFilter = SubscriptionStatus | "all";
export const FILTERS: readonly StatusFilter[] = ["pending", "approved", "rejected", "expired", "revoked", "all"];

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
    case "revoked":
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
    revoked: get("revoked"),
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

export type ReviewErrorKey = "already_reviewed" | "invalid" | "not_found" | "not_approved" | "not_revoked" | "live_exists" | "generic";

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

/** Maps the database error code of `admin_revoke_subscription` to a message key. */
export function revokeErrorKey(code: string | undefined): ReviewErrorKey {
  switch (code) {
    case "55000":
      return "not_approved";
    case "22023":
      return "invalid";
    case "P0002":
      return "not_found";
    default:
      return "generic";
  }
}

/**
 * Maps the database error of `admin_reinstate_subscription`. The two 55000 refusals have different messages: the message
 * text of the database tells them apart (not revoked, or a newer live subscription in the way).
 */
export function reinstateErrorKey(code: string | undefined, message?: string): ReviewErrorKey {
  switch (code) {
    case "55000":
      return message?.includes("already has a live") ? "live_exists" : "not_revoked";
    case "22023":
      return "invalid";
    case "P0002":
      return "not_found";
    default:
      return "generic";
  }
}

const REVIEW_ERRORS: readonly string[] = ["already_reviewed", "invalid", "not_found", "not_approved", "not_revoked", "live_exists", "generic"];

export function isReviewErrorKey(value: string | undefined): value is ReviewErrorKey {
  return typeof value === "string" && REVIEW_ERRORS.includes(value);
}

export const EVENT_ACTIONS = ["requested", "approved", "rejected", "revoked", "reinstated"] as const;
export type EventAction = (typeof EVENT_ACTIONS)[number];

/** One operation on a subscription, as the history shows it. */
export type SubscriptionOperation = { action: EventAction; at: string; actorName: string | null; byStudent: boolean; note: string | null };

/** The tone of an operation's chip. Words always come with it. */
export function eventTone(action: EventAction): ChipTone {
  switch (action) {
    case "approved":
    case "reinstated":
      return "ok";
    case "rejected":
    case "revoked":
      return "bad";
    default:
      return "info";
  }
}

export function isEventAction(value: string): value is EventAction {
  return (EVENT_ACTIONS as readonly string[]).includes(value);
}

export type RequestHistory = {
  id: string;
  status: SubscriptionStatus;
  createdAt: string;
  stopName: string | null;
  operations: SubscriptionOperation[];
};

/**
 * Puts a student's requests of a semester in the order the history shows them: the latest request first (it opens), and
 * inside each, the latest operation first. Unknown actions are left out rather than guessed.
 */
export function orderHistory(requests: RequestHistory[]): RequestHistory[] {
  return [...requests]
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
    .map((r) => ({ ...r, operations: [...r.operations].sort((a, b) => b.at.localeCompare(a.at)) }));
}

export type SubscriptionFilters = {
  status: StatusFilter;
  /** A semester id, or null for all semesters. */
  semester: string | null;
  /** A stop id, or null for all stops. */
  stop: string | null;
  /** Rows per page (one of PAGE_SIZES); left out means the default. */
  size?: number;
};

/** Reads the list's filters from its query string. Anything malformed means "no filter". */
export function parseSubscriptionFilters(query: {
  status?: string | string[];
  semester?: string | string[];
  stop?: string | string[];
  size?: string | string[];
}): SubscriptionFilters {
  return { status: parseStatusFilter(query.status), semester: uuidParam(query.semester), stop: uuidParam(query.stop), size: parsePageSize(query.size) };
}

/** The address of the list for these filters. The review queue is the plain address, so it carries no status. */
export function subscriptionsHref(filters: SubscriptionFilters, page = 1): string {
  return listHref("/subscriptions", {
    status: filters.status === "pending" ? null : filters.status,
    semester: filters.semester,
    stop: filters.stop,
    size: sizeParam(filters.size),
    page: page > 1 ? page : null,
  });
}

/** Pending and approved are the live states: a student can have only one of them per semester. */
export function isLiveStatus(status: SubscriptionStatus): boolean {
  return status === "pending" || status === "approved";
}

const SUMMARY_ORDER: readonly SubscriptionStatus[] = ["pending", "approved", "revoked", "rejected", "expired"];

/** How many requests a student has made in each state, in a fixed order, leaving out the states with none. */
export function summarizeStatuses(statuses: readonly SubscriptionStatus[]): { status: SubscriptionStatus; count: number }[] {
  return SUMMARY_ORDER.map((status) => ({ status, count: statuses.filter((s) => s === status).length })).filter((item) => item.count > 0);
}

/** The request that is pending or approved, if any (the history is newest first). */
export function liveRequest<T extends { status: SubscriptionStatus }>(history: readonly T[]): T | undefined {
  return history.find((request) => isLiveStatus(request.status));
}
