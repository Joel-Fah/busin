"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { busSaveErrorKey, parseBusForm } from "@/lib/buses";
import { isUuid } from "@/lib/ids";
import { safeNext } from "@/lib/next-path";
import { createClient } from "@/lib/supabase/server";

/**
 * Adds a bus to the admin's school. Row Level Security allows this only for administrators of
 * that school, and the database enforces the unique plate. This action validates the form first
 * so the admin gets a clear message.
 */
export async function createBus(formData: FormData): Promise<void> {
  const admin = await requireAdmin();

  // A detour from another page (the trip form) goes back there with the new bus chosen.
  const next = safeNext(formData.get("next"));
  const again = (query: string) => `/buses/new?${query}${next ? `&next=${encodeURIComponent(next)}` : ""}`;
  const parsed = parseBusForm(formData);
  if (!parsed.ok) redirect(again(`error=${parsed.error}`));
  const { plate, name, capacity, inService } = parsed.value;

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("buses")
    .insert({ school_id: admin.schoolId, plate, name, capacity, in_service: inService })
    .select("id")
    .single();
  if (error || !data) redirect(again(`error=${busSaveErrorKey(error?.code, error?.message)}`));

  revalidatePath("/buses");
  if (next === "/trips/new") redirect(`/trips/new?bus=${data.id}`);
  if (next === "/") redirect("/?done=bus");
  redirect(`/buses/${data.id}?done=created`);
}

/** Saves changes to a bus. A bus of another school simply is not found, because of RLS. */
export async function updateBus(formData: FormData): Promise<void> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/buses");

  const parsed = parseBusForm(formData);
  if (!parsed.ok) redirect(`/buses/${id}?error=${parsed.error}`);
  const { plate, name, capacity, inService } = parsed.value;

  const supabase = await createClient();
  const { error } = await supabase
    .from("buses")
    .update({ plate, name, capacity, in_service: inService })
    .eq("id", id)
    .select("id")
    .single();
  if (error) redirect(`/buses/${id}?error=${busSaveErrorKey(error.code, error.message)}`);

  revalidatePath("/buses");
  redirect(`/buses/${id}?done=saved`);
}
