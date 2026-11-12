"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { parseUnitForm, unitSaveErrorKey, type UnitDoneKey } from "@/lib/academics";
import { requireAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { createClient } from "@/lib/supabase/server";

/*
  Faculties, departments and degree levels. Row Level Security allows writes only to administrators of the school;
  these actions validate first so the admin gets a clear message. Each ends back on the page with ?done= or ?error=.
*/

function back(key: "done" | "error", value: string): never {
  revalidatePath("/academics");
  redirect(`/academics?${key}=${value}`);
}

function done(key: UnitDoneKey): never {
  back("done", key);
}

export async function addFaculty(formData: FormData): Promise<void> {
  const admin = await requireAdmin();
  const parsed = parseUnitForm(formData);
  if (!parsed.ok) back("error", parsed.error);
  const supabase = await createClient();
  const { error } = await supabase.from("faculties").insert({ school_id: admin.schoolId, ...parsed.value });
  if (error) back("error", unitSaveErrorKey(error.code));
  done("faculty_added");
}

export async function saveFaculty(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = formData.get("id");
  if (!isUuid(id)) back("error", "not_found");
  const parsed = parseUnitForm(formData);
  if (!parsed.ok) back("error", parsed.error);
  const supabase = await createClient();
  const { error } = await supabase.from("faculties").update(parsed.value).eq("id", id).select("id").single();
  if (error) back("error", unitSaveErrorKey(error.code));
  done("faculty_saved");
}

/** A faculty that still has departments is refused by the database (restrict), and the admin is told why. */
export async function removeFaculty(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = formData.get("id");
  if (!isUuid(id)) back("error", "not_found");
  const supabase = await createClient();
  const { error } = await supabase.from("faculties").delete().eq("id", id);
  if (error) back("error", unitSaveErrorKey(error.code));
  done("faculty_removed");
}

export async function addDepartment(formData: FormData): Promise<void> {
  const admin = await requireAdmin();
  const facultyId = formData.get("faculty_id");
  if (!isUuid(facultyId)) back("error", "not_found");
  const parsed = parseUnitForm(formData);
  if (!parsed.ok) back("error", parsed.error);
  const supabase = await createClient();
  const { error } = await supabase.from("departments").insert({ school_id: admin.schoolId, faculty_id: facultyId, ...parsed.value });
  if (error) back("error", unitSaveErrorKey(error.code));
  done("department_added");
}

export async function saveDepartment(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = formData.get("id");
  if (!isUuid(id)) back("error", "not_found");
  const parsed = parseUnitForm(formData);
  if (!parsed.ok) back("error", parsed.error);
  const supabase = await createClient();
  const { error } = await supabase.from("departments").update(parsed.value).eq("id", id).select("id").single();
  if (error) back("error", unitSaveErrorKey(error.code));
  done("department_saved");
}

/** Students who chose it simply have no department afterwards (the database clears their choice). */
export async function removeDepartment(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = formData.get("id");
  if (!isUuid(id)) back("error", "not_found");
  const supabase = await createClient();
  const { error } = await supabase.from("departments").delete().eq("id", id);
  if (error) back("error", unitSaveErrorKey(error.code));
  done("department_removed");
}

export async function addProgram(formData: FormData): Promise<void> {
  const admin = await requireAdmin();
  const parsed = parseUnitForm(formData);
  if (!parsed.ok) back("error", parsed.error);
  const supabase = await createClient();
  const { error } = await supabase.from("programs").insert({ school_id: admin.schoolId, name: parsed.value.name });
  if (error) back("error", unitSaveErrorKey(error.code));
  done("program_added");
}

export async function saveProgram(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = formData.get("id");
  if (!isUuid(id)) back("error", "not_found");
  const parsed = parseUnitForm(formData);
  if (!parsed.ok) back("error", parsed.error);
  const supabase = await createClient();
  const { error } = await supabase.from("programs").update({ name: parsed.value.name }).eq("id", id).select("id").single();
  if (error) back("error", unitSaveErrorKey(error.code));
  done("program_saved");
}

export async function removeProgram(formData: FormData): Promise<void> {
  await requireAdmin();
  const id = formData.get("id");
  if (!isUuid(id)) back("error", "not_found");
  const supabase = await createClient();
  const { error } = await supabase.from("programs").delete().eq("id", id);
  if (error) back("error", unitSaveErrorKey(error.code));
  done("program_removed");
}
