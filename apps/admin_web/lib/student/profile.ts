/**
 * What a student may type about themselves, checked the same way as the apps (`profile_validation.dart`). The server is
 * the final judge; these give early, kind messages and are never trusted for access.
 */
export type FieldProblem = "empty" | "tooShort" | "tooLong" | "invalid";

export const NAME_MIN = 2;
export const NAME_MAX = 80;
export const MATRICULE_MIN = 3;
export const MATRICULE_MAX = 32;

export function checkFullName(value: string | null | undefined): FieldProblem | null {
  const v = (value ?? "").trim();
  if (!v) return "empty";
  if (v.length < NAME_MIN) return "tooShort";
  if (v.length > NAME_MAX) return "tooLong";
  return null;
}

/** A student number: letters, digits, dashes, slashes, dots and spaces, starting with a letter or digit. */
export function checkMatricule(value: string | null | undefined): FieldProblem | null {
  const v = (value ?? "").trim();
  if (!v) return "empty";
  if (v.length < MATRICULE_MIN) return "tooShort";
  if (v.length > MATRICULE_MAX) return "tooLong";
  if (!/^[A-Za-z0-9][A-Za-z0-9._/\- ]*$/.test(v)) return "invalid";
  return null;
}

/** 8 to 15 digits, with an optional leading plus; spaces, dots, dashes and brackets are ignored. */
export function checkPhone(value: string | null | undefined): FieldProblem | null {
  const v = (value ?? "").trim();
  if (!v) return "empty";
  if (!/^\+?[0-9 .\-()]+$/.test(v)) return "invalid";
  const digits = v.replace(/[^0-9]/g, "");
  if (digits.length < 8) return "tooShort";
  if (digits.length > 15) return "tooLong";
  return null;
}

/** A phone number as it is stored: the plus and digits only. */
export function normalizePhone(value: string): string {
  const v = value.trim();
  const digits = v.replace(/[^0-9]/g, "");
  return v.startsWith("+") ? `+${digits}` : digits;
}
