"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { toEwkt } from "@/lib/geo";
import { isUuid } from "@/lib/ids";
import { parseStopForm, stopSaveErrorKey } from "@/lib/stops";
import { createClient } from "@/lib/supabase/server";

/**
 * Adds a stop to the admin's school. Row Level Security allows this only for administrators of
 * that school, and the database enforces the unique name and a valid position. This action
 * validates the form first so the admin gets a clear message.
 */
export async function createStop(formData: FormData): Promise<void> {
  const admin = await requireAdmin();

  const parsed = parseStopForm(formData);
  if (!parsed.ok) redirect(`/stops/new?error=${parsed.error}`);
  const { name, position, active } = parsed.value;

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("stops")
    .insert({ school_id: admin.schoolId, name, location: toEwkt(position), active })
    .select("id")
    .single();
  if (error || !data) redirect(`/stops/new?error=${stopSaveErrorKey(error?.code)}`);

  revalidatePath("/stops");
  redirect(`/stops/${data.id}?done=created`);
}

/** Saves changes to a stop. A stop of another school simply is not found, because of RLS. */
export async function updateStop(formData: FormData): Promise<void> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/stops");

  const parsed = parseStopForm(formData);
  if (!parsed.ok) redirect(`/stops/${id}?error=${parsed.error}`);
  const { name, position, active } = parsed.value;

  const supabase = await createClient();
  const { error } = await supabase
    .from("stops")
    .update({ name, location: toEwkt(position), active })
    .eq("id", id)
    .select("id")
    .single();
  if (error) redirect(`/stops/${id}?error=${stopSaveErrorKey(error.code)}`);

  revalidatePath("/stops");
  redirect(`/stops/${id}?done=saved`);
}
