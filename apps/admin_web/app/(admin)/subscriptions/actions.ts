"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { isUuid, parseReason, reinstateErrorKey, revokeErrorKey, reviewErrorKey } from "@/lib/subscriptions";

/**
 * Approves or rejects a pending subscription.
 * The decision itself is made by the database function `admin_review_subscription`, which
 * checks the caller again, refuses anything but a pending subscription and writes the audit
 * log. This action only validates the form and reports the outcome.
 */
export async function reviewSubscription(formData: FormData): Promise<void> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/subscriptions");

  const decision = formData.get("decision");
  if (decision !== "approved" && decision !== "rejected") {
    redirect(`/subscriptions/${id}?error=invalid`);
  }

  const reason = parseReason(formData.get("note"));
  if (decision === "rejected" && reason === null) {
    redirect(`/subscriptions/${id}?error=invalid`);
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_review_subscription", {
    p_subscription_id: id,
    p_decision: decision,
    // A note only accompanies a rejection.
    p_note: decision === "rejected" ? (reason ?? undefined) : undefined,
  });

  if (error) {
    redirect(`/subscriptions/${id}?error=${reviewErrorKey(error.code)}`);
  }

  revalidatePath("/subscriptions");
  redirect(`/subscriptions/${id}?done=${decision}`);
}

/**
 * Ends an approved subscription early, with a reason the student can read. The database function
 * `admin_revoke_subscription` checks the caller again, refuses anything but an approved subscription and writes the
 * audit log; from the next scan the student is refused at the door and they may ask again.
 */
export async function revokeSubscription(formData: FormData): Promise<void> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/subscriptions");

  const reason = parseReason(formData.get("note"));
  if (reason === null) redirect(`/subscriptions/${id}?error=invalid`);

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_revoke_subscription", { p_subscription_id: id, p_note: reason });
  if (error) redirect(`/subscriptions/${id}?error=${revokeErrorKey(error.code)}`);

  revalidatePath("/subscriptions");
  redirect(`/subscriptions/${id}?done=revoked`);
}

/**
 * Gives a revoked subscription back. The database function `admin_reinstate_subscription` checks the caller again, refuses
 * anything but a revoked subscription (and one whose student has a newer live request), records it as its own operation
 * in the subscription's history and tells the student. The note is optional.
 */
export async function reinstateSubscription(formData: FormData): Promise<void> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/subscriptions");

  const raw = formData.get("note");
  const note = parseReason(raw);
  // A note that is there but unusable (too long) is refused; an empty one is simply no note.
  if (note === null && typeof raw === "string" && raw.trim() !== "") redirect(`/subscriptions/${id}?error=invalid`);

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_reinstate_subscription", { p_subscription_id: id, p_note: note ?? undefined });
  if (error) redirect(`/subscriptions/${id}?error=${reinstateErrorKey(error.code, error.message)}`);

  revalidatePath("/subscriptions");
  redirect(`/subscriptions/${id}?done=reinstated`);
}
