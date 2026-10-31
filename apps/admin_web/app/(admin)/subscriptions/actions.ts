"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { isUuid, parseReason, reviewErrorKey } from "@/lib/subscriptions";

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
