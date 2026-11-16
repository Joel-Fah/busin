"use server";

import { checkInterest, outcomeOf, type InterestOutcome } from "@/lib/landing/interest";
import { createClient } from "@/lib/supabase/server";

/**
 * Someone who cannot sign in any more asks for their account's deletion (ADR 0028). It becomes a 'deletion' lead the
 * platform confirms by email before scheduling it. Anyone may call it; the database checks and limits it like the
 * landing's other requests, and nothing about the sender is logged.
 */
export async function requestDeletionByEmail(_previous: InterestOutcome | null, form: FormData): Promise<InterestOutcome> {
  const text = (key: string) => (typeof form.get(key) === "string" ? (form.get(key) as string) : "");
  const input = { kind: "deletion", email: text("email"), message: text("message") };
  if (Object.keys(checkInterest(input)).length > 0) return "invalid";
  const supabase = await createClient();
  const result = await supabase.rpc("submit_interest", {
    p_kind: "deletion",
    p_email: input.email,
    p_message: input.message || undefined,
    p_locale: text("locale") === "fr" ? "fr" : "en",
    p_trap: text("website") || undefined,
  });
  return outcomeOf(result);
}
