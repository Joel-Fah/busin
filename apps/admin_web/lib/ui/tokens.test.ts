import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

import { DARK, LIGHT } from "./tokens";

const css = readFileSync(fileURLToPath(new URL("../../app/globals.css", import.meta.url)), "utf8");

function parse(body: string): Record<string, string> {
  return Object.fromEntries([...body.matchAll(/--([a-z0-9-]+):\s*(#[0-9a-f]{6})/gi)].map((m) => [m[1], m[2]]));
}

const cssLight = parse(css.match(/:root \{([\s\S]*?)\n\}/)?.[1] ?? "");
const cssDark = { ...cssLight, ...parse(css.match(/:root\[data-theme='dark'\] \{([\s\S]*?)\n\}/)?.[1] ?? "") };

describe("colour tokens in tokens.ts match app/globals.css", () => {
  it("light theme", () => {
    for (const [name, value] of Object.entries(LIGHT)) expect(cssLight[name], name).toBe(value);
  });

  it("dark theme", () => {
    for (const [name, value] of Object.entries(DARK)) expect(cssDark[name], name).toBe(value);
  });

  it("covers every colour the stylesheet defines", () => {
    for (const name of Object.keys(cssLight)) expect(LIGHT[name], name).toBeDefined();
  });
});
