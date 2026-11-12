"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import type { ReasonFormState } from "@/components/ReasonForm";
import { requireAdmin } from "@/lib/auth";
import { checkReason, reasonProblemFromDb } from "@/lib/reasons";
import { createClient } from "@/lib/supabase/server";
import { MAX_REASON_LENGTH, isUuid, reinstateErrorKey, revokeErrorKey, reviewErrorKey } from "@/lib/subscriptions";

/**
 * Approves a pending subscription. The decision itself is made by the database function `admin_review_subscription`,
 * which checks the caller again, refuses anything but a pending subscription, refuses one with no proof or for a
 * semester that has ended, and writes the audit log.
 */
export async function approveSubscription(formData: FormData): Promise<void> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/subscriptions");

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_review_subscription", { p_subscription_id: id, p_decision: "approved" });
  if (error) redirect(`/subscriptions/${id}?error=${reviewErrorKey(error.code, error.message)}`);

  revalidatePath("/subscriptions");
  redirect(`/subscriptions/${id}?done=approved`);
}

/** The typed reason, checked; the text goes back to the form when it is not good enough. */
function reasonOf(formData: FormData) {
  const raw = formData.get("note");
  const text = typeof raw === "string" ? raw : "";
  return { text, checked: checkReason(text, { required: true, max: MAX_REASON_LENGTH }) };
}

/**
 * Rejects a pending subscription with a reason the student can read (10 to 500 characters). A problem is answered to the
 * form, which keeps what was typed and says what is wrong; success goes to the page's own message.
 */
export async function rejectSubscription(_previous: ReasonFormState, formData: FormData): Promise<ReasonFormState> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/subscriptions");
  const { text, checked } = reasonOf(formData);
  if (!checked.ok) return { error: checked.problem, text };

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_review_subscription", { p_subscription_id: id, p_decision: "rejected", p_note: checked.value ?? undefined });
  if (error) return { error: reasonProblemFromDb(error.code, error.message) ?? reviewErrorKey(error.code, error.message), text };

  revalidatePath("/subscriptions");
  redirect(`/subscriptions/${id}?done=rejected`);
}

/**
 * Ends an approved subscription early, with a reason the student can read. The database function
 * `admin_revoke_subscription` checks the caller again, refuses anything but an approved subscription and writes the
 * audit log; from the next scan the student is refused at the door and they may ask again.
 */
export async function revokeSubscription(_previous: ReasonFormState, formData: FormData): Promise<ReasonFormState> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/subscriptions");
  const { text, checked } = reasonOf(formData);
  if (!checked.ok) return { error: checked.problem, text };

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_revoke_subscription", { p_subscription_id: id, p_note: checked.value ?? "" });
  if (error) return { error: reasonProblemFromDb(error.code, error.message) ?? revokeErrorKey(error.code), text };

  revalidatePath("/subscriptions");
  redirect(`/subscriptions/${id}?done=revoked`);
}

/**
 * Gives a revoked subscription back, with a reason like the others. The database function `admin_reinstate_subscription`
 * checks the caller again, refuses anything but a revoked subscription (and one whose student has a newer live request,
 * or whose semester has ended), records it as its own operation in the subscription's history and tells the student.
 */
export async function reinstateSubscription(_previous: ReasonFormState, formData: FormData): Promise<ReasonFormState> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/subscriptions");
  const { text, checked } = reasonOf(formData);
  if (!checked.ok) return { error: checked.problem, text };

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_reinstate_subscription", { p_subscription_id: id, p_note: checked.value ?? undefined });
  if (error) return { error: reasonProblemFromDb(error.code, error.message) ?? reinstateErrorKey(error.code, error.message), text };

  revalidatePath("/subscriptions");
  redirect(`/subscriptions/${id}?done=reinstated`);
}
