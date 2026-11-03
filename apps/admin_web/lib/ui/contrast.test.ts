import { describe, expect, it } from "vitest";

import { AA_TEXT, contrastRatio } from "./contrast";
import { DARK, LIGHT, TEXT_PAIRS } from "./tokens";

describe("contrastRatio", () => {
  it("matches the known extremes", () => {
    expect(contrastRatio("#000000", "#ffffff")).toBeCloseTo(21, 5);
    expect(contrastRatio("#ffffff", "#ffffff")).toBeCloseTo(1, 5);
  });

  it("does not depend on argument order", () => {
    expect(contrastRatio("#002a33", "#f4f8f8")).toBeCloseTo(contrastRatio("#f4f8f8", "#002a33"), 10);
  });

  it("rejects values that are not #rrggbb", () => {
    expect(() => contrastRatio("red", "#ffffff")).toThrow();
  });
});


describe.each([
  ["light", LIGHT],
  ["dark", DARK],
])("%s theme text colours", (_name, theme) => {
  it.each(TEXT_PAIRS)("%s on %s meets WCAG AA", (fg, bg) => {
    expect(contrastRatio(theme[fg], theme[bg])).toBeGreaterThanOrEqual(AA_TEXT);
  });
});
