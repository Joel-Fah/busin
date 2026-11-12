/** Pure helpers for the semesters pages. Kept separate so they are unit tested. */

export const SEMESTER_NAMES = ["fall", "spring", "summer"] as const;
export type SemesterName = (typeof SEMESTER_NAMES)[number];

export const MIN_YEAR = 2000;
export const MAX_YEAR = 2100;

/** A semester lasts at least a week and at most a year. The database repeats this. */
export const MIN_SEMESTER_DAYS = 7;
export const MAX_SEMESTER_DAYS = 366;

export type SemesterInput = { name: SemesterName; year: number; startDate: string; endDate: string };

export type SemesterFormError = "name" | "year" | "start_date" | "end_date" | "date_order" | "end_past" | "span" | "year_dates";

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

/**
 * Validates the semester form fields. The database repeats these rules; this gives clear messages. With `check`, a
 * semester whose last day is before the school's `today` is refused, unless it is an edit that leaves both dates as
 * they were (`unchanged`), so an old semester can still be renamed. Its length (7 to 366 days) and its year (the year it
 * starts or ends in) are held to the same exception.
 */
export function parseSemesterForm(
  form: { get(name: string): unknown },
  check?: { today: string; unchanged?: { startDate: string; endDate: string; year?: number } },
): { ok: true; value: SemesterInput } | { ok: false; error: SemesterFormError } {
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

  const same = check?.unchanged && check.unchanged.startDate === startDate && check.unchanged.endDate === endDate;
  if (check && !same && endDate < check.today) return { ok: false, error: "end_past" };

  const sameYear = same && check?.unchanged?.year === year;
  if (!same) {
    const days = Math.round((Date.parse(`${endDate}T00:00:00Z`) - Date.parse(`${startDate}T00:00:00Z`)) / 86_400_000);
    if (days < MIN_SEMESTER_DAYS || days > MAX_SEMESTER_DAYS) return { ok: false, error: "span" };
  }
  if (!sameYear && (year < Number(startDate.slice(0, 4)) || year > Number(endDate.slice(0, 4)))) return { ok: false, error: "year_dates" };

  return { ok: true, value: { name, year, startDate, endDate } };
}

export type SemesterSaveErrorKey = "taken" | "end_past" | "span" | "year_dates" | "invalid" | "not_found" | "generic";

/** Maps a database error from saving a semester. 23505 is the unique name and year per school. */
export function semesterSaveErrorKey(code: string | undefined, message?: string): SemesterSaveErrorKey {
  if (code === "22023" && message === "semester_in_past") return "end_past";
  if (code === "22023" && message === "semester_length") return "span";
  if (code === "22023" && message === "semester_year") return "year_dates";
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
  "end_past",
  "span",
  "year_dates",
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

export type SemesterPhase = "current" | "upcoming" | "past";

export function semesterPhase(startDate: string, endDate: string, today: string): SemesterPhase {
  if (today < startDate) return "upcoming";
  if (today > endDate) return "past";
  return "current";
}
