import { readFileSync } from "node:fs";
import path from "node:path";

/** Reads the colour tokens (#rrggbb only) out of app/globals.css, so docs and tests use the real values. */

export type ColourTokens = Record<string, string>;

function parse(body: string): ColourTokens {
  return Object.fromEntries([...body.matchAll(/--([a-z0-9-]+):\s*(#[0-9a-f]{6})/gi)].map((m) => [m[1], m[2]]));
}

export function readColourTokens(cssPath = path.join(process.cwd(), "app/globals.css")): {
  light: ColourTokens;
  dark: ColourTokens;
} {
  const css = readFileSync(cssPath, "utf8");
  const light = parse(css.match(/:root \{([\s\S]*?)\n\}/)?.[1] ?? "");
  const dark = { ...light, ...parse(css.match(/:root\[data-theme='dark'\] \{([\s\S]*?)\n\}/)?.[1] ?? "") };
  return { light, dark };
}

/** Text on background pairs that must stay readable in both themes. */
export const TEXT_PAIRS: [string, string][] = [
  ["fg", "bg"],
  ["fg", "surface"],
  ["muted", "surface"],
  ["muted", "surface-2"],
  ["on-accent", "accent"],
  ["ok", "ok-bg"],
  ["warn", "warn-bg"],
  ["bad", "bad-bg"],
  ["info", "info-bg"],
  ["link", "surface"],
];
