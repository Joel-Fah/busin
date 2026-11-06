import { describe, expect, it } from "vitest";

import { TOAST_DURATION, nextToast, toastDuration, type ToastItem } from "./toast";

describe("toastDuration", () => {
  it("keeps good news short and problems long", () => {
    expect(TOAST_DURATION.ok).toBeLessThan(TOAST_DURATION.info);
    expect(TOAST_DURATION.info).toBeLessThan(TOAST_DURATION.warn);
    expect(TOAST_DURATION.warn).toBeLessThan(TOAST_DURATION.bad);
  });

  it("lets a caller choose", () => {
    expect(toastDuration("ok")).toBe(2800);
    expect(toastDuration("ok", 1000)).toBe(1000);
  });
});

describe("nextToast", () => {
  it("replaces what was showing", () => {
    const a: ToastItem = { id: 1, tone: "ok", message: "a", duration: 1 };
    const b: ToastItem = { id: 2, tone: "bad", message: "b", duration: 1 };
    expect(nextToast(a, b)).toBe(b);
    expect(nextToast(null, a)).toBe(a);
  });
});
