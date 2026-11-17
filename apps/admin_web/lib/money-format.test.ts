import { describe, expect, it } from "vitest";

import { compactAmount, shownAmount } from "./money-format";

const plain = (s: string | null) => s?.replace(/[  ]/g, " ");

describe("short amounts", () => {
  it("keeps amounts under 100,000 whole", () => {
    expect(compactAmount(99_999, "en")).toBeNull();
    expect(shownAmount(20_000, "en")).toEqual({ text: "20,000 XAF", full: "20,000 XAF", short: false });
  });

  it("writes thousands and millions short, with one decimal at most", () => {
    expect(compactAmount(120_000, "en")).toBe("120K XAF");
    expect(compactAmount(1_234_567, "en")).toBe("1.2M XAF");
    expect(compactAmount(2_500_000_000, "en")).toBe("2.5B XAF");
    expect(compactAmount(-450_000, "en")).toBe("-450K XAF");
  });

  it("follows the reader's language", () => {
    expect(plain(compactAmount(120_000, "fr"))).toBe("120 k XAF");
    expect(plain(compactAmount(1_234_567, "fr"))).toBe("1,2 M XAF");
  });

  it("keeps the exact amount for the hover", () => {
    expect(shownAmount(1_234_567, "en")).toEqual({ text: "1.2M XAF", full: "1,234,567 XAF", short: true });
  });
});
