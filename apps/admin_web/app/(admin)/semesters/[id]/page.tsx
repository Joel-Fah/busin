import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { SemesterForm } from "@/components/SemesterForm";
import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { isSemesterDone, isSemesterFormErrorKey, isSemesterName } from "@/lib/semesters";
import { createClient } from "@/lib/supabase/server";

import { updateSemester } from "../actions";

export const metadata: Metadata = { title: "Semester" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

export default function SemesterPage({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <SemesterDetail params={params} searchParams={searchParams} />
    </Suspense>
  );
}

function single(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

async function SemesterDetail({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  await requireAdmin();
  const { t } = await getMessages();
  const { id } = await params;
  if (!isUuid(id)) notFound();

  const supabase = await createClient();
  const { data: semester } = await supabase
    .from("semesters")
    .select("id, name, year, start_date, end_date")
    .eq("id", id)
    .maybeSingle();
  if (!semester || !isSemesterName(semester.name)) notFound();

  const query = await searchParams;
  const doneParam = single(query.done);
  const errorParam = single(query.error);
  const done = isSemesterDone(doneParam) ? doneParam : null;
  const errorKey = isSemesterFormErrorKey(errorParam) ? errorParam : null;

  return (
    <>
      <p>
        <Link href="/semesters">{t.semesters.form.back}</Link>
      </p>
      <header className="page-head">
        <h1>
          {t.semester[semester.name]} {semester.year}
        </h1>
      </header>
      {done ? (
        <p className="success" role="status">
          {t.semesters.done[done]}
        </p>
      ) : null}
      {errorKey ? (
        <p className="notice" role="alert">
          {t.semesters.errors[errorKey]}
        </p>
      ) : null}
      <SemesterForm
        action={updateSemester}
        t={t}
        defaultYear={semester.year}
        semester={{
          id: semester.id,
          name: semester.name,
          year: semester.year,
          startDate: semester.start_date,
          endDate: semester.end_date,
        }}
      />
    </>
  );
}
