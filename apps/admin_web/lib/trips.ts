/** Pure helpers for the trips pages. Kept separate so they are unit tested. */

import { choiceParam, listHref, uuidParam } from "./filters";
import { isUuid } from "./ids";
import { first, parsePageSize, sizeParam } from "./pagination";
import { dayBounds } from "./scans";
import { isIsoDate } from "./semesters";
import { zonedLocalToUtc } from "./zoned";

export const DIRECTIONS = ["inbound", "outbound"] as const;
export type Direction = (typeof DIRECTIONS)[number];

export const TRIP_STATUSES = ["scheduled", "active", "completed", "cancelled"] as const;
export type TripStatus = (typeof TRIP_STATUSES)[number];
/** "archived" is not a status: it is the set of finished or cancelled trips an admin has put away. Every other tab leaves them out. */
export type StatusFilter = TripStatus | "all" | "archived";
export const STATUS_FILTERS: readonly StatusFilter[] = ["all", ...TRIP_STATUSES, "archived"];

export function isDirection(value: unknown): value is Direction {
  return typeof value === "string" && (DIRECTIONS as readonly string[]).includes(value);
}

export function isTripStatus(value: unknown): value is TripStatus {
  return typeof value === "string" && (TRIP_STATUSES as readonly string[]).includes(value);
}

/** The status filter shown in the list. Anything unknown means all trips. */
export function parseStatusFilter(value: string | string[] | undefined): StatusFilter {
  const candidate = first(value);
  return STATUS_FILTERS.find((filter) => filter === candidate) ?? "all";
}

export type TripInput = { busId: string; driverId: string | null; direction: Direction; scheduledStart: string };

export type TripFormError = "bus" | "driver" | "direction" | "start";

/**
 * Validates the trip form fields. `timeZone` is the school's, because the start time is typed as a
 * wall-clock time. Whether the bus is in service and the driver is staff is checked by the action,
 * which has the database at hand.
 */
export function parseTripForm(
  form: { get(name: string): unknown },
  timeZone: string,
): { ok: true; value: TripInput } | { ok: false; error: TripFormError } {
  const busId = form.get("bus_id");
  if (!isUuid(busId)) return { ok: false, error: "bus" };

  // An empty driver means "not assigned yet".
  const rawDriver = form.get("driver_id");
  let driverId: string | null = null;
  if (typeof rawDriver === "string" && rawDriver !== "") {
    if (!isUuid(rawDriver)) return { ok: false, error: "driver" };
    driverId = rawDriver;
  }

  const direction = form.get("direction");
  if (!isDirection(direction)) return { ok: false, error: "direction" };

  const start = zonedLocalToUtc(form.get("scheduled_start"), timeZone);
  if (!start) return { ok: false, error: "start" };

  return { ok: true, value: { busId, driverId, direction, scheduledStart: start.toISOString() } };
}

export type TripSaveErrorKey =
  | "bus_unavailable"
  | "driver_unavailable"
  | "not_editable"
  | "cannot_cancel"
  | "cannot_archive"
  | "invalid"
  | "generic";

/** Maps a database error code from saving a trip. PGRST116 on update means no scheduled trip matched. */
export function tripSaveErrorKey(code: string | undefined): TripSaveErrorKey {
  switch (code) {
    case "23503":
      return "bus_unavailable";
    case "PGRST116":
      return "not_editable";
    case "23514":
    case "22007":
    case "22008":
      return "invalid";
    default:
      return "generic";
  }
}

export type TripFormErrorKey = TripFormError | TripSaveErrorKey;

const FORM_ERRORS: readonly string[] = [
  "bus",
  "driver",
  "direction",
  "start",
  "bus_unavailable",
  "driver_unavailable",
  "not_editable",
  "cannot_cancel",
  "cannot_archive",
  "invalid",
  "generic",
];

export function isTripFormErrorKey(value: string | undefined): value is TripFormErrorKey {
  return value !== undefined && FORM_ERRORS.includes(value);
}

export type TripAction = "cancel" | "archive";

/** Maps a database error code from cancelling or archiving. 55000 means the trip is not in a state that allows it. */
export function tripActionErrorKey(code: string | undefined, action: TripAction): TripSaveErrorKey {
  if (code === "55000") return action === "cancel" ? "cannot_cancel" : "cannot_archive";
  if (code === "22023") return "invalid";
  return "generic";
}

