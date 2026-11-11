import { describe, expect, it } from "vitest";

import { fitPadding, focusOffset } from "./fit";

describe("fitting under a dock", () => {
  it("adds the covered share to the bottom padding", () => {
    expect(fitPadding(900)).toEqual({ top: 56, left: 56, right: 56, bottom: 56 });
    expect(fitPadding(900, 0.4)).toEqual({ top: 56, left: 56, right: 56, bottom: 416 });
    expect(fitPadding(900, 2).bottom).toBe(56 + 720);
  });

  it("moves a focused point up by half the covered part", () => {
    expect(focusOffset(900, 0.4)).toEqual([0, -180]);
    expect(focusOffset(900)[1]).toBe(-0);
  });
});
