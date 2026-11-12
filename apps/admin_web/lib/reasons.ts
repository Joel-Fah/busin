/**
 * Reasons an administrator gives (rejecting or revoking a subscription, giving it back, cancelling a trip, declining a
 * request to join). The student or the school's staff read them, so they must say something: trimmed, runs of spaces
 * collapsed, at least REASON_MIN characters, at most the limit of the place they are used. The database repeats these
 * rules (`private.clean_reason`); this gives the message before the trip to the server.
 */
export const REASON_MIN = 10;

export type ReasonProblem = "reason_required" | "reason_too_short" | "reason_too_long";

export const REASON_PROBLEMS: readonly ReasonProblem[] = ["reason_required", "reason_too_short", "reason_too_long"];

export function isReasonProblem(value: unknown): value is ReasonProblem {
  return typeof value === "string" && (REASON_PROBLEMS as readonly string[]).includes(value);
}

/** The text as it will be stored: spaces and line breaks collapsed to single spaces, then trimmed. */
export function tidyReason(raw: unknown): string {
  return typeof raw === "string" ? raw.replace(/\s+/g, " ").trim() : "";
}

export type ReasonCheck = { ok: true; value: string | null } | { ok: false; problem: ReasonProblem };

/** Checks a typed reason. `required: false` accepts nothing at all (value null), but not a few words. */
export function checkReason(raw: unknown, { required, max }: { required: boolean; max: number }): ReasonCheck {
  const value = tidyReason(raw);
  if (value === "") return required ? { ok: false, problem: "reason_required" } : { ok: true, value: null };
  if (value.length < REASON_MIN) return { ok: false, problem: "reason_too_short" };
  if (value.length > max) return { ok: false, problem: "reason_too_long" };
  return { ok: true, value };
}

/** The problem the database reported (22023 with a short code as its message), or null for any other error. */
export function reasonProblemFromDb(code: string | undefined, message: string | undefined): ReasonProblem | null {
  return code === "22023" && isReasonProblem(message) ? message : null;
}

/**
 * What a clicked preset does to the field: it fills an empty field, adds itself after what is there, and does nothing
 * when it is already in the text or would not fit.
 */
export function withPreset(current: string, preset: string, max: number): string {
  const text = current.trim();
  if (text === "") return preset;
  if (text.includes(preset)) return current;
  const next = `${text} ${preset}`;
  return next.length > max ? current : next;
}
