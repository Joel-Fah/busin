import type { Metadata } from "next";
import { Suspense } from "react";

import { NewSchoolForm } from "@/components/platform/NewSchoolForm";
import { BackLink } from "@/components/ui/BackLink";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { PageHeader } from "@/components/ui/PageHeader";
import { requirePlatformAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { getMessages } from "@/lib/i18n/server";
import { timeZones } from "@/lib/platform-onboarding";
import { createClient } from "@/lib/supabase/server";

import { createSchool } from "./actions";

export const metadata: Metadata = { title: "New school" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ lead?: string | string[] }>;

export default function NewSchoolPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <NewSchool searchParams={searchParams} />
    </Suspense>
  );
}

async function NewSchool({ searchParams }: { searchParams: SearchParams }) {
  await requirePlatformAdmin();
  const { locale, t } = await getMessages();
  const o = t.platform.onboarding;
  // From a lead: its organisation and email fill the form.
  const leadParam = (await searchParams).lead;
  const leadId = Array.isArray(leadParam) ? leadParam[0] : leadParam;
  let initial: { name?: string; adminEmail?: string } | undefined;
  if (isUuid(leadId)) {
    const supabase = await createClient();
    const { data } = await supabase.rpc("platform_lead", { p_lead_id: leadId });
    const lead = data?.[0];
    if (lead?.kind === "school") initial = { name: lead.organisation ?? lead.name ?? undefined, adminEmail: lead.email ?? undefined };
  }
  return (
    <>
      <BackLink href="/platform/schools">{t.platform.school.back}</BackLink>
      <PageHeader title={o.title} />
      <NewSchoolForm action={createSchool} text={o} locale={locale} timeZones={timeZones()} initial={initial} leadId={initial && isUuid(leadId) ? leadId : undefined} />
    </>
  );
}
