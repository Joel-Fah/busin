import { describe, expect, it } from "vitest";

import { studentCatalogues } from "./student";

function keyPaths(value: unknown, prefix = ""): string[] {
  if (value && typeof value === "object") {
    return Object.entries(value).flatMap(([key, child]) => keyPaths(child, prefix ? `${prefix}.${key}` : key));
  }
  return [prefix];
}

function strings(value: unknown): string[] {
  if (typeof value === "string") return [value];
  if (value && typeof value === "object") return Object.values(value).flatMap(strings);
  return [];
}

describe("student web copy", () => {
  it("has the same keys in English and French", () => {
    expect(keyPaths(studentCatalogues.fr).sort()).toEqual(keyPaths(studentCatalogues.en).sort());
  });

  it("has no empty text and no emoji", () => {
    const emoji = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]/u;
    for (const locale of ["en", "fr"] as const) {
      for (const text of strings(studentCatalogues[locale])) {
        expect(text.trim().length, `${locale}: empty text`).toBeGreaterThan(0);
        expect(emoji.test(text), `${locale}: ${text}`).toBe(false);
      }
    }
  });
});
