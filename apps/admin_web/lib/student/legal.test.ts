import { describe, expect, it } from "vitest";

import { roundCoordinate } from "./area";
import { legalDocument, readingMinutes, type LegalDoc } from "./legal";

describe("the legal texts", () => {
  it("exist in both languages with the same parts", () => {
    for (const doc of ["terms", "privacy", "acceptable-use"] as LegalDoc[]) {
      const en = legalDocument(doc, "en");
      const fr = legalDocument(doc, "fr");
      expect(en.sections.length).toBeGreaterThan(0);
      expect(fr.sections.length).toBe(en.sections.length);
      expect(fr.highlights.length).toBe(en.highlights.length);
      expect(readingMinutes(en)).toBeGreaterThanOrEqual(1);
    }
  });
});

describe("my area", () => {
  it("rounds a reading to about a kilometre before it is sent", () => {
    expect(roundCoordinate(3.848765)).toBe(3.85);
    expect(roundCoordinate(11.50231)).toBe(11.5);
    expect(roundCoordinate(-0.004)).toBe(-0);
  });
});
