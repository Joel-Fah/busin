import { describe, expect, it } from "vitest";

import { toneOf, trend } from "./money-tones";

describe("money tones", () => {
  it("a margin takes the colour of its sign; fixed tones stay", () => {
    expect(toneOf("signed", 1200)).toBe("ok");
    expect(toneOf("signed", -50)).toBe("bad");
    expect(toneOf("signed", 0)).toBe("neutral");
    expect(toneOf("warn", -10)).toBe("warn");
  });

  it("a rise is good for money in and bad for costs; the percentage is against last month", () => {
    expect(trend(1200, 1000)).toEqual({ direction: "up", percent: 20, tone: "ok" });
    expect(trend(800, 1000)).toEqual({ direction: "down", percent: 20, tone: "bad" });
    expect(trend(1200, 1000, false)).toEqual({ direction: "up", percent: 20, tone: "bad" });
    expect(trend(800, 1000, false)).toEqual({ direction: "down", percent: 20, tone: "ok" });
  });

  it("a rise from nothing has no percentage, and no change is flat", () => {
    expect(trend(500, 0)).toEqual({ direction: "up", percent: null, tone: "ok" });
    expect(trend(1000, 1000)).toEqual({ direction: "flat", percent: 0, tone: "neutral" });
    expect(trend(1002, 1000).direction).toBe("flat");
  });

  it("a margin going from a loss to a smaller loss is a rise", () => {
    expect(trend(-200, -1000)).toEqual({ direction: "up", percent: 80, tone: "ok" });
  });
});
