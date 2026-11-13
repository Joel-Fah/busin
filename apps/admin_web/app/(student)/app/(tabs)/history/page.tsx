import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { StudentPage } from "@/components/student/StudentPage";
import { EmptyState } from "@/components/ui/EmptyState";
import { format } from "@/lib/i18n/format";
import { getStudentCopy } from "@/lib/i18n/server";
import { requireStudent } from "@/lib/student/session";
import { createClient } from "@/lib/supabase/server";
import { startOfDayInTimeZone } from "@/lib/time";
import { todayInZone } from "@/lib/zoned";
import { Contour } from "@/components/ui/Contour";

export const metadata: Metadata = { title: "History" };
export const instant = false;

const PAGE = 20;
type SearchParams = Promise<{ n?: string | string[] }>;

export default function HistoryPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<main className="min-h-dvh" aria-busy="true" />}>
      <History searchParams={searchParams} />
    </Suspense>
  );
}

/**
 * Every boarding, newest first, grouped by day at the school, as the app's history: 20 at a time, with how many this
 * week. Only the student's own scans (RLS).
 */
async function History({ searchParams }: { searchParams: SearchParams }) {
  const student = await requireStudent();
  const { locale, s } = await getStudentCopy();
  const h = s.history;
  const supabase = await createClient();
  const { n } = await searchParams;
  const pages = Math.min(25, Math.max(1, Number(typeof n === "string" ? n : 1) || 1));
  const zone = student.schoolTimezone;

  // Monday of this week at the school.
  const today = todayInZone(zone);
  const weekday = (new Date(`${today}T12:00:00Z`).getUTCDay() + 6) % 7;
  const monday = startOfDayInTimeZone(zone, new Date(Date.parse(`${today}T12:00:00Z`) - weekday * 86_400_000));

  const [scans, week] = await Promise.all([
    supabase.from("scans").select("id, scanned_at, stop_id, trip_id").eq("student_id", student.userId).order("scanned_at", { ascending: false }).range(0, pages * PAGE),
    supabase.from("scans").select("id", { count: "exact", head: true }).eq("student_id", student.userId).gte("scanned_at", monday.toISOString()),
  ]);
  const rows = (scans.data ?? []).slice(0, pages * PAGE);
  const more = (scans.data ?? []).length > pages * PAGE;
  const stopIds = [...new Set(rows.map((r) => r.stop_id).filter((id): id is string => Boolean(id)))];
  const tripIds = [...new Set(rows.map((r) => r.trip_id))];
  const [stops, trips] = await Promise.all([
    stopIds.length ? supabase.from("stops").select("id, name").in("id", stopIds) : { data: [] as { id: string; name: string }[] },
    tripIds.length ? supabase.from("trips").select("id, direction").in("id", tripIds) : { data: [] as { id: string; direction: "inbound" | "outbound" }[] },
  ]);
  const stopName = new Map((stops.data ?? []).map((stop) => [stop.id, stop.name]));
  const direction = new Map((trips.data ?? []).map((trip) => [trip.id, trip.direction]));

  const dayOf = (iso: string) => new Intl.DateTimeFormat("en-CA", { timeZone: zone }).format(new Date(iso));
  const days = new Map<string, typeof rows>();
  for (const row of rows) days.set(dayOf(row.scanned_at), [...(days.get(dayOf(row.scanned_at)) ?? []), row]);
  const dayTitle = (day: string) => new Intl.DateTimeFormat(locale, { dateStyle: "full", timeZone: "UTC" }).format(new Date(`${day}T12:00:00Z`));
  const timeOf = (iso: string) => new Intl.DateTimeFormat(locale, { timeStyle: "short", timeZone: zone }).format(new Date(iso));
  const count = (k: number) => (k === 1 ? h.count.one : format(h.count.other, { count: k }));

  return (
    <StudentPage lang={locale} title={h.title}>
      <section className="relative rounded-lg bg-surface p-5 shadow-soft">
        <Contour radius={28} inset={10} />
        <p className="m-0 text-sm text-muted">{h.week}</p>
        <p className="m-0 text-4xl font-extrabold tabular-nums">{week.count ?? 0}</p>
      </section>
      {rows.length === 0 ? (
        <EmptyState title={h.emptyTitle} body={h.emptyBody} />
      ) : (
        <ol className="m-0 flex list-none flex-col gap-4 p-0">
          {[...days.entries()].map(([day, list]) => (
            <li key={day} className="flex flex-col gap-2">
              <div className="flex items-baseline justify-between gap-3">
                <h2 className="m-0 text-base font-bold">{dayTitle(day)}</h2>
                <span className="text-sm text-muted">{count(list.length)}</span>
              </div>
              <ul className="m-0 flex list-none flex-col gap-2 p-0">
                {list.map((row) => (
                  <li key={row.id} className="flex items-center gap-4 relative rounded-md bg-surface p-4 shadow-soft">
                    <Contour radius={20} inset={7} />
                    <span className="w-16 shrink-0 font-bold tabular-nums">{timeOf(row.scanned_at)}</span>
                    <span className="min-w-0">
                      <span className="block truncate font-semibold">{row.stop_id ? stopName.get(row.stop_id) ?? h.stopUnknown : h.stopUnknown}</span>
                      {direction.get(row.trip_id) ? <span className="block text-sm text-muted">{s.bus.directions[direction.get(row.trip_id)!]}</span> : null}
                    </span>
                  </li>
                ))}
              </ul>
            </li>
          ))}
        </ol>
      )}
      {more ? (
        <Link href={`/app/history?n=${pages + 1}`} scroll={false} className="inline-flex h-12 items-center justify-center rounded-sm bg-surface-2 font-semibold text-fg no-underline">
          {h.more}
        </Link>
      ) : null}
    </StudentPage>
  );
}
