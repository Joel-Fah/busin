import { FlagTriangleRightIcon, Flag01Icon, Bus01Icon, Navigation03Icon } from "@hugeicons/core-free-icons";
import { describe, expect, it } from "vitest";

import { ICON_STROKE, iconStrokeWidth, isFilledOutline } from "./icons";

describe("isFilledOutline", () => {
  it("spots the icon that ships as one filled path", () => {
    expect(isFilledOutline(FlagTriangleRightIcon)).toBe(true);
  });

  it("leaves normal stroked icons alone", () => {
    for (const icon of [Flag01Icon, Bus01Icon, Navigation03Icon]) expect(isFilledOutline(icon)).toBe(false);
  });
});

describe("iconStrokeWidth", () => {
  it("uses the full weight for stroked icons", () => {
    expect(iconStrokeWidth(Bus01Icon)).toBe(ICON_STROKE);
  });

  it("adds only the difference for filled outlines, so they match their neighbours", () => {
    expect(iconStrokeWidth(FlagTriangleRightIcon)).toBeCloseTo(0.3, 5);
  });
});
