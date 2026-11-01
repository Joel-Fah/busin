"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { isRole, peopleErrorKey } from "@/lib/people";
import { createClient } from "@/lib/supabase/server";

/**
 * Changes a person's role. The database function `admin_set_user_role` checks the caller again,
 * refuses a change to the caller's own account, limits the change to this school and writes the
 * audit log. This action only validates the form and reports the outcome.
 */
export async function changeRole(formData: FormData): Promise<void> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/people");

  const role = formData.get("role");
  if (!isRole(role)) redirect(`/people/${id}?error=invalid`);

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_set_user_role", { p_user_id: id, p_role: role });
  if (error) redirect(`/people/${id}?error=${peopleErrorKey(error.code)}`);

  revalidatePath("/people");
  redirect(`/people/${id}?done=role`);
}

/** Suspends an account or restores it. Same checks and audit trail as `changeRole`. */
export async function changeStatus(formData: FormData): Promise<void> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/people");

  const status = formData.get("status");
  if (status !== "suspended" && status !== "verified") redirect(`/people/${id}?error=invalid`);

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_set_user_status", { p_user_id: id, p_status: status });
  if (error) redirect(`/people/${id}?error=${peopleErrorKey(error.code)}`);

  revalidatePath("/people");
  redirect(`/people/${id}?done=${status === "suspended" ? "suspended" : "restored"}`);
}
