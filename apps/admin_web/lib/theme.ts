/** Theme choice. "system" follows the device; the other two force a theme. Kept in the browser only. */

export const THEMES = ["system", "light", "dark"] as const;
export type Theme = (typeof THEMES)[number];

export const THEME_STORAGE_KEY = "busin-theme";

export function isTheme(value: unknown): value is Theme {
  return typeof value === "string" && (THEMES as readonly string[]).includes(value);
}

/** A stored value that is missing or unknown means "system". */
export function parseTheme(value: unknown): Theme {
  return isTheme(value) ? value : "system";
}

/**
 * Runs before the first paint so a forced theme never flashes the wrong colours.
 * "system" sets nothing, and the stylesheet follows prefers-color-scheme.
 */
export const themeInitScript = `try{var t=localStorage.getItem(${JSON.stringify(THEME_STORAGE_KEY)});if(t==="light"||t==="dark"){document.documentElement.dataset.theme=t}}catch(e){}`;
