/** Pure helpers for the scans (boardings) page. Kept separate so they are unit tested. */

import { choiceParam, listHref, uuidParam } from "./filters";
import { first, parsePageSize, sizeParam } from "./pagination";
import { isIsoDate } from "./semesters";
import { startOfDayInTimeZone } from "./time";

export type ScanFilters = {
  /** A trip id, or null for all trips. */
  trip: string | null;
  /** A stop id, or null for all stops. */
  stop: string | null;
  /** A calendar day as YYYY-MM-DD in the school timezone, or null for all days. */
  date: string | null;
  /** A bus id (the bus of the trip the student boarded), or null for all buses. */
  bus: string | null;
  /** Going to school or going home, or null for both. */
  direction: "inbound" | "outbound" | null;
  /** Rows per page (one of PAGE_SIZES); left out means the default. */
  size?: number;
};

/** Reads the filters from the query string. Anything malformed means "no filter". */
export function parseScanFilters(query: {
  trip?: string | string[];
  stop?: string | string[];
  date?: string | string[];
  bus?: string | string[];
  direction?: string | string[];
  size?: string | string[];
}): ScanFilters {
  const date = first(query.date);
  return {
    trip: uuidParam(query.trip),
    stop: uuidParam(query.stop),
    date: isIsoDate(date) ? date : null,
    bus: uuidParam(query.bus),
    direction: choiceParam(query.direction, ["inbound", "outbound"] as const),
    size: parsePageSize(query.size),
  };
}

/** The instants at which a calendar day starts and ends in `timeZone`, for a half-open range filter. */
export function dayBounds(date: string, timeZone: string): { from: string; to: string } {
  const [year, month, day] = date.split("-").map(Number);
  // Noon avoids landing on a skipped or repeated hour on a daylight saving change day.
  const from = startOfDayInTimeZone(timeZone, new Date(Date.UTC(year, month - 1, day, 12)));
  const to = startOfDayInTimeZone(timeZone, new Date(Date.UTC(year, month - 1, day + 1, 12)));
  return { from: from.toISOString(), to: to.toISOString() };
}

/** The query string for the list, leaving out empty filters and the first page. */
export function scansHref(filters: ScanFilters, page = 1): string {
  return listHref("/scans", {
    trip: filters.trip,
    stop: filters.stop,
    date: filters.date,
    bus: filters.bus,
    direction: filters.direction,
    size: sizeParam(filters.size),
    page: page > 1 ? page : null,
  });
}
