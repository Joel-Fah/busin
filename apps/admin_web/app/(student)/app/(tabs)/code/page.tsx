import { SquareLock02Icon } from "@hugeicons/core-free-icons";
import type { Metadata } from "next";
import Image from "next/image";
import { Suspense } from "react";

import { BoardingCode } from "@/components/student/BoardingCode";
import { StudentPage } from "@/components/student/StudentPage";
import { Icon } from "@/components/ui/Icon";
import { Skeleton } from "@/components/ui/Skeleton";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";
import { todayInZone } from "@/lib/zoned";

export const metadata: Metadata = { title: "Boarding code" };
export const instant = false;

export default function CodePage() {
  return (
    <Suspense
      fallback={
        <main className="mx-auto flex w-full max-w-[640px] flex-col gap-4 px-4 pt-6" aria-busy="true">
          <Skeleton className="h-[30rem] rounded-xl" />
        </main>
      }
    >
      <Code />
    </Suspense>
  );
}

/**
 * The boarding code tab, as in the app: the ticket with the live code, a reminder to keep it private, and how to board.
 * Whether a code can be shown is the server's answer (an approved subscription for a semester running today, at the
 * school); the code itself is made in the browser.
 */
async function Code() {
  const student = await requireStudent();
  const { locale, s } = await getStudentCopy();
  const c = s.code;
  const supabase = await createClient();
  const today = todayInZone(student.schoolTimezone);
  const { data: semester } = await supabase.from("semesters").select("id, end_date").lte("start_date", today).gte("end_date", today).order("start_date", { ascending: false }).limit(1).maybeSingle();
  const approved = semester
    ? Boolean((await supabase.from("subscriptions").select("id").eq("student_id", student.userId).eq("semester_id", semester.id).eq("status", "approved").limit(1).maybeSingle()).data)
    : false;

  return (
    <StudentPage lang={locale} title={c.title} subtitle={c.hint}>
      <BoardingCode copy={c} studentId={student.userId} name={student.fullName} matricule={student.matricule} timeZone={student.schoolTimezone} approved={approved} validUntil={semester?.end_date ?? null} />
      {approved ? (
        <>
          <p className="m-0 flex items-start gap-3 rounded-md bg-surface-2 p-4 text-sm">
            <Icon icon={SquareLock02Icon} size={20} className="shrink-0" />
            <span>
              <strong className="block">{c.privateTitle}</strong>
              <span className="text-muted">{c.privateBody}</span>
            </span>
          </p>
          <section aria-labelledby="board-title" className="flex flex-col gap-4 rounded-lg bg-surface p-5 shadow-soft">
            <div className="flex items-center justify-between gap-3">
              <h2 id="board-title" className="m-0 text-lg font-bold">
                {c.boardTitle}
              </h2>
              <Image src="/illustrations/seat.webp" alt="" width={64} height={64} className="size-16 object-contain" />
            </div>
            <ol className="m-0 flex list-none flex-col gap-3 p-0">
              {c.steps.map((step, index) => (
                <li key={step} className="flex items-start gap-3">
                  <span className="grid size-7 shrink-0 place-items-center rounded-xs bg-accent text-sm font-bold text-on-accent">{index + 1}</span>
                  <span className="pt-0.5">{step}</span>
                </li>
              ))}
            </ol>
          </section>
        </>
      ) : null}
    </StudentPage>
  );
}
