import { Suspense } from "react";

import { StudentPage } from "@/components/student/StudentPage";
import { Notice } from "@/components/ui/Notice";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";

export const instant = false;

export default function Page() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Content />
    </Suspense>
  );
}

// Filled in by the next steps of the web app (ADR 0021).
async function Content() {
  await requireStudent();
  const { locale, s } = await getStudentCopy();
  return (
    <StudentPage lang={locale} title={s.nav.subscription}>
      <Notice tone="info">{s.soon.body}</Notice>
    </StudentPage>
  );
}
