"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requirePlatformAdmin } from "@/lib/auth";
import { onboardingErrorKey, readNewSchool, type OnboardingError } from "@/lib/platform-onboarding";
import { createClient } from "@/lib/supabase/server";

/** What was typed, given back with a refusal so the form keeps it (a form action resets the fields). */
export type TypedSchool = { name: string; shortName: string; city: string; country: string; timezone: string; adminEmail: string };
export type CreateSchoolState = { error: OnboardingError | null; typed?: TypedSchool };

const typedOf = (form: FormData): TypedSchool => {
  const read = (key: string) => (typeof form.get(key) === "string" ? (form.get(key) as string) : "");
  return { name: read("name"), shortName: read("short_name"), city: read("city"), country: read("country"), timezone: read("timezone"), adminEmail: read("admin_email") };
};

/**
 * Creates a school, then invites its first administrator when an email was given. The database functions check the
 * caller again, apply the same rules and write the platform audit. A refused form comes back with what was typed; an
 * invite that fails after the school exists sends the admin to the school's page to try again there.
 */
export async function createSchool(_previous: CreateSchoolState, formData: FormData): Promise<CreateSchoolState> {
  await requirePlatformAdmin();
  const read = readNewSchool(formData);
  if (!read.ok) return { error: read.error, typed: typedOf(formData) };
  const school = read.value;

  const supabase = await createClient();
  const { data: id, error } = await supabase.rpc("platform_create_school", {
    p_name: school.name,
    p_short_name: school.shortName ?? undefined,
    p_timezone: school.timezone,
    p_country: school.country ?? undefined,
    p_city: school.city ?? undefined,
    p_domains: school.domains,
  });
  if (error || !id) return { error: onboardingErrorKey(error?.message), typed: typedOf(formData) };

  revalidatePath("/platform", "layout");
  if (!school.adminEmail) redirect(`/platform/schools/${id}?done=created`);

  const invite = await supabase.rpc("platform_invite_school_admin", { p_school_id: id, p_email: school.adminEmail });
  if (invite.error) redirect(`/platform/schools/${id}?done=created&error=${onboardingErrorKey(invite.error.message)}#admins`);
  redirect(`/platform/schools/${id}?done=${invite.data === "applied" ? "applied" : "invited"}`);
}
