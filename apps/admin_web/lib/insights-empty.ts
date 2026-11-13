import type { StopLoads } from "@/lib/insights";
import type { Proximity } from "@/lib/proximity";
import type { Suggestion } from "@/lib/suggestions";

/**
 * Whether an Insights view has nothing to show yet, so the page says what it needs instead of a map and cards full of
 * zeros. A school just starting has stops but no rides and no shared home areas.
 */
export const loadIsEmpty = (loads: StopLoads) => loads.stops.every((stop) => stop.boardings === 0 && stop.students === 0);

/** Proximity says something only for a stop with at least 5 students who shared their area. */
export const proximityIsEmpty = (proximity: Proximity) => proximity.stops.every((stop) => stop.median === null);

export const suggestionsAreEmpty = (suggestions: readonly Suggestion[]) => suggestions.length === 0;

/** The graph joins the two: it is empty while both are. */
export const graphIsEmpty = (loads: StopLoads, proximity: Proximity) => loadIsEmpty(loads) && proximityIsEmpty(proximity);
