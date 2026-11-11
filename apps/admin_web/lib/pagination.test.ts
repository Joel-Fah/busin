import { describe, expect, it } from "vitest";

import { PAGE_SIZE, PAGE_SIZES, lastPage, pageRange, parsePageSize, sizeParam } from "./pagination";
import { scansHref } from "./scans";
import { subscriptionsHref } from "./subscriptions";
import { tripsHref } from "./trips";

describe("page size", () => {
  it("accepts only the offered sizes, and the largest is the cap", () => {
    expect(PAGE_SIZES).toEqual([10, 20, 50, 100]);
    expect(parsePageSize("50")).toBe(50);
    expect(parsePageSize(["100", "10"])).toBe(100);
    expect(parsePageSize("1000")).toBe(PAGE_SIZE);
    expect(parsePageSize("7")).toBe(PAGE_SIZE);
    expect(parsePageSize("abc")).toBe(PAGE_SIZE);
    expect(parsePageSize(undefined)).toBe(PAGE_SIZE);
  });

  it("leaves the default out of addresses", () => {
    expect(sizeParam(20)).toBeNull();
    expect(sizeParam(undefined)).toBeNull();
    expect(sizeParam(50)).toBe(50);
  });

  it("counts rows and pages with the chosen size", () => {
    expect(pageRange(3, 50)).toEqual({ from: 100, to: 149 });
    expect(lastPage(101, 50)).toBe(3);
    expect(lastPage(101, 100)).toBe(2);
  });

  it("keeps the size in every list's address, with its filters", () => {
    expect(subscriptionsHref({ status: "pending", semester: null, stop: null, size: 50 }, 2)).toBe("/subscriptions?size=50&page=2");
    expect(subscriptionsHref({ status: "pending", semester: null, stop: null, size: 20 })).toBe("/subscriptions");
    expect(tripsHref({ status: "all", date: null, bus: null, direction: null, driver: null, size: 100 })).toBe("/trips?size=100");
    expect(scansHref({ trip: null, stop: null, date: null, bus: null, direction: null, size: 10 })).toBe("/scans?size=10");
  });
});
