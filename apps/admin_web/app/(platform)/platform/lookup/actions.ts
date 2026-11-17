"use server";

import { requirePlatformAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { lookupErrorKey, parseLookup, type LookedUp, type LookupError } from "@/lib/platform-lookup";
import { createClient } from "@/lib/supabase/server";

export type LookupState = { email: string; result: LookedUp | null; error: LookupError | null };

/**
 * Looks up one account by its exact email. A server action, so the email typed never goes into the address (history,
 * logs). The database checks the caller, limits the lookups and records each one in the platform audit.
 */
export async function lookupAccount(_previous: LookupState, formData: FormData): Promise<LookupState> {
  await requirePlatformAdmin();
  const email = typeof formData.get("email") === "string" ? (formData.get("email") as string).trim() : "";
  const supabase = await createClient();
  // Scheduling or cancelling a deletion (ADR 0028) for the account shown, after confirming with the person by email;
  // the account is then looked up again, so the card shows the new state.
  const intent = formData.get("intent");
  const user = formData.get("user");
  if ((intent === "schedule" || intent === "cancel") && isUuid(user)) {
    const scheduled = await supabase.rpc("platform_schedule_deletion", { p_user_id: user, p_schedule: intent === "schedule" });
    if (scheduled.error) {
      const again = await supabase.rpc("platform_lookup_account", { p_email: email });
      return { email, result: again.error ? null : parseLookup(again.data), error: lookupErrorKey(scheduled.error.message) };
    }
  }
  const { data, error } = await supabase.rpc("platform_lookup_account", { p_email: email });
  if (error) return { email, result: null, error: lookupErrorKey(error.message) };
  return { email, result: parseLookup(data), error: null };
}
