import { describe, expect, it } from "vitest";

import { AA_TEXT, contrastRatio } from "./contrast";
import { TEXT_PAIRS, readColourTokens } from "./tokens";

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

const { light, dark } = readColourTokens();

describe.each([
  ["light", light],
  ["dark", dark],
])("%s theme text colours", (_name, theme) => {
  it.each(TEXT_PAIRS)("%s on %s meets WCAG AA", (fg, bg) => {
    expect(contrastRatio(theme[fg], theme[bg])).toBeGreaterThanOrEqual(AA_TEXT);
  });
});
