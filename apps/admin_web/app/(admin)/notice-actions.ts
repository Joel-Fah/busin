"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { createClient } from "@/lib/supabase/server";

/**
 * Dismisses a reminder from BusIn (ADR 0027). The database checks the caller is an administrator of the notice's school;
 * the platform keeps the notice in its log, marked as dismissed.
 */
export async function dismissNotice(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = formData.get("notice");
  if (!isUuid(id)) redirect("/");
  const supabase = await createClient();
  const { error } = await supabase.rpc("dismiss_school_notice", { p_notice_id: id });
  revalidatePath("/");
  redirect(error ? "/" : "/?done=notice");
}
