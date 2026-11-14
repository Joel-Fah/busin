import type { Metadata } from "next";
import { Suspense } from "react";

import { AreaPicker } from "@/components/student/AreaPicker";
import { StudentPage } from "@/components/student/StudentPage";
import { ButtonLink } from "@/components/ui/Button";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "My area" };
export const instant = false;

type Props = { searchParams: Promise<{ intro?: string }> };

export default function AreaPage({ searchParams }: Props) {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Area searchParams={searchParams} />
    </Suspense>
  );
}

/** My area. With `?intro=1` it is the one-time invitation right after setup (ADR 0023): "Not now" goes on to the app. */
async function Area({ searchParams }: Props) {
  await requireStudent();
  const { locale, s } = await getStudentCopy();
  const intro = (await searchParams).intro === "1";
  const supabase = await createClient();
  const { data } = await supabase.rpc("my_area");
  return (
    <StudentPage lang={locale} title={intro ? s.area.introTitle : s.area.title} subtitle={s.area.intro}>
      <AreaPicker copy={s.area} current={data?.[0]?.label ?? null} next={intro ? "/app/subscription" : null} />
      {intro ? (
        <ButtonLink variant="ghost" href="/app/subscription" className="self-center">
          {s.area.notNow}
        </ButtonLink>
      ) : null}
    </StudentPage>
  );
}
