import type { Metadata } from "next";
import { Suspense } from "react";

import { NewSchoolForm } from "@/components/platform/NewSchoolForm";
import { BackLink } from "@/components/ui/BackLink";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { PageHeader } from "@/components/ui/PageHeader";
import { requirePlatformAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { timeZones } from "@/lib/platform-onboarding";

import { createSchool } from "./actions";

export const metadata: Metadata = { title: "New school" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function NewSchoolPage() {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <NewSchool />
    </Suspense>
  );
}

async function NewSchool() {
  await requirePlatformAdmin();
  const { locale, t } = await getMessages();
  const o = t.platform.onboarding;
  return (
    <>
      <BackLink href="/platform/schools">{t.platform.school.back}</BackLink>
      <PageHeader title={o.title} />
      <NewSchoolForm action={createSchool} text={o} locale={locale} timeZones={timeZones()} />
    </>
  );
}
