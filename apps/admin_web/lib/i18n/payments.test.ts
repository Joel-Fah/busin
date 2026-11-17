import { describe, expect, it } from "vitest";

import { paymentsCatalogues } from "./payments";

function flatten(value: unknown, prefix = ""): Record<string, string> {
  if (typeof value === "string") return { [prefix]: value };
  const out: Record<string, string> = {};
  for (const [key, child] of Object.entries(value as Record<string, unknown>)) Object.assign(out, flatten(child, prefix ? `${prefix}.${key}` : key));
  return out;
}

describe("payment words", () => {
  const english = flatten(paymentsCatalogues.en);
  const french = flatten(paymentsCatalogues.fr);

  it("French has exactly the same keys as English, none empty", () => {
    expect(Object.keys(french).sort()).toEqual(Object.keys(english).sort());
    for (const [key, text] of [...Object.entries(english), ...Object.entries(french)]) expect(text.trim(), key).not.toBe("");
  });

  it("uses the same placeholders in both languages", () => {
    const placeholders = (text: string) => (text.match(/\{\w+\}/g) ?? []).sort();
    for (const key of Object.keys(english)) expect(placeholders(french[key]), key).toEqual(placeholders(english[key]));
  });

  it("contains no emoji", () => {
    const emoji = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/u;
    for (const [key, text] of [...Object.entries(english), ...Object.entries(french)]) expect(emoji.test(text), key).toBe(false);
  });
});
