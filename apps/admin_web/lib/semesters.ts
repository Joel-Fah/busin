/** Pure helpers for the semesters pages. Kept separate so they are unit tested. */

export const SEMESTER_NAMES = ["fall", "spring", "summer"] as const;
export type SemesterName = (typeof SEMESTER_NAMES)[number];

export const MIN_YEAR = 2000;
export const MAX_YEAR = 2100;

export type SemesterInput = { name: SemesterName; year: number; startDate: string; endDate: string };

export type SemesterFormError = "name" | "year" | "start_date" | "end_date" | "date_order";

export function isSemesterName(value: unknown): value is SemesterName {
  return typeof value === "string" && (SEMESTER_NAMES as readonly string[]).includes(value);
}

/** True for a real calendar date written as YYYY-MM-DD, which is what a date input submits. */
export function isIsoDate(value: unknown): value is string {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const [year, month, day] = value.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
}

/** Validates the semester form fields. The database repeats these rules; this gives clear messages. */
export function parseSemesterForm(form: {
  get(name: string): unknown;
}): { ok: true; value: SemesterInput } | { ok: false; error: SemesterFormError } {
  const name = form.get("name");
  if (!isSemesterName(name)) return { ok: false, error: "name" };

  const rawYear = form.get("year");
  const year = typeof rawYear === "string" && /^\d{4}$/.test(rawYear.trim()) ? Number(rawYear.trim()) : NaN;
  if (!Number.isInteger(year) || year < MIN_YEAR || year > MAX_YEAR) return { ok: false, error: "year" };

  const startDate = form.get("start_date");
  if (!isIsoDate(startDate)) return { ok: false, error: "start_date" };
  const endDate = form.get("end_date");
  if (!isIsoDate(endDate)) return { ok: false, error: "end_date" };

  // ISO dates sort the same as calendar dates, so a string comparison is enough.
  if (endDate <= startDate) return { ok: false, error: "date_order" };

  return { ok: true, value: { name, year, startDate, endDate } };
}

export type SemesterSaveErrorKey = "taken" | "invalid" | "not_found" | "generic";

/** Maps a database error code from saving a semester. 23505 is the unique name and year per school. */
export function semesterSaveErrorKey(code: string | undefined): SemesterSaveErrorKey {
  switch (code) {
    case "23505":
      return "taken";
    case "23514":
    case "22007":
    case "22008":
    case "22P02":
      return "invalid";
    case "PGRST116":
      return "not_found";
    default:
      return "generic";
  }
}

export type SemesterFormErrorKey = SemesterFormError | SemesterSaveErrorKey;

const FORM_ERRORS: readonly string[] = [
  "name",
  "year",
  "start_date",
  "end_date",
  "date_order",
  "taken",
  "invalid",
  "not_found",
  "generic",
];

export function isSemesterFormErrorKey(value: string | undefined): value is SemesterFormErrorKey {
  return value !== undefined && FORM_ERRORS.includes(value);
}

export type SemesterDone = "created" | "saved";

export function isSemesterDone(value: string | undefined): value is SemesterDone {
  return value === "created" || value === "saved";
}

/** Today in UTC as YYYY-MM-DD, used to mark the semester that is running. */
export function todayIso(now: Date = new Date()): string {
  return now.toISOString().slice(0, 10);
}

export type SemesterPhase = "current" | "upcoming" | "past";

export function semesterPhase(startDate: string, endDate: string, today: string): SemesterPhase {
  if (today < startDate) return "upcoming";
  if (today > endDate) return "past";
  return "current";
}
