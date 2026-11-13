import { Suspense } from "react";

import { OfflineBanner } from "@/components/student/OfflineBanner";
import { SessionOwner } from "@/components/student/SessionOwner";
import { TabBar } from "@/components/student/TabBar";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";

// Everything here depends on who is signed in.
export const instant = false;

export default function TabsLayout({ children }: { children: React.ReactNode }) {
  return (
    <Suspense fallback={<main className="min-h-dvh bg-bg" aria-busy="true" />}>
      <Tabs>{children}</Tabs>
    </Suspense>
  );
}

/** The four tabs of a verified student with their details in. Anyone else is sent to their gate first. */
async function Tabs({ children }: { children: React.ReactNode }) {
  const student = await requireStudent();
  const { s } = await getStudentCopy();
  return (
    <>
      <SessionOwner userId={student.userId} />
      <OfflineBanner text={s.offline.banner} />
      {children}
      <TabBar copy={s.nav} />
    </>
  );
}
