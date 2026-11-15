"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requirePlatformAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { isLeadStatus } from "@/lib/platform-leads";
import { createClient } from "@/lib/supabase/server";

/** Back to the list the action came from (its filters and page), never another page. */
function backTo(formData: FormData): string {
  const back = formData.get("back");
  return typeof back === "string" && /^\/platform\/leads(\?[a-z0-9=&]*)?$/.test(back) ? back : "/platform/leads";
}

const withParam = (href: string, key: string, value: string) => `${href}${href.includes("?") ? "&" : "?"}${key}=${value}`;

/** Marks a lead contacted, dismissed or new again. The database checks the caller and writes the platform audit. */
export async function setLeadStatus(formData: FormData): Promise<void> {
  await requirePlatformAdmin();
  const back = backTo(formData);
  const id = formData.get("lead");
  const status = formData.get("status");
  if (!isUuid(id) || !isLeadStatus(status) || status === "converted") redirect(back);

  const supabase = await createClient();
  const { error } = await supabase.rpc("platform_update_lead", { p_lead_id: id, p_status: status });
  if (error) redirect(withParam(back, "error", "generic"));
  revalidatePath("/platform", "layout");
  redirect(withParam(back, "done", status));
}

/** Saves the note of a lead, keeping its status. */
export async function saveLeadNote(formData: FormData): Promise<void> {
  await requirePlatformAdmin();
  const back = backTo(formData);
  const id = formData.get("lead");
  const status = formData.get("status");
  const note = formData.get("note");
  if (!isUuid(id) || !isLeadStatus(status)) redirect(back);

  const supabase = await createClient();
  const { error } = await supabase.rpc("platform_update_lead", { p_lead_id: id, p_status: status, p_note: typeof note === "string" ? note : "" });
  if (error) redirect(withParam(back, "error", error.message === "note_too_long" ? "note_too_long" : "generic"));
  revalidatePath("/platform", "layout");
  redirect(withParam(back, "done", "note"));
}
