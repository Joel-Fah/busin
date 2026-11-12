"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { MAX_LOGO_BYTES, SCHOOL_TERMS_VERSION, isWebp, parseSchoolForm, schoolSaveError } from "@/lib/school";
import { createClient } from "@/lib/supabase/server";

/** Saves the school profile through the database function, which checks the admin and every field again. */
export async function saveSchoolProfile(formData: FormData): Promise<void> {
  await requireAdmin();
  const parsed = parseSchoolForm(formData);
  if (!parsed.ok) redirect(`/school?error=${parsed.field}`);
  const v = parsed.value;

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_update_school_profile", {
    p_name: v.name,
    p_short_name: v.shortName,
    p_website: v.website,
    p_contact_email: v.contactEmail,
    p_phone: v.phone,
    p_address: v.address,
    p_city: v.city,
    p_country: v.country,
    p_about: v.about,
    p_accepts_open_signup: v.acceptsOpenSignup,
    p_public_listing: v.publicListing,
    p_open_signup_domains: v.openSignupDomains,
  });
  if (error) redirect(`/school?error=${schoolSaveError(error.code, error.message)}`);

  revalidatePath("/school");
  revalidatePath("/landing");
  redirect("/school?done=saved");
}

/** Turns on or off that staff can start a trip from the ops app when none was scheduled (ADR 0020). */
export async function saveFieldTrips(formData: FormData): Promise<void> {
  await requireAdmin();
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_set_field_trips", { p_allowed: formData.get("allow_field_trips") === "on" });
  if (error) redirect("/school?error=generic");
  revalidatePath("/school");
  redirect("/school?done=field_trips");
}

/** The school accepts the current version of the terms for schools. */
export async function acceptSchoolTerms(): Promise<void> {
  await requireAdmin();
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_accept_school_terms", { p_version: SCHOOL_TERMS_VERSION });
  if (error) redirect("/school?error=generic");
  revalidatePath("/school");
  redirect("/school?done=terms");
}

export type LogoResult = "saved" | "removed" | "failed";

/**
 * Stores a new logo. The browser has already shrunk it to a 512 px WebP; this checks it really is a small WebP, uploads
 * it to the school's folder as the signed-in admin (the storage policy allows only that folder), points the school at it,
 * and removes the previous file.
 */
export async function uploadSchoolLogo(formData: FormData): Promise<LogoResult> {
  const admin = await requireAdmin();
  const file = formData.get("logo");
  if (!(file instanceof Blob) || file.size === 0 || file.size > MAX_LOGO_BYTES) return "failed";
  const bytes = new Uint8Array(await file.arrayBuffer());
  if (!isWebp(bytes)) return "failed";

  const supabase = await createClient();
  const { data: before } = await supabase.from("schools").select("logo_path").eq("id", admin.schoolId).maybeSingle();
  const path = `${admin.schoolId}/logo-${Date.now()}.webp`;
  const upload = await supabase.storage.from("school-logos").upload(path, bytes, { contentType: "image/webp", upsert: false });
  if (upload.error) return "failed";
  const { error } = await supabase.rpc("admin_set_school_logo", { p_path: path });
  if (error) {
    await supabase.storage.from("school-logos").remove([path]);
    return "failed";
  }
  if (before?.logo_path) await supabase.storage.from("school-logos").remove([before.logo_path]);
  revalidatePath("/school");
  return "saved";
}

/** Removes the logo: the school points at none, then the file is deleted. */
export async function removeSchoolLogo(): Promise<LogoResult> {
  const admin = await requireAdmin();
  const supabase = await createClient();
  const { data: before } = await supabase.from("schools").select("logo_path").eq("id", admin.schoolId).maybeSingle();
  // The generated types do not mark function arguments as nullable; the function takes null to mean "no logo".
  const { error } = await supabase.rpc("admin_set_school_logo", { p_path: null as unknown as string });
  if (error) return "failed";
  if (before?.logo_path) await supabase.storage.from("school-logos").remove([before.logo_path]);
  revalidatePath("/school");
  return "removed";
}
