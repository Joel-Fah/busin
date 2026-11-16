"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { deletionBack, deletionErrorKey } from "@/lib/account-deletion";
import { getCurrentUser } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";

/**
 * Asks for the deletion of the signed-in person's own account (ADR 0028). The database checks who asks, refuses the last
 * administrator of a school and someone on a running trip, and schedules it 7 days ahead.
 */
export async function requestAccountDeletion(formData: FormData): Promise<void> {
  const back = deletionBack(formData.get("back"));
  if (!(await getCurrentUser())) redirect("/login");
  const supabase = await createClient();
  const { error } = await supabase.rpc("request_account_deletion");
  if (error) redirect(`${back}?deletion_error=${deletionErrorKey(error.message)}#delete-account`);
  revalidatePath(back);
  redirect(`${back}?deletion=requested#delete-account`);
}

/** Cancels the signed-in person's scheduled deletion. */
export async function cancelAccountDeletion(formData: FormData): Promise<void> {
  const back = deletionBack(formData.get("back"));
  if (!(await getCurrentUser())) redirect("/login");
  const supabase = await createClient();
  const { error } = await supabase.rpc("cancel_account_deletion");
  if (error) redirect(`${back}?deletion_error=generic#delete-account`);
  revalidatePath(back);
  redirect(`${back}?deletion=cancelled#delete-account`);
}
