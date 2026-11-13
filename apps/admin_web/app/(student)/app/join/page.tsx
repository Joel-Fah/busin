import type { Metadata } from "next";
import { Suspense } from "react";

import { GatePage } from "@/components/student/GatePage";
import { SchoolChooser, type OpenSchool } from "@/components/student/SchoolChooser";
import { SignOutForm } from "@/components/student/SignOutForm";
import { EmptyState } from "@/components/ui/EmptyState";
import { Notice } from "@/components/ui/Notice";
import { supabaseConfig } from "@/lib/env";
import { format } from "@/lib/i18n/format";
import { getStudentCopy } from "@/lib/i18n/server";
import { logoUrl } from "@/lib/school";
import { requireGate } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Choose your school" };
export const instant = false;

export default function JoinPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh bg-bg" aria-busy="true" />}>
      <Join />
    </Suspense>
  );
}

/**
 * A student whose Google account is not a school email chooses the school to ask (ADR 0012). If the last request was
 * declined, the school's reason comes first.
 */
async function Join() {
  await requireGate("needsSchool");
  const { locale, s } = await getStudentCopy();
  const supabase = await createClient();
  const [schools, last] = await Promise.all([supabase.rpc("list_open_schools"), supabase.rpc("my_join_request")]);
  const { url } = supabaseConfig();
  const open: OpenSchool[] = (schools.data ?? []).map((school) => ({
    id: school.id,
    name: school.name,
    place: [school.city, school.country].filter(Boolean).join(", "),
    logoUrl: logoUrl(school.logo_path, url),
  }));
  const declined = last.data?.[0]?.declined_at ? last.data[0] : null;

  return (
    <GatePage lang={locale} title={s.join.title} intro={s.join.body}>
      {declined ? (
        <Notice tone="warn">
          <strong className="block">{format(s.join.declinedTitle, { school: declined.declined_school_name ?? "" })}</strong>
          {declined.decline_note ? format(s.join.declinedReason, { reason: declined.decline_note }) : s.join.declinedNoReason}
        </Notice>
      ) : null}
      {schools.error ? (
        <Notice tone="bad">{s.join.failed}</Notice>
      ) : open.length === 0 ? (
        <EmptyState title={s.join.emptyTitle} body={s.join.emptyBody} />
      ) : (
        <SchoolChooser schools={open} copy={s.join} />
      )}
      <div className="mt-auto pt-6">
        <SignOutForm label={s.profile.signOut} />
      </div>
    </GatePage>
  );
}
