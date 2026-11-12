import { describe, expect, it } from "vitest";

import { buildLlmsTxt } from "./llms";

describe("llms.txt", () => {
  const text = buildLlmsTxt("https://busin.example");

  it("follows the format: a title, a summary line, then sections of links", () => {
    const lines = text.split("\n");
    expect(lines[0]).toBe("# BusIn");
    expect(lines[2].startsWith("> ")).toBe(true);
    expect(text).toContain("## Public pages");
  });

  it("links only the public pages, with absolute addresses", () => {
    const links = [...text.matchAll(/\]\((https?:[^)]+)\)/g)].map((m) => m[1]);
    expect(links).toEqual(["https://busin.example/", "https://busin.example/credits"]);
  });

  it("says the portal is private and holds no emoji", () => {
    expect(text).toContain("private and not meant for indexing");
    expect(/\p{Extended_Pictographic}/u.test(text)).toBe(false);
  });
});
