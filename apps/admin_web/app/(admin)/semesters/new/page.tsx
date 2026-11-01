import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { SemesterForm } from "@/components/SemesterForm";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { isSemesterFormErrorKey, todayIso } from "@/lib/semesters";

import { createSemester } from "../actions";

export const metadata: Metadata = { title: "Add a semester" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ error?: string | string[] }>;

export default function NewSemesterPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <NewSemester searchParams={searchParams} />
    </Suspense>
  );
}

async function NewSemester({ searchParams }: { searchParams: SearchParams }) {
  await requireAdmin();
  const { t } = await getMessages();

  const { error } = await searchParams;
  const errorParam = Array.isArray(error) ? error[0] : error;
  const errorKey = isSemesterFormErrorKey(errorParam) ? errorParam : null;

  return (
    <>
      <p>
        <Link href="/semesters">{t.semesters.form.back}</Link>
      </p>
      <header className="page-head">
        <h1>{t.semesters.form.newTitle}</h1>
      </header>
      {errorKey ? (
        <p className="notice" role="alert">
          {t.semesters.errors[errorKey]}
        </p>
      ) : null}
      <SemesterForm action={createSemester} t={t} defaultYear={Number(todayIso().slice(0, 4))} />
    </>
  );
}
