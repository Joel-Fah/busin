/**
 * The dot on My bus, as in the app (bus_news.dart): shown while a trip runs that the student has not looked at yet.
 * The trips seen are kept for this browser tab's session only, so a new session shows the dot again for a trip still
 * running. Nothing leaves the browser.
 */

const KEY = "busin.bus.seen";
const KEPT = 50;

/** Said when the trips seen change (My bus shows them), so the tab bar looks again without reading anything. */
export const BUS_SEEN_EVENT = "busin:bus-seen";
/** Said when a "trip started" notification arrives while a page is open, so the tab bar reads the running trips. */
export const TRIP_STARTED_EVENT = "busin:trip-started";

export function seenTrips(): Set<string> {
  try {
    const stored = JSON.parse(sessionStorage.getItem(KEY) ?? "[]");
    return new Set(Array.isArray(stored) ? stored.filter((id): id is string => typeof id === "string") : []);
  } catch {
    return new Set();
  }
}

/** The student is looking at these trips on My bus. */
export function markTripsSeen(tripIds: string[]): void {
  const seen = seenTrips();
  const before = seen.size;
  for (const id of tripIds) seen.add(id);
  if (seen.size === before) return;
  try {
    sessionStorage.setItem(KEY, JSON.stringify([...seen].slice(-KEPT)));
  } catch {
    // Storage refused (a private window): the dot then shows until the trip ends, which is harmless.
  }
  window.dispatchEvent(new Event(BUS_SEEN_EVENT));
}

/** Whether a running trip has not been looked at. */
export function hasNews(running: string[], seen: Set<string>): boolean {
  return running.some((id) => !seen.has(id));
}
