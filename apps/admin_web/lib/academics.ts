/** Pure helpers for the faculties, departments and degree levels page. Kept separate so they are unit tested. */

export const NAME_MIN = 2;
export const NAME_MAX = 120;
export const CODE_MAX = 12;

export type UnitInput = { name: string; code: string | null };
export type UnitFormError = "name" | "code";

/** Validates a faculty, department or degree level form. The database repeats these rules. */
export function parseUnitForm(form: { get(name: string): unknown }): { ok: true; value: UnitInput } | { ok: false; error: UnitFormError } {
  const rawName = form.get("name");
  const name = typeof rawName === "string" ? rawName.trim().replace(/\s+/g, " ") : "";
  if (name.length < NAME_MIN || name.length > NAME_MAX) return { ok: false, error: "name" };

  const rawCode = form.get("code");
  const code = typeof rawCode === "string" ? rawCode.trim() : "";
  if (code.length > CODE_MAX) return { ok: false, error: "code" };

  return { ok: true, value: { name, code: code === "" ? null : code } };
}

export type UnitErrorKey = UnitFormError | "taken" | "in_use" | "not_found" | "generic";

/** Maps a database error code. 23505 is a repeated name; 23503 means other rows still point at it. */
export function unitSaveErrorKey(code: string | undefined): UnitErrorKey {
  switch (code) {
    case "23505":
      return "taken";
    case "23503":
      return "in_use";
    case "23514":
      return "name";
    case "PGRST116":
      return "not_found";
    default:
      return "generic";
  }
}

const ERRORS: readonly string[] = ["name", "code", "taken", "in_use", "not_found", "generic"];

export function isUnitErrorKey(value: string | undefined): value is UnitErrorKey {
  return typeof value === "string" && ERRORS.includes(value);
}

export type UnitDoneKey = "faculty_saved" | "faculty_added" | "faculty_removed" | "department_saved" | "department_added" | "department_removed" | "program_saved" | "program_added" | "program_removed";

const DONE: readonly string[] = [
  "faculty_saved", "faculty_added", "faculty_removed",
  "department_saved", "department_added", "department_removed",
  "program_saved", "program_added", "program_removed",
];

export function isUnitDoneKey(value: string | undefined): value is UnitDoneKey {
  return typeof value === "string" && DONE.includes(value);
}
