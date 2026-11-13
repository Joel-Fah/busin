import type { Metadata } from "next";
import Image from "next/image";
import { Suspense } from "react";

import { StudentPage } from "@/components/student/StudentPage";
import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { format } from "@/lib/i18n/format";
import { getStudentCopy } from "@/lib/i18n/server";
import { firstName } from "@/lib/overview";
import { requireStudent } from "@/lib/student/session";
import { setStreaks } from "@/lib/student/settings";
import { createClient } from "@/lib/supabase/server";
import { todayInZone } from "@/lib/zoned";
import { Contour } from "@/components/ui/Contour";

export const metadata: Metadata = { title: "Streaks" };
export const instant = false;

export default function StreaksPage() {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <Streaks />
    </Suspense>
  );
}

/**
 * Streaks, as in the app: off until the student turns them on (it also puts them on the school's leaderboard, under their
 * first name); then the current and best streak, the rides of the semester, and the leaderboard.
 */
async function Streaks() {
  const student = await requireStudent();
  const { locale, s } = await getStudentCopy();
  const k = s.streaks;
  const supabase = await createClient();
  const today = todayInZone(student.schoolTimezone);
  const [own, semester] = await Promise.all([
    supabase.from("profiles").select("streak_opt_in").eq("id", student.userId).maybeSingle(),
    supabase.from("semesters").select("id").lte("start_date", today).gte("end_date", today).order("start_date", { ascending: false }).limit(1).maybeSingle(),
  ]);
  const on = own.data?.streak_opt_in === true;
  const semesterId = semester.data?.id;
  const [mine, board] = on && semesterId ? await Promise.all([supabase.rpc("my_streak", { p_semester_id: semesterId }), supabase.rpc("school_leaderboard", { p_semester_id: semesterId, p_limit: 50 })]) : [null, null];
  const streak = mine?.data?.[0];
  const days = (n: number) => (n === 0 ? k.days.zero : n === 1 ? k.days.one : format(k.days.other, { count: n }));
  const rides = (n: number) => (n === 1 ? k.rides.one : format(k.rides.other, { count: n }));

  return (
    <StudentPage lang={locale} title={k.title} subtitle={k.hint}>
      {!on ? (
        <section className="flex flex-col gap-4 relative rounded-lg bg-surface p-5 shadow-soft">
          <Contour radius={28} inset={10} />
          <Image src="/illustrations/bus.webp" alt="" width={96} height={96} className="size-24 object-contain" />
          <h2 className="m-0 text-xl font-bold">{k.onTitle}</h2>
          <p className="m-0 text-muted">{format(k.onBody, { name: firstName(student.fullName) || student.fullName })}</p>
          <form action={setStreaks}>
            <input type="hidden" name="on" value="true" />
            <Button type="submit" className="w-full">
              {k.turnOn}
            </Button>
          </form>
        </section>
      ) : (
        <>
          <section className="texture-grain flex flex-col gap-1 rounded-xl bg-seed p-6 text-white shadow-soft [--grain:0.8]" data-testid="streak-card">
            {semesterId ? (
              <>
                <p className="m-0 text-3xl font-extrabold">{days(streak?.current_streak ?? 0)}</p>
                <p className="m-0 text-white/80">
                  {format(k.best, { count: streak?.best_streak ?? 0 })} · {rides(streak?.rides ?? 0)}
                </p>
              </>
            ) : (
              <p className="m-0">{k.noSemester}</p>
            )}
          </section>
          {semesterId ? (
            <section aria-labelledby="board-title" className="flex flex-col gap-3 relative rounded-lg bg-surface p-5 shadow-soft">
              <Contour radius={28} inset={10} />
              <div>
                <h2 id="board-title" className="m-0 text-lg font-bold">
                  {k.board}
                </h2>
                <p className="m-0 text-sm text-muted">{k.boardNote}</p>
              </div>
              {(board?.data ?? []).length === 0 ? (
                <p className="m-0 text-sm text-muted">{k.boardEmpty}</p>
              ) : (
                <ol className="m-0 flex list-none flex-col gap-1 p-0">
                  {(board?.data ?? []).map((row) => (
                    <li key={`${row.rank}-${row.display_name}`} className={`flex items-center gap-3 rounded-sm px-2 py-2 ${row.is_me ? "bg-surface-2" : ""}`} aria-label={format(k.rank, { rank: row.rank })}>
                      <span className="w-7 text-right font-bold tabular-nums">{row.rank}</span>
                      <Avatar name={row.display_name} url={row.avatar_url} size={32} />
                      <span className="min-w-0 flex-1 truncate font-semibold">{row.is_me ? `${row.display_name} (${k.you})` : row.display_name}</span>
                      <span className="text-sm text-muted tabular-nums">{days(row.current_streak)}</span>
                    </li>
                  ))}
                </ol>
              )}
            </section>
          ) : null}
          <form action={setStreaks}>
            <input type="hidden" name="on" value="false" />
            <Button type="submit" variant="ghost" className="w-full">
              {k.turnOff}
            </Button>
          </form>
        </>
      )}
    </StudentPage>
  );
}
