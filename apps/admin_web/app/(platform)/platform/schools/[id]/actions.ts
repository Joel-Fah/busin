"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requirePlatformAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { SIGNALS } from "@/lib/platform-health";
import { isChannel, isPortalPath, SNOOZE_DAYS } from "@/lib/platform-outreach";
import { outreachErrorKey } from "@/lib/platform-outreach-errors";
import { createClient } from "@/lib/supabase/server";

/** The signals ticked in the form, known ones only. */
function signalsOf(formData: FormData): string[] {
  return formData.getAll("signal").filter((s): s is string => typeof s === "string" && (SIGNALS as readonly string[]).includes(s));
}

function snoozeOf(formData: FormData): number {
  const n = Number(formData.get("snooze"));
  return (SNOOZE_DAYS as readonly number[]).includes(n) ? n : 0;
}

function followUpOf(formData: FormData): string | null {
  const value = formData.get("followUp");
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value) ? value : null;
}

const page = (id: string) => `/platform/schools/${id}`;

/**
 * Sends a notice to the school's administrators (they see it on their overview) and logs it. The database function
 * checks the caller again, bounds the text, keeps the link inside the portal and writes the platform audit.
 */
export async function sendNotice(formData: FormData): Promise<void> {
  await requirePlatformAdmin();
  const id = formData.get("school");
  if (!isUuid(id)) redirect("/platform/schools");
  const body = formData.get("notice");
  const link = formData.get("link");

  const supabase = await createClient();
  const { error } = await supabase.rpc("platform_send_notice", {
    p_school_id: id,
    p_body: typeof body === "string" ? body : "",
    p_link_path: isPortalPath(link) ? link : undefined,
    p_signals: signalsOf(formData),
    p_snooze_days: snoozeOf(formData),
    p_follow_up_on: followUpOf(formData) ?? undefined,
  });
  if (error) redirect(`${page(id)}?error=${outreachErrorKey(error.message)}#reach-out`);
  revalidatePath("/platform", "layout");
  redirect(`${page(id)}?done=notice#reach-out`);
}

/** Logs a contact made outside BusIn (email, WhatsApp, call, meeting), pausing its signals if asked. */
export async function logOutreach(formData: FormData): Promise<void> {
  await requirePlatformAdmin();
  const id = formData.get("school");
  if (!isUuid(id)) redirect("/platform/schools");
  const channel = formData.get("channel");
  if (!isChannel(channel)) redirect(`${page(id)}?error=bad_channel#reach-out`);
  const note = formData.get("note");

  const supabase = await createClient();
  const { error } = await supabase.rpc("platform_log_outreach", {
    p_school_id: id,
    p_channel: channel,
    p_signals: signalsOf(formData),
    p_note: typeof note === "string" ? note : undefined,
    p_snooze_days: snoozeOf(formData),
    p_follow_up_on: followUpOf(formData) ?? undefined,
  });
  if (error) redirect(`${page(id)}?error=${outreachErrorKey(error.message)}#reach-out`);
  revalidatePath("/platform", "layout");
  redirect(`${page(id)}?done=logged#reach-out`);
}

/** Marks a follow-up done, from "Needs you" on the overview or from the school's page. */
export async function completeFollowUp(formData: FormData): Promise<void> {
  await requirePlatformAdmin();
  const id = formData.get("outreach");
  const back = formData.get("back") === "school" && isUuid(formData.get("school")) ? page(formData.get("school") as string) : "/platform";
  if (!isUuid(id)) redirect(back);

  const supabase = await createClient();
  const { error } = await supabase.rpc("platform_complete_follow_up", { p_outreach_id: id });
  if (error) redirect(`${back}?error=generic`);
  revalidatePath("/platform", "layout");
  redirect(`${back}?done=followUp`);
}
