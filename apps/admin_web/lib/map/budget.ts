/**
 * A per-browser cap on how many paid maps may be started. Mapbox bills each time a map is created, so
 * a bug (a remount loop, a page that creates a map on every render) could otherwise cost real money.
 * Past the cap the portal draws the free map instead. It is a safety net against our own mistakes in
 * one browser, not protection against abuse: that is what the token's URL restriction is for.
 */

/** Map loads allowed per browser per window. An administrator visiting the map pages a few times a day stays far below it. */
export const MAP_LOAD_LIMIT = 30;
export const MAP_LOAD_WINDOW_MS = 24 * 60 * 60 * 1000;

/** Where the history is kept in the browser. */
export const MAP_BUDGET_KEY = "busin-map-loads";

/** The stored list of load times, or an empty list if it is missing or damaged. */
export function parseHistory(raw: string | null): number[] {
  if (!raw) return [];
  try {
    const value: unknown = JSON.parse(raw);
    return Array.isArray(value) ? value.filter((item): item is number => typeof item === "number" && Number.isFinite(item)) : [];
  } catch {
    return [];
  }
}

/** Only the loads inside the window still count. */
export function recent(history: number[], now: number, windowMs = MAP_LOAD_WINDOW_MS): number[] {
  return history.filter((time) => time > now - windowMs && time <= now);
}

export function canLoadMap(history: number[], now: number, limit = MAP_LOAD_LIMIT, windowMs = MAP_LOAD_WINDOW_MS): boolean {
  return recent(history, now, windowMs).length < limit;
}

/** The history with one more load at `now`, pruned to the window. */
export function withLoad(history: number[], now: number, windowMs = MAP_LOAD_WINDOW_MS): number[] {
  return [...recent(history, now, windowMs), now];
}

/** A read-only look: is there budget left? Nothing is recorded. Storage that is missing or blocked counts as available. */
export function mapBudgetAvailable(storage: Pick<Storage, "getItem"> | null, now = Date.now()): boolean {
  if (!storage) return true;
  try {
    return canLoadMap(parseHistory(storage.getItem(MAP_BUDGET_KEY)), now);
  } catch {
    return true;
  }
}

/**
 * Asks to start a paid map. Returns true and records the load, or false when the budget is spent.
 * If storage is blocked it allows the load, because failing closed would hide the map from everyone
 * whose browser blocks storage; the session reuse in the provider still keeps that to one load per tab.
 */
export function takeMapLoad(storage: Pick<Storage, "getItem" | "setItem"> | null, now = Date.now()): boolean {
  if (!storage) return true;
  try {
    const history = parseHistory(storage.getItem(MAP_BUDGET_KEY));
    if (!canLoadMap(history, now)) return false;
    storage.setItem(MAP_BUDGET_KEY, JSON.stringify(withLoad(history, now)));
    return true;
  } catch {
    return true;
  }
}
