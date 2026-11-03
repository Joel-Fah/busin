import { describe, expect, it } from "vitest";

import { placePanel, type Box } from "./placement";

const viewport = { width: 1000, height: 800 };
const panel = { width: 200, height: 240 };
const box = (left: number, top: number, w = 120, h = 44): Box => ({ left, top, right: left + w, bottom: top + h });

describe("placePanel", () => {
  it("opens below when there is room", () => {
    const result = placePanel({ anchor: box(100, 100), panel, viewport });
    expect(result.side).toBe("bottom");
    expect(result.top).toBe(100 + 44 + 8);
    expect(result.left).toBe(100);
  });

  it("opens above when the trigger is near the bottom of the screen", () => {
    const result = placePanel({ anchor: box(100, 720), panel, viewport });
    expect(result.side).toBe("top");
    expect(result.top).toBe(720 - 8 - 240);
  });

  it("keeps the preferred side when it fits, and flips when it does not", () => {
    expect(placePanel({ anchor: box(400, 300), panel, viewport, preferred: "right" }).side).toBe("right");
    expect(placePanel({ anchor: box(400, 300), panel, viewport, preferred: "left" }).side).toBe("left");
    expect(placePanel({ anchor: box(850, 300), panel, viewport, preferred: "right" }).side).toBe("left");
    expect(placePanel({ anchor: box(20, 300), panel, viewport, preferred: "left" }).side).toBe("right");
  });

  it("sits beside the trigger on the left and right, lined up with its top", () => {
    const right = placePanel({ anchor: box(400, 300), panel, viewport, preferred: "right" });
    expect(right.left).toBe(400 + 120 + 8);
    expect(right.top).toBe(300);
    const left = placePanel({ anchor: box(400, 300), panel, viewport, preferred: "left" });
    expect(left.left).toBe(400 - 8 - 200);
  });

  it("shifts back so the panel stays on screen near the right edge", () => {
    const result = placePanel({ anchor: box(900, 100), panel, viewport });
    expect(result.left + panel.width).toBeLessThanOrEqual(1000 - 8);
  });

  it("never lets the panel leave the screen, even when nothing fits", () => {
    const tiny = { width: 300, height: 200 };
    const result = placePanel({ anchor: box(100, 90, 100, 20), panel: { width: 250, height: 500 }, viewport: tiny });
    expect(result.top).toBeGreaterThanOrEqual(8);
    expect(result.left).toBeGreaterThanOrEqual(8);
  });

  it("falls back to the roomier side when neither up nor down fits", () => {
    const result = placePanel({ anchor: box(100, 300, 120, 44), panel: { width: 200, height: 700 }, viewport });
    expect(["top", "bottom", "left", "right"]).toContain(result.side);
    expect(result.top).toBeGreaterThanOrEqual(8);
  });
});
