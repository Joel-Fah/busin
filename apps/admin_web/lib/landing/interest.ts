/**
 * The landing page's interest form: what each kind of request needs, checked in the browser for quick feedback and again
 * in the server action. The database function checks it a third time and is the one that counts.
 */
export const INTEREST_KINDS = ["school", "notify_android", "notify_ios"] as const;
export type InterestKind = (typeof INTEREST_KINDS)[number];

export type InterestInput = { kind: string; email: string; name?: string; organisation?: string; message?: string };
export type InterestField = "email" | "name" | "organisation" | "message";
export type InterestProblem = "required" | "email" | "long";

export const LIMITS = { name: 80, organisation: 120, message: 1000, email: 254 } as const;

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/;

export function isInterestKind(value: string): value is InterestKind {
  return (INTEREST_KINDS as readonly string[]).includes(value);
}

/** The problems with a request, by field. Empty when it can be sent. */
export function checkInterest(input: InterestInput): Partial<Record<InterestField, InterestProblem>> {
  const problems: Partial<Record<InterestField, InterestProblem>> = {};
  const email = input.email.trim();
  if (!email) problems.email = "required";
  else if (email.length > LIMITS.email || !EMAIL.test(email)) problems.email = "email";
  const name = input.name?.trim() ?? "";
  const organisation = input.organisation?.trim() ?? "";
  if (input.kind === "school") {
    if (!name) problems.name = "required";
    if (!organisation) problems.organisation = "required";
  }
  if (name.length > LIMITS.name) problems.name = "long";
  if (organisation.length > LIMITS.organisation) problems.organisation = "long";
  if ((input.message?.trim().length ?? 0) > LIMITS.message) problems.message = "long";
  return problems;
}

/** What the database said, as one of the outcomes the form knows how to show. */
export type InterestOutcome = "stored" | "already" | "invalid" | "busy" | "failed";

export function outcomeOf(result: { data: string | null; error: { code?: string } | null }): InterestOutcome {
  if (result.error) {
    if (result.error.code === "22023") return "invalid";
    if (result.error.code === "54000") return "busy";
    return "failed";
  }
  return result.data === "already" ? "already" : result.data === "stored" ? "stored" : "failed";
}
