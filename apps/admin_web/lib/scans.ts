/** Pure helpers for the scans (boardings) page. Kept separate so they are unit tested. */

import { isUuid } from "./ids";
import { first } from "./pagination";
import { isIsoDate } from "./semesters";
import { startOfDayInTimeZone } from "./time";

export type ScanFilters = {
  /** A trip id, or null for all trips. */
  trip: string | null;
  /** A stop id, or null for all stops. */
  stop: string | null;
  /** A calendar day as YYYY-MM-DD in the school timezone, or null for all days. */
  date: string | null;
};

function uuidOrNull(value: string | string[] | undefined): string | null {
  const candidate = first(value);
  return isUuid(candidate) ? candidate : null;
}

/** Reads the filters from the query string. Anything malformed means "no filter". */
export function parseScanFilters(query: {
  trip?: string | string[];
  stop?: string | string[];
  date?: string | string[];
}): ScanFilters {
  const date = first(query.date);
  return { trip: uuidOrNull(query.trip), stop: uuidOrNull(query.stop), date: isIsoDate(date) ? date : null };
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
  const params = new URLSearchParams();
  if (filters.trip) params.set("trip", filters.trip);
  if (filters.stop) params.set("stop", filters.stop);
  if (filters.date) params.set("date", filters.date);
  if (page > 1) params.set("page", String(page));
  const query = params.toString();
  return query ? `/scans?${query}` : "/scans";
}
