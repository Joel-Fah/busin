/**
 * Calendar maths for the date picker. Dates are plain YYYY-MM-DD strings and all arithmetic is done
 * in UTC, so the result never depends on the visitor's timezone or daylight saving.
 */

export type Iso = string;

const ISO = /^(\d{4})-(\d{2})-(\d{2})$/;
const DAY_MS = 86_400_000;

export function parseIso(value: unknown): { year: number; month: number; day: number } | null {
  if (typeof value !== "string") return null;
  const match = ISO.exec(value);
  if (!match) return null;
  const [year, month, day] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const date = new Date(Date.UTC(year, month - 1, day));
  if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) return null;
  return { year, month, day };
}

export function toIso(year: number, month: number, day: number): Iso {
  return new Date(Date.UTC(year, month - 1, day)).toISOString().slice(0, 10);
}

const fromMs = (ms: number): Iso => new Date(ms).toISOString().slice(0, 10);

export function addDays(iso: Iso, days: number): Iso {
  const parts = parseIso(iso);
  if (!parts) throw new Error(`Not a date: ${iso}`);
  return fromMs(Date.UTC(parts.year, parts.month - 1, parts.day) + days * DAY_MS);
}

/** Adds months and keeps the day when it exists (31 January plus one month is 28 or 29 February). */
export function addMonths(iso: Iso, months: number): Iso {
  const parts = parseIso(iso);
  if (!parts) throw new Error(`Not a date: ${iso}`);
  const index = parts.year * 12 + (parts.month - 1) + months;
  const year = Math.floor(index / 12);
  const month = (index % 12) + 1;
  const last = new Date(Date.UTC(year, month, 0)).getUTCDate();
  return toIso(year, month, Math.min(parts.day, last));
}

/** 0 for Sunday to 6 for Saturday. */
export function weekday(iso: Iso): number {
  const parts = parseIso(iso);
  if (!parts) throw new Error(`Not a date: ${iso}`);
  return new Date(Date.UTC(parts.year, parts.month - 1, parts.day)).getUTCDay();
}

/** Six weeks of days that cover the month, starting on the chosen weekday. Always 42 days, so the grid keeps its height. */
export function monthGrid(year: number, month: number, weekStartsOn: 0 | 1 = 1): Iso[] {
  const first = toIso(year, month, 1);
  const offset = (weekday(first) - weekStartsOn + 7) % 7;
  const start = addDays(first, -offset);
  return Array.from({ length: 42 }, (_, index) => addDays(start, index));
}

export function inRange(iso: Iso, min?: Iso, max?: Iso): boolean {
  return (!min || iso >= min) && (!max || iso <= max);
}

/** "HH:mm" into hour and minute, or null. */
export function parseTime(value: unknown): { hour: number; minute: number } | null {
  if (typeof value !== "string") return null;
  const match = /^(\d{2}):(\d{2})$/.exec(value);
  if (!match) return null;
  const [hour, minute] = [Number(match[1]), Number(match[2])];
  return hour < 24 && minute < 60 ? { hour, minute } : null;
}

export function formatTime(hour: number, minute: number): string {
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

/** The minutes offered in the time picker: every `step` minutes. */
export function minuteOptions(step: number): number[] {
  const safe = Number.isInteger(step) && step >= 1 && step <= 30 && 60 % step === 0 ? step : 5;
  return Array.from({ length: 60 / safe }, (_, index) => index * safe);
}

/** Combines a date and a time into the value a datetime-local field uses, or "" when either is missing. */
export function joinDateTime(date: Iso, time: string): string {
  return parseIso(date) && parseTime(time) ? `${date}T${time}` : "";
}

export function splitDateTime(value: string): { date: Iso; time: string } {
  const [date = "", time = ""] = value.split("T");
  return { date: parseIso(date) ? date : "", time: parseTime(time.slice(0, 5)) ? time.slice(0, 5) : "" };
}
