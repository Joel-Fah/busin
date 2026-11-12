import { describe, expect, it } from "vitest";

import { parseSubscriptionFilters, subscriptionsHref } from "./subscriptions";

const ID = "a1000000-0000-4000-8000-000000000001";

describe("subscription filters", () => {
  it("defaults to the review queue and reads valid filters", () => {
    expect(parseSubscriptionFilters({})).toEqual({ status: "pending", semester: null, stop: null, size: 20 });
    expect(parseSubscriptionFilters({ status: "approved", semester: ID, stop: ID })).toEqual({ status: "approved", semester: ID, stop: ID, size: 20 });
    expect(parseSubscriptionFilters({ semester: "x", stop: "'; drop" })).toEqual({ status: "pending", semester: null, stop: null, size: 20 });
  });

  it("builds addresses, with the review queue as the plain one", () => {
    expect(subscriptionsHref({ status: "pending", semester: null, stop: null })).toBe("/subscriptions");
    expect(subscriptionsHref({ status: "all", semester: ID, stop: null }, 2)).toBe(`/subscriptions?status=all&semester=${ID}&page=2`);
  });
});