/** The longest reason a cancellation can carry. The database enforces the same limit. */
export const MAX_REASON_LENGTH = 300;

/** The reason typed when cancelling: trimmed, empty means none, and null when it is too long. */
export function parseReason(value: unknown): string | null | undefined {
  if (typeof value !== "string") return undefined;
  const reason = value.trim();
  if (reason === "") return undefined;
  return reason.length > MAX_REASON_LENGTH ? null : reason;
}

export const TRIP_DONE = ["created", "saved", "cancelled", "archived", "restored"] as const;
export type TripDone = (typeof TRIP_DONE)[number];

export function isTripDone(value: string | undefined): value is TripDone {
  return value !== undefined && (TRIP_DONE as readonly string[]).includes(value);
}

/** The tone of a status chip. The label always comes with it, so colour is never the only signal. */
export function tripStatusTone(status: TripStatus): "info" | "ok" | "neutral" | "bad" {
  switch (status) {
    case "active":
      return "ok";
    case "scheduled":
      return "info";
    case "cancelled":
      return "bad";
    default:
      return "neutral";
  }
}

/** Number of trips for each tab. Status counts leave out archived trips; "all" is their sum, and a missing count counts as zero. */
export function tripTabCounts(
  byStatus: Partial<Record<TripStatus, number | null>>,
  archived: number | null = 0,
): Record<StatusFilter, number> {
  const get = (status: TripStatus) => byStatus[status] ?? 0;
  return {
    all: TRIP_STATUSES.reduce((sum, status) => sum + get(status), 0),
    scheduled: get("scheduled"),
    active: get("active"),
    completed: get("completed"),
    cancelled: get("cancelled"),
    archived: archived ?? 0,
  };
}

/** The driver filter value for trips that have no driver yet. */
export const NO_DRIVER = "none";

export type TripFilters = {
  status: StatusFilter;
  /** A calendar day as YYYY-MM-DD in the school timezone. */
  date: string | null;
  bus: string | null;
  direction: Direction | null;
  /** A driver id, NO_DRIVER for trips without one, or null for everyone. */
  driver: string | null;
  /** Rows per page (one of PAGE_SIZES); left out means the default. */
  size?: number;
};

export type TripQuery = {
  status?: string | string[];
  date?: string | string[];
  bus?: string | string[];
  direction?: string | string[];
  driver?: string | string[];
  size?: string | string[];
};

/** Reads the list's filters from its query string. Anything malformed means "no filter". */
export function parseTripFilters(query: TripQuery): TripFilters {
  const date = first(query.date);
  const driver = first(query.driver);
  return {
    status: parseStatusFilter(query.status),
    date: isIsoDate(date) ? date : null,
    bus: uuidParam(query.bus),
    direction: choiceParam(query.direction, DIRECTIONS),
    driver: driver === NO_DRIVER ? NO_DRIVER : uuidParam(query.driver),
    size: parsePageSize(query.size),
  };
}

/** The address of the trips list for these filters, leaving out what is empty and the first page. */
export function tripsHref(filters: TripFilters, page = 1): string {
  return listHref("/trips", {
    status: filters.status === "all" ? null : filters.status,
    date: filters.date,
    bus: filters.bus,
    direction: filters.direction,
    driver: filters.driver,
    size: sizeParam(filters.size),
    page: page > 1 ? page : null,
  });
}

type Chain = {
  eq(column: string, value: string): Chain;
  is(column: string, value: null): Chain;
  gte(column: string, value: string): Chain;
  lt(column: string, value: string): Chain;
};

/**
 * Narrows a trips query by the column filters (not by status, which the page handles with the archive).
 * The same function narrows the list and the counts on the tabs, so the numbers always agree with the rows.
 */
export function applyTripFilters<Q>(query: Q, filters: TripFilters, timeZone: string): Q {
  let q = query as unknown as Chain;
  if (filters.bus) q = q.eq("bus_id", filters.bus);
  if (filters.direction) q = q.eq("direction", filters.direction);
  if (filters.driver === NO_DRIVER) q = q.is("driver_id", null);
  else if (filters.driver) q = q.eq("driver_id", filters.driver);
  if (filters.date) {
    const bounds = dayBounds(filters.date, timeZone);
    q = q.gte("scheduled_start", bounds.from).lt("scheduled_start", bounds.to);
  }
  return q as unknown as Q;
}
