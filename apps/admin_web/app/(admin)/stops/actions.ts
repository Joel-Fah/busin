"use server";

import { revalidatePath } from "next/cache";

import { requireAdmin } from "@/lib/auth";
import { toEwkt } from "@/lib/geo";
import { isUuid } from "@/lib/ids";
import { deleteStopErrorKey, parseStopForm, stopSaveErrorKey, type DeleteStopErrorKey, type StopFormErrorKey } from "@/lib/stops";
import { createClient } from "@/lib/supabase/server";

export type SaveStopState =
  | { status: "idle" }
  | { status: "saved"; id: string; created: boolean }
  | { status: "error"; error: StopFormErrorKey };

/**
 * Adds a stop to the admin's school, or saves changes to one when the form carries an `id`. It answers
 * the sheet on the Stops page with a result instead of sending the browser to another page. Row Level
 * Security allows this only for administrators of that school (a stop of another school is simply not
 * found), and the database enforces the unique name and a valid position. The form is checked first so
 * the admin gets a clear message.
 */
export async function saveStop(_previous: SaveStopState, formData: FormData): Promise<SaveStopState> {
  const admin = await requireAdmin();

  const parsed = parseStopForm(formData);
  if (!parsed.ok) return { status: "error", error: parsed.error };
  const { name, position, active } = parsed.value;
  const supabase = await createClient();

  const id = formData.get("id");
  if (id === null || id === "") {
    const { data, error } = await supabase
      .from("stops")
      .insert({ school_id: admin.schoolId, name, location: toEwkt(position), active })
      .select("id")
      .single();
    if (error || !data) return { status: "error", error: stopSaveErrorKey(error?.code, error?.message) };
    revalidatePath("/stops");
    return { status: "saved", id: data.id, created: true };
  }

  if (!isUuid(id)) return { status: "error", error: "not_found" };
  const { error } = await supabase.from("stops").update({ name, location: toEwkt(position), active }).eq("id", id).select("id").single();
  if (error) return { status: "error", error: stopSaveErrorKey(error.code, error.message) };
  revalidatePath("/stops");
  return { status: "saved", id, created: false };
}

export type DeleteStopResult = { status: "deleted" } | { status: "error"; error: DeleteStopErrorKey };

/**
 * Deletes a stop nothing ever used (no subscription in any state, no boarding). The database decides and audits it; a
 * stop in use is refused with a reason the sheet explains, and a stop of another school is simply not found.
 */
export async function deleteStop(id: string): Promise<DeleteStopResult> {
  await requireAdmin();
  if (!isUuid(id)) return { status: "error", error: "not_found" };
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_delete_stop", { p_stop_id: id });
  if (error) return { status: "error", error: deleteStopErrorKey(error.code, error.message) };
  revalidatePath("/stops");
  return { status: "deleted" };
}
