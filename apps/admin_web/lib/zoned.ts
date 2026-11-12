/** Conversion between a wall-clock time in the school's timezone and an instant, for date and time inputs. */

import { zoneOffsetMs } from "./time";

const LOCAL = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/;

/** True for a real date and time written as YYYY-MM-DDTHH:mm, which is what a datetime-local input submits. */
export function isLocalDateTime(value: unknown): value is string {
  if (typeof value !== "string") return false;
  const match = LOCAL.exec(value);
  if (!match) return false;
  const [year, month, day, hour, minute] = match.slice(1).map(Number);
  const date = new Date(Date.UTC(year, month - 1, day, hour, minute));
  return (
    date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day &&
    date.getUTCHours() === hour &&
    date.getUTCMinutes() === minute
  );
}

/** The instant at which the wall clock in `timeZone` shows `local`. Null when the input is not a valid date and time. */
export function zonedLocalToUtc(local: unknown, timeZone: string): Date | null {
  if (!isLocalDateTime(local)) return null;
  const [year, month, day, hour, minute] = (LOCAL.exec(local) as RegExpExecArray).slice(1).map(Number);
  const asUtc = Date.UTC(year, month - 1, day, hour, minute);
  const first = asUtc - zoneOffsetMs(timeZone, new Date(asUtc));
  // The offset can differ at the corrected instant on a daylight saving change day.
  const second = asUtc - zoneOffsetMs(timeZone, new Date(first));
  return new Date(second);
}

/** The wall clock in `timeZone` at `instant`, as YYYY-MM-DDTHH:mm for a datetime-local input. */
export function utcToZonedLocal(instant: string | Date, timeZone: string): string {
  const at = typeof instant === "string" ? new Date(instant) : instant;
  const shifted = new Date(at.getTime() + zoneOffsetMs(timeZone, at));
  return shifted.toISOString().slice(0, 16);
}
