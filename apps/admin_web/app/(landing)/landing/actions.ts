"use server";

import { checkInterest, isInterestKind, outcomeOf, type InterestOutcome } from "@/lib/landing/interest";
import { createClient } from "@/lib/supabase/server";

/**
 * Sends a request from the landing page's form. Anyone may call it (it acts as the visitor, with no special rights):
 * the database function validates again, drops spam caught by the hidden field and refuses floods. Nothing about the
 * sender is logged.
 */
export async function submitInterest(form: FormData): Promise<InterestOutcome> {
  const text = (key: string) => {
    const value = form.get(key);
    return typeof value === "string" ? value : "";
  };
  const kind = text("kind");
  const input = { kind, email: text("email"), name: text("name"), organisation: text("organisation"), message: text("message") };
  if (!isInterestKind(kind) || Object.keys(checkInterest(input)).length > 0) return "invalid";

  const supabase = await createClient();
  const result = await supabase.rpc("submit_interest", {
    p_kind: kind,
    p_email: input.email,
    p_name: input.name || undefined,
    p_organisation: input.organisation || undefined,
    p_message: input.message || undefined,
    p_locale: text("locale") === "fr" ? "fr" : "en",
    p_trap: text("website") || undefined,
  });
  return outcomeOf(result);
}
