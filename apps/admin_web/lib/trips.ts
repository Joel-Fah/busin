/** Pure helpers for the trips pages. Kept separate so they are unit tested. */

import { isUuid } from "./ids";
import { first } from "./pagination";
import { zonedLocalToUtc } from "./zoned";

export const DIRECTIONS = ["inbound", "outbound"] as const;
export type Direction = (typeof DIRECTIONS)[number];

export const TRIP_STATUSES = ["scheduled", "active", "completed", "cancelled"] as const;
export type TripStatus = (typeof TRIP_STATUSES)[number];
export type StatusFilter = TripStatus | "all";
export const STATUS_FILTERS: readonly StatusFilter[] = ["all", ...TRIP_STATUSES];

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

export type TripSaveErrorKey = "bus_unavailable" | "driver_unavailable" | "not_editable" | "invalid" | "generic";

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
  "invalid",
  "generic",
];

export function isTripFormErrorKey(value: string | undefined): value is TripFormErrorKey {
  return value !== undefined && FORM_ERRORS.includes(value);
}

export type TripDone = "created" | "saved";

export function isTripDone(value: string | undefined): value is TripDone {
  return value === "created" || value === "saved";
}

export function statusPill(status: TripStatus): string {
  switch (status) {
    case "active":
      return "pill pill-ok";
    case "scheduled":
      return "pill pill-info";
    case "cancelled":
      return "pill pill-warn";
    default:
      return "pill";
  }
}
