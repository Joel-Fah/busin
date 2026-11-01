"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { parseSemesterForm, semesterSaveErrorKey } from "@/lib/semesters";
import { createClient } from "@/lib/supabase/server";

/**
 * Adds a semester to the admin's school. Row Level Security allows this only for administrators of
 * that school, and the database enforces the unique name and year and the date order. This action
 * validates the form first so the admin gets a clear message.
 */
export async function createSemester(formData: FormData): Promise<void> {
  const admin = await requireAdmin();

  const parsed = parseSemesterForm(formData);
  if (!parsed.ok) redirect(`/semesters/new?error=${parsed.error}`);
  const { name, year, startDate, endDate } = parsed.value;

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("semesters")
    .insert({ school_id: admin.schoolId, name, year, start_date: startDate, end_date: endDate })
    .select("id")
    .single();
  if (error || !data) redirect(`/semesters/new?error=${semesterSaveErrorKey(error?.code)}`);

  revalidatePath("/semesters");
  redirect(`/semesters/${data.id}?done=created`);
}

/** Saves changes to a semester. A semester of another school simply is not found, because of RLS. */
export async function updateSemester(formData: FormData): Promise<void> {
  await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/semesters");

  const parsed = parseSemesterForm(formData);
  if (!parsed.ok) redirect(`/semesters/${id}?error=${parsed.error}`);
  const { name, year, startDate, endDate } = parsed.value;

  const supabase = await createClient();
  const { error } = await supabase
    .from("semesters")
    .update({ name, year, start_date: startDate, end_date: endDate })
    .eq("id", id)
    .select("id")
    .single();
  if (error) redirect(`/semesters/${id}?error=${semesterSaveErrorKey(error.code)}`);

  revalidatePath("/semesters");
  redirect(`/semesters/${id}?done=saved`);
}
