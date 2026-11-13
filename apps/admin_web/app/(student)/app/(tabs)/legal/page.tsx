import { Agreement02Icon, LegalDocument01Icon, SquareLock02Icon } from "@hugeicons/core-free-icons";
import type { Metadata } from "next";
import { Suspense } from "react";

import { LinkRow } from "@/components/student/LinkRow";
import { StudentPage } from "@/components/student/StudentPage";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";

export const metadata: Metadata = { title: "Legal" };
export const instant = false;

export default function LegalPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Legal />
    </Suspense>
  );
}

async function Legal() {
  await requireStudent();
  const { locale, s } = await getStudentCopy();
  const l = s.legal;
  return (
    <StudentPage lang={locale} title={l.title}>
      <nav className="flex flex-col gap-2" aria-label={l.title}>
        <LinkRow href="/app/legal/terms" icon={LegalDocument01Icon} title={l.terms} body={l.termsBody} />
        <LinkRow href="/app/legal/privacy" icon={SquareLock02Icon} title={l.privacy} body={l.privacyBody} />
        <LinkRow href="/app/legal/acceptable-use" icon={Agreement02Icon} title={l.acceptable} body={l.acceptableBody} />
      </nav>
    </StudentPage>
  );
}
