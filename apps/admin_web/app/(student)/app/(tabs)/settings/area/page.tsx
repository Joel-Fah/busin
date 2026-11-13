import type { Metadata } from "next";
import { Suspense } from "react";

import { AreaPicker } from "@/components/student/AreaPicker";
import { StudentPage } from "@/components/student/StudentPage";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "My area" };
export const instant = false;

export default function AreaPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Area />
    </Suspense>
  );
}

async function Area() {
  await requireStudent();
  const { locale, s } = await getStudentCopy();
  const supabase = await createClient();
  const { data } = await supabase.rpc("my_area");
  return (
    <StudentPage lang={locale} title={s.area.title} subtitle={s.area.intro}>
      <AreaPicker copy={s.area} current={data?.[0]?.label ?? null} />
    </StudentPage>
  );
}
