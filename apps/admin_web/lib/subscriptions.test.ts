import { describe, expect, it } from "vitest";

import {
  MAX_PAGE,
  MAX_REASON_LENGTH,
  PAGE_SIZE,
  isUuid,
  pageRange,
  parsePage,
  parseStatusFilter,
  reviewErrorKey,
  statusTone,
  tabCounts,
  isReviewErrorKey,
  revokeErrorKey,
  eventTone,
  orderHistory,
  reinstateErrorKey,
  isLiveStatus,
  liveRequest,
  summarizeStatuses,
} from "./subscriptions";

describe("parseStatusFilter", () => {
  it("defaults to the review queue", () => {
    expect(parseStatusFilter(undefined)).toBe("pending");
    expect(parseStatusFilter("")).toBe("pending");
  });

  it("accepts the known filters", () => {
    for (const filter of ["pending", "approved", "rejected", "expired", "revoked", "all"]) {
      expect(parseStatusFilter(filter)).toBe(filter);
    }
  });

  it("rejects unknown values and uses the first of repeated values", () => {
    expect(parseStatusFilter("drop table")).toBe("pending");
    expect(parseStatusFilter(["approved", "rejected"])).toBe("approved");
  });
});

describe("parsePage", () => {
  it("defaults to 1 for missing or invalid values", () => {
    expect(parsePage(undefined)).toBe(1);
    expect(parsePage("abc")).toBe(1);
    expect(parsePage("0")).toBe(1);
    expect(parsePage("-4")).toBe(1);
  });

  it("parses a normal page and caps huge ones", () => {
    expect(parsePage("3")).toBe(3);
    expect(parsePage("99999999")).toBe(MAX_PAGE);
  });
});

describe("pageRange", () => {
  it("gives inclusive ranges", () => {
    expect(pageRange(1)).toEqual({ from: 0, to: PAGE_SIZE - 1 });
    expect(pageRange(2)).toEqual({ from: PAGE_SIZE, to: PAGE_SIZE * 2 - 1 });
    expect(pageRange(3, 10)).toEqual({ from: 20, to: 29 });
  });
});

describe("the reasons of the review pages", () => {
  it("are held to the shared rules (10 to 500 characters, tidied)", async () => {
    const { checkReason } = await import("./reasons");
    expect(checkReason("  Receipt is   unreadable  ", { required: true, max: MAX_REASON_LENGTH })).toEqual({ ok: true, value: "Receipt is unreadable" });
    expect(checkReason("", { required: true, max: MAX_REASON_LENGTH })).toEqual({ ok: false, problem: "reason_required" });
    expect(checkReason("x".repeat(MAX_REASON_LENGTH + 1), { required: true, max: MAX_REASON_LENGTH })).toEqual({ ok: false, problem: "reason_too_long" });
  });
});

describe("reviewErrorKey", () => {
  it("maps the database error codes", () => {
    expect(reviewErrorKey("55000")).toBe("already_reviewed");
    expect(reviewErrorKey("22023")).toBe("invalid");
    expect(reviewErrorKey("P0002")).toBe("not_found");
    expect(reviewErrorKey("XX000")).toBe("generic");
    expect(reviewErrorKey(undefined)).toBe("generic");
  });

  it("tells the new refusals apart by the database's short message", () => {
    expect(reviewErrorKey("22023", "proof_required")).toBe("proof_required");
    expect(reviewErrorKey("55000", "semester_ended")).toBe("semester_ended");
    expect(reviewErrorKey("55000", "Only pending subscriptions can be reviewed")).toBe("already_reviewed");
    expect(reinstateErrorKey("55000", "semester_ended")).toBe("semester_ended");
    expect(reviewErrorKey("55000", "account_suspended")).toBe("account_suspended");
    expect(revokeErrorKey("55000", "account_suspended")).toBe("account_suspended");
    expect(reinstateErrorKey("55000", "account_suspended")).toBe("account_suspended");
  });
});

describe("isUuid", () => {
  it("accepts a uuid and refuses anything else", () => {
    expect(isUuid("a1000000-0000-4000-8000-000000000001")).toBe(true);
    expect(isUuid("not-a-uuid")).toBe(false);
    expect(isUuid("a1000000-0000-4000-8000-000000000001; drop")).toBe(false);
    expect(isUuid(undefined)).toBe(false);
  });
});

describe("statusTone", () => {
  it("gives each status its own tone", () => {
    expect(statusTone("pending")).toBe("warn");
    expect(statusTone("approved")).toBe("ok");
    expect(statusTone("rejected")).toBe("bad");
    expect(statusTone("expired")).toBe("neutral");
    expect(statusTone("revoked")).toBe("bad");
  });
});

