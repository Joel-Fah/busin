import { describe, expect, it } from "vitest";

import { en, fr, format, isLocale } from "./messages";

function flatten(value: unknown, prefix = ""): Record<string, string> {
  if (typeof value === "string") return { [prefix]: value };
  const out: Record<string, string> = {};
  for (const [key, child] of Object.entries(value as Record<string, unknown>)) {
    Object.assign(out, flatten(child, prefix ? `${prefix}.${key}` : key));
  }
  return out;
}

describe("message catalogues", () => {
  const english = flatten(en);
  const french = flatten(fr);

  it("French has exactly the same keys as English", () => {
    expect(Object.keys(french).sort()).toEqual(Object.keys(english).sort());
  });

  it("has no empty strings", () => {
    for (const [key, text] of [...Object.entries(english), ...Object.entries(french)]) {
      expect(text.trim(), key).not.toBe("");
    }
  });

  it("uses the same placeholders in both languages", () => {
    const placeholders = (text: string) => (text.match(/\{\w+\}/g) ?? []).sort();
    for (const key of Object.keys(english)) {
      expect(placeholders(french[key]), key).toEqual(placeholders(english[key]));
    }
  });

  it("contains no emoji", () => {
    const emoji = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/u;
    for (const [key, text] of [...Object.entries(english), ...Object.entries(french)]) {
      expect(emoji.test(text), key).toBe(false);
    }
  });
});

describe("format", () => {
  it("replaces known placeholders and keeps unknown ones", () => {
    expect(format("Hello {name}, {other}", { name: "Ada" })).toBe("Hello Ada, {other}");
  });

  it("replaces repeated placeholders", () => {
    expect(format("{n} of {n}", { n: 3 })).toBe("3 of 3");
  });
});

describe("isLocale", () => {
  it("accepts only supported languages", () => {
    expect(isLocale("en")).toBe(true);
    expect(isLocale("fr")).toBe(true);
    expect(isLocale("de")).toBe(false);
    expect(isLocale(undefined)).toBe(false);
    expect(isLocale("")).toBe(false);
  });
});
