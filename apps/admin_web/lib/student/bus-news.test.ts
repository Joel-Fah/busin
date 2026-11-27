import { describe, expect, it } from "vitest";

import { hasNews } from "./bus-news";

describe("the dot on My bus", () => {
  it("shows while a running trip has not been looked at", () => {
    expect(hasNews(["t1", "t2"], new Set(["t1"]))).toBe(true);
    expect(hasNews(["t1"], new Set(["t1", "t0"]))).toBe(false);
    expect(hasNews([], new Set())).toBe(false);
  });
});
