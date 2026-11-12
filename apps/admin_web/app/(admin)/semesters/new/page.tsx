import type { Metadata } from "next";
import { Suspense } from "react";
import { BackLink } from "@/components/ui/BackLink";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";

import { SemesterForm } from "@/components/SemesterForm";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { isSemesterFormErrorKey } from "@/lib/semesters";
import { todayInZone } from "@/lib/zoned";

import { createSemester } from "../actions";

export const metadata: Metadata = { title: "Add a semester" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[] }>;

export default function NewSemesterPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={2} />}>
      <NewSemester searchParams={searchParams} />
    </Suspense>
  );
}

async function NewSemester({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();

  const { error } = await searchParams;
  const errorParam = Array.isArray(error) ? error[0] : error;
  const errorKey = isSemesterFormErrorKey(errorParam) ? errorParam : null;
  const today = todayInZone(admin.schoolTimezone);

  return (
    <>
      <BackLink href="/semesters">{t.semesters.form.back}</BackLink>
      <PageHeader title={t.semesters.form.newTitle} />

      {errorKey ? <Notice tone="bad">{t.semesters.errors[errorKey]}</Notice> : null}

      <SemesterForm action={createSemester} t={t} locale={locale} defaultYear={Number(today.slice(0, 4))} today={today} />
    </>
  );
}
