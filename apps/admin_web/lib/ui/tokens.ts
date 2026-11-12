/**
 * Colour tokens as data, for the styleguide and the contrast test. The source of truth is
 * app/globals.css; a unit test (tokens.test.ts) fails if the two ever disagree, so this file
 * cannot drift. Dark lists only the values that differ from light.
 */

export type ColourTokens = Record<string, string>;

export const LIGHT: ColourTokens = {
  "bg": "#f4f8f8",
  "surface": "#ffffff",
  "surface-2": "#e8f1f2",
  "fg": "#002a33",
  "muted": "#4d6a70",
  "line": "#d2e1e3",
  "brand": "#002a33",
  "on-brand": "#ffffff",
  "accent": "#f5951f",
  "on-accent": "#002a33",
  "link": "#087282",
  "focus": "#087282",
  "ok": "#0b7a43",
  "ok-bg": "#e2f4ea",
  "warn": "#8a6100",
  "warn-bg": "#fbf0cf",
  "bad": "#b3261e",
  "bad-bg": "#fbe5e3",
  "info": "#1a56c4",
  "info-bg": "#e3ecfb",
};

export const DARK_OVERRIDES: ColourTokens = {
  "bg": "#00181d",
  "surface": "#002a33",
  "surface-2": "#06404b",
  "fg": "#e6f4f4",
  "muted": "#9dbdc1",
  "line": "#14505c",
  "brand": "#e6f4f4",
  "on-brand": "#00181d",
  "link": "#54d8e8",
  "focus": "#54d8e8",
  "ok": "#4cd08a",
  "ok-bg": "#0c3a28",
  "warn": "#ffd24d",
  "warn-bg": "#3d3208",
  "bad": "#ff8a80",
  "bad-bg": "#4a1714",
  "info": "#8ab4ff",
  "info-bg": "#14305e",
};

export const DARK: ColourTokens = { ...LIGHT, ...DARK_OVERRIDES };

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
