import { describe, expect, it } from "vitest";

import {
  MAX_PAGE,
  MAX_REASON_LENGTH,
  PAGE_SIZE,
  isUuid,
  pageRange,
  parsePage,
  parseReason,
  parseStatusFilter,
  pillClass,
  reviewErrorKey,
} from "./subscriptions";

describe("parseStatusFilter", () => {
  it("defaults to the review queue", () => {
    expect(parseStatusFilter(undefined)).toBe("pending");
    expect(parseStatusFilter("")).toBe("pending");
  });

  it("accepts the known filters", () => {
    for (const filter of ["pending", "approved", "rejected", "expired", "all"]) {
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

describe("parseReason", () => {
  it("trims and accepts a normal reason", () => {
    expect(parseReason("  Receipt is unreadable  ")).toBe("Receipt is unreadable");
  });

  it("refuses empty, blank, non-text and over-long reasons", () => {
    expect(parseReason("")).toBeNull();
    expect(parseReason("   ")).toBeNull();
    expect(parseReason(null)).toBeNull();
    expect(parseReason(42)).toBeNull();
    expect(parseReason("x".repeat(MAX_REASON_LENGTH + 1))).toBeNull();
    expect(parseReason("x".repeat(MAX_REASON_LENGTH))).not.toBeNull();
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
});

describe("isUuid", () => {
  it("accepts a uuid and refuses anything else", () => {
    expect(isUuid("a1000000-0000-4000-8000-000000000001")).toBe(true);
    expect(isUuid("not-a-uuid")).toBe(false);
    expect(isUuid("a1000000-0000-4000-8000-000000000001; drop")).toBe(false);
    expect(isUuid(undefined)).toBe(false);
  });
});

describe("pillClass", () => {
  it("has a distinct class per status", () => {
    const classes = (["pending", "approved", "rejected", "expired"] as const).map(pillClass);
    expect(new Set(classes).size).toBe(4);
  });
});
