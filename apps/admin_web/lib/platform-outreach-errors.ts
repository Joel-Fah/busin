/** The refusals of the outreach functions the console explains; anything else is "generic". */
export const OUTREACH_ERRORS = ["bad_body", "bad_text_link", "bad_link", "bad_channel", "bad_follow_up", "no_school", "generic"] as const;
export type OutreachError = (typeof OUTREACH_ERRORS)[number];

export function outreachErrorKey(message: string | null | undefined): OutreachError {
  const key = (message ?? "").trim();
  return (OUTREACH_ERRORS as readonly string[]).includes(key) ? (key as OutreachError) : "generic";
}

export function isOutreachError(value: unknown): value is OutreachError {
  return typeof value === "string" && (OUTREACH_ERRORS as readonly string[]).includes(value);
}

export const OUTREACH_DONE = ["notice", "logged", "followUp"] as const;
export type OutreachDone = (typeof OUTREACH_DONE)[number];

export function isOutreachDone(value: unknown): value is OutreachDone {
  return typeof value === "string" && (OUTREACH_DONE as readonly string[]).includes(value);
}