describe("revokeErrorKey", () => {
  it("maps the database codes of the revoke function", () => {
    expect(revokeErrorKey("55000")).toBe("not_approved");
    expect(revokeErrorKey("22023")).toBe("invalid");
    expect(revokeErrorKey("P0002")).toBe("not_found");
    expect(revokeErrorKey("42501")).toBe("generic");
    expect(revokeErrorKey(undefined)).toBe("generic");
  });

  it("every key it can return has words", () => {
    for (const key of ["not_approved", "invalid", "not_found", "generic"]) expect(isReviewErrorKey(key)).toBe(true);
  });
});

describe("tabCounts", () => {
  it("adds up the total and treats a missing count as zero", () => {
    expect(tabCounts({ pending: 3, approved: 10, rejected: 1, expired: null, revoked: 2 })).toEqual({
      pending: 3,
      approved: 10,
      rejected: 1,
      expired: 0,
      revoked: 2,
      all: 16,
    });
    expect(tabCounts({}).all).toBe(0);
  });
});

describe("reinstateErrorKey", () => {
  it("tells apart the two refusals of the same code by the database message", () => {
    expect(reinstateErrorKey("55000", "Only revoked subscriptions can be reinstated")).toBe("not_revoked");
    expect(reinstateErrorKey("55000", "The student already has a live subscription for this semester")).toBe("live_exists");
    expect(reinstateErrorKey("55000")).toBe("not_revoked");
  });
  it("maps the other codes", () => {
    expect(reinstateErrorKey("22023")).toBe("invalid");
    expect(reinstateErrorKey("P0002")).toBe("not_found");
    expect(reinstateErrorKey("42501")).toBe("generic");
  });
  it("every key it can return has words", () => {
    for (const key of ["not_revoked", "live_exists"]) expect(isReviewErrorKey(key)).toBe(true);
  });
});

describe("eventTone", () => {
  it("good news is green, bad news is red, a request is neutral information", () => {
    expect(eventTone("approved")).toBe("ok");
    expect(eventTone("reinstated")).toBe("ok");
    expect(eventTone("rejected")).toBe("bad");
    expect(eventTone("revoked")).toBe("bad");
    expect(eventTone("requested")).toBe("info");
  });
});

describe("orderHistory", () => {
  const op = (action: "requested" | "approved" | "revoked" | "reinstated", at: string) => ({ action, at, actorName: null, byStudent: false, note: null });

  it("puts the latest request first, and the latest operation first inside each", () => {
    const first = {
      id: "a",
      status: "approved" as const,
      createdAt: "2026-11-01T08:00:00Z",
      stopName: "A",
      operations: [op("requested", "2026-11-01T08:00:00Z"), op("reinstated", "2026-11-05T08:00:00Z"), op("approved", "2026-11-02T08:00:00Z")],
    };
    const second = { id: "b", status: "pending" as const, createdAt: "2026-11-03T08:00:00Z", stopName: null, operations: [op("requested", "2026-11-03T08:00:00Z")] };
    const ordered = orderHistory([first, second]);
    expect(ordered.map((r) => r.id)).toEqual(["b", "a"]);
    expect(ordered[1].operations.map((o) => o.action)).toEqual(["reinstated", "approved", "requested"]);
  });

  it("does not change what it was given", () => {
    const input = [{ id: "a", status: "pending" as const, createdAt: "2026-11-01T08:00:00Z", stopName: null, operations: [op("requested", "2026-11-01T08:00:00Z"), op("approved", "2026-11-02T08:00:00Z")] }];
    orderHistory(input);
    expect(input[0].operations[0].action).toBe("requested");
  });
});

describe("live requests and the summary of a student's requests", () => {
  it("knows which states are live", () => {
    expect(isLiveStatus("pending")).toBe(true);
    expect(isLiveStatus("approved")).toBe(true);
    for (const s of ["revoked", "rejected", "expired"] as const) expect(isLiveStatus(s)).toBe(false);
  });

  it("finds the live request in a history, newest first, or none", () => {
    expect(liveRequest([{ id: "b", status: "pending" as const }, { id: "a", status: "revoked" as const }])?.id).toBe("b");
    expect(liveRequest([{ id: "a", status: "revoked" as const }, { id: "c", status: "rejected" as const }])).toBeUndefined();
    expect(liveRequest([])).toBeUndefined();
  });

  it("counts requests by state in a fixed order and leaves out the empty states", () => {
    expect(summarizeStatuses(["revoked", "pending"])).toEqual([
      { status: "pending", count: 1 },
      { status: "revoked", count: 1 },
    ]);
    expect(summarizeStatuses(["rejected", "rejected", "approved", "revoked", "revoked"])).toEqual([
      { status: "approved", count: 1 },
      { status: "revoked", count: 2 },
      { status: "rejected", count: 2 },
    ]);
    expect(summarizeStatuses([])).toEqual([]);
  });
});
