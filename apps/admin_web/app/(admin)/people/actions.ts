"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { inviteErrorKey, isInviteRole, normalizeInviteEmail } from "@/lib/invites";
import { MAX_DECLINE_REASON, isRole, peopleErrorKey } from "@/lib/people";
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

/** Where to go back to after deciding a request: the queue, or the person's page when the decision was made there. */
function back(formData: FormData, id: string, outcome: string): string {
  return formData.get("from") === "detail" ? `/people/${id}?${outcome}` : `/people?role=verify&${outcome}`;
}

/** Lets in a student who asked to join the school. The database checks the request is for this school and still open. */
export async function verifyMember(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = formData.get("id");
  if (!isUuid(id)) redirect("/people?role=verify");

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_verify_member", { p_user_id: id });
  if (error) redirect(back(formData, id, `error=${peopleErrorKey(error.code)}`));

  revalidatePath("/people");
  redirect(back(formData, id, "done=verified"));
}

/** Declines a request to join, with an optional reason the student will see. */
export async function declineMember(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = formData.get("id");
  if (!isUuid(id)) redirect("/people?role=verify");
  const raw = formData.get("reason");
  const reason = typeof raw === "string" ? raw.trim().slice(0, MAX_DECLINE_REASON) : "";

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_decline_member", { p_user_id: id, p_reason: reason });
  if (error) redirect(back(formData, id, `error=${peopleErrorKey(error.code)}`));

  revalidatePath("/people");
  redirect(formData.get("from") === "detail" ? "/people?role=verify&done=declined" : back(formData, id, "done=declined"));
}

/**
 * Adds a staff member or an administrator by email (ADR 0015). The database function checks the caller, applies the role
 * at once to an account of the school (or one without a school), or keeps the invite for the first sign-in.
 */
export async function inviteStaff(formData: FormData): Promise<void> {
  await requireAdmin();
  const email = normalizeInviteEmail(formData.get("email"));
  if (!email) redirect("/people/invite?error=invalid_email");
  const role = formData.get("role");
  if (!isInviteRole(role)) redirect("/people/invite?error=invalid_role");

  const supabase = await createClient();
  const { data, error } = await supabase.rpc("admin_invite_staff", { p_email: email, p_role: role });
  if (error) redirect(`/people/invite?error=${inviteErrorKey(error.code, error.message)}`);

  revalidatePath("/people");
  redirect(`/people/invite?done=${data === "applied" ? "applied" : "invited"}`);
}

/** Withdraws an open invite of the school. */
export async function cancelInvite(formData: FormData): Promise<void> {
  await requireAdmin();
  // From the Invited tab of People, back there; otherwise back to the invite page.
  const fromPeople = formData.get("from") === "people";
  const email = normalizeInviteEmail(formData.get("email"));
  if (!email) redirect(fromPeople ? "/people?role=invited" : "/people/invite");

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_cancel_invite", { p_email: email });
  if (error) redirect(fromPeople ? "/people?role=invited&error=generic" : "/people/invite?error=generic");

  revalidatePath("/people");
  redirect(fromPeople ? "/people?role=invited&done=withdrawn" : "/people/invite?done=cancelled");
}
