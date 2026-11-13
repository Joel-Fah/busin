import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

import { RADIUS } from "@/lib/ui/radius";
import { DARK, LIGHT } from "@/lib/ui/tokens";

import { COMPONENT_NOTES, MOTION_STEPS, NEVER, RAMPS, SECTIONS, SEED, TOKEN_USE } from "./content";
import { buildMarkdown, tokenData } from "./markdown";
import { buildPdf } from "./pdf";

const theme = readFileSync(fileURLToPath(new URL("../../app/theme.css", import.meta.url)), "utf8");
// Pictographs and the emoji variation selector: the guide forbids emojis, so the exports must not carry any.
const EMOJI = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/u;

describe("the shared content", () => {
  it("keeps the brand ramps, the seed and the motion steps in step with app/theme.css", () => {
    for (const ramp of ["teal", "orange"] as const) {
      for (const [step, hex] of Object.entries(RAMPS[ramp])) expect(theme, `${ramp}-${step}`).toContain(`--color-${ramp}-${step}: ${hex};`);
    }
    expect(theme).toContain(`--color-seed: ${SEED};`);
    for (const m of MOTION_STEPS.filter((m) => m.name !== "Standard")) expect(theme).toContain(`--dur-${m.name.toLowerCase()}: ${m.ms}ms;`);
    for (const [name, px] of Object.entries(RADIUS)) expect(theme).toContain(`--r-${name}: ${px}px;`);
  });

  it("says what every colour token is for", () => {
    for (const name of Object.keys(LIGHT)) expect(TOKEN_USE[name], name).toBeTruthy();
  });
});

describe("the Markdown export for agents", () => {
  const md = buildMarkdown({ generatedOn: "2026-11-13" });

  it("starts with what it is and how to use it, rules before anything else", () => {
    expect(md.startsWith("---\nname: BusIn design system")).toBe(true);
    const how = md.indexOf("## How to use this file");
    const rules = md.indexOf("## Hard rules");
    expect(how).toBeGreaterThan(0);
    expect(rules).toBeGreaterThan(how);
    expect(rules).toBeLessThan(md.indexOf("## Colour"));
  });

  it("carries every section, every rule, every component and every token value in both themes", () => {
    for (const s of SECTIONS.filter((s) => s.id !== "rules")) expect(md, s.title).toContain(s.intro);
    for (const rule of NEVER) expect(md).toContain(`- ${rule}`);
    for (const c of COMPONENT_NOTES) expect(md).toContain(`### ${c.name}`);
    for (const name of Object.keys(LIGHT)) expect(md).toContain(`| \`${name}\` | ${LIGHT[name]} | ${DARK[name]} |`);
  });

  it("ends with a token block a program can read", () => {
    const json = md.match(/```json\n([\s\S]*?)\n```/)?.[1];
    expect(JSON.parse(json ?? "")).toEqual(tokenData());
  });

  it("has recipes for the common goals and no emojis", () => {
    for (const goal of ["A project illustration", "A new portal screen", "Interface copy", "A design review"]) expect(md).toContain(`### ${goal}`);
    expect(EMOJI.test(md)).toBe(false);
  });
});

describe("the PDF export", () => {
  it("is a real PDF with the cover, the contents and one part per section", async () => {
    const pdf = await buildPdf({ generatedOn: "2026-11-13" });
    expect(pdf.subarray(0, 5).toString()).toBe("%PDF-");
    const pages = (pdf.toString("latin1").match(/\/Type\s*\/Page[^s]/g) ?? []).length;
    expect(pages).toBeGreaterThanOrEqual(SECTIONS.length);
  }, 30_000);
});
