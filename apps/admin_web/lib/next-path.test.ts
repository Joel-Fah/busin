import { describe, expect, it } from "vitest";

import { safeNext } from "./next-path";

describe("returning after a quick detour", () => {
  it("accepts only the portal pages it knows", () => {
    expect(safeNext("/trips/new")).toBe("/trips/new");
    expect(safeNext("/")).toBe("/");
    expect(safeNext("https://example.com")).toBeNull();
    expect(safeNext("//example.com")).toBeNull();
    expect(safeNext("/trips/new?x=1")).toBeNull();
    expect(safeNext(null)).toBeNull();
  });
});
