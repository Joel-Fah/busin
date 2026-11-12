import { describe, expect, it } from "vitest";

import { THEME_STORAGE_KEY, isTheme, parseTheme, themeInitScript } from "./theme";

describe("parseTheme", () => {
  it("keeps the three known themes", () => {
    expect(parseTheme("light")).toBe("light");
    expect(parseTheme("dark")).toBe("dark");
    expect(parseTheme("system")).toBe("system");
  });

  it("falls back to system for anything else", () => {
    expect(parseTheme(null)).toBe("system");
    expect(parseTheme("blue")).toBe("system");
    expect(parseTheme(3)).toBe("system");
  });
});

describe("isTheme", () => {
  it("rejects look-alikes", () => {
    expect(isTheme("Dark")).toBe(false);
    expect(isTheme(undefined)).toBe(false);
  });
});

describe("themeInitScript", () => {
  it("reads the storage key and only applies forced themes", () => {
    expect(themeInitScript).toContain(THEME_STORAGE_KEY);
    expect(themeInitScript).toContain('"light"');
    expect(themeInitScript).toContain('"dark"');
    expect(themeInitScript).not.toContain('"system"');
  });
});
