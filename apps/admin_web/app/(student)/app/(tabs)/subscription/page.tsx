import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { Banner } from "@/components/student/Banner";
import { LiveSubscriptions } from "@/components/student/LiveSubscriptions";
import { PushOptIn } from "@/components/student/PushOptIn";
import { RequestHistory } from "@/components/student/RequestHistory";
import { StatusCard } from "@/components/student/StatusCard";
import { SubscribeForm } from "@/components/student/SubscribeForm";
import { EmptyState } from "@/components/ui/EmptyState";
import { Skeleton } from "@/components/ui/Skeleton";
import { format } from "@/lib/i18n/format";
import { getStudentCopy } from "@/lib/i18n/server";
import { firstName, greetingFor } from "@/lib/overview";
import { requireStudent } from "@/lib/student/session";
import { buildRequestHistory, isLive, subscriptionToShow, type SubscriptionEvent, type SubscriptionRow } from "@/lib/student/subscription";
import { createClient } from "@/lib/supabase/server";
import { todayInZone } from "@/lib/zoned";

export const metadata: Metadata = { title: "Subscription" };
export const instant = false;

type SearchParams = Promise<{ again?: string | string[] }>;

function Loading() {
  return (
    <main className="mx-auto flex w-full max-w-[640px] flex-col gap-4 px-4 pt-6" aria-busy="true">
      <Skeleton className="h-44 rounded-xl" />
      <Skeleton className="h-72 rounded-lg" />
    </main>
  );
}

export default function SubscriptionPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<Loading />}>
      <Subscription searchParams={searchParams} />
    </Suspense>
  );
}

const SEMESTER_COLUMNS = "id, name, year, start_date, end_date";
const SUBSCRIPTION_COLUMNS = "id, semester_id, stop_id, status, proof_path, review_note, created_at";

/**
 * The first tab, as in the app: a banner that greets the student and names the semester (the current one, else the next),
 * then the request form, or where the request stands and everything that happened to this semester's requests.
 */
async function Subscription({ searchParams }: { searchParams: SearchParams }) {
  const student = await requireStudent();
  const { locale, s } = await getStudentCopy();
  const c = s.subscription;
  const supabase = await createClient();
  const now = new Date();
  const today = todayInZone(student.schoolTimezone, now);

  const [current, mine] = await Promise.all([
    supabase.from("semesters").select(SEMESTER_COLUMNS).lte("start_date", today).gte("end_date", today).order("start_date", { ascending: false }).limit(1).maybeSingle(),
    supabase.from("subscriptions").select(SUBSCRIPTION_COLUMNS).eq("student_id", student.userId).order("created_at", { ascending: false }).limit(20),
  ]);
  let semester = current.data;
  let upcoming = false;
  if (!semester && !current.error) {
    const next = await supabase.from("semesters").select(SEMESTER_COLUMNS).gt("start_date", today).order("start_date", { ascending: true }).limit(1).maybeSingle();
    semester = next.data;
    upcoming = semester !== null;
  }

  const hour = Number(new Intl.DateTimeFormat("en-GB", { hour: "2-digit", hourCycle: "h23", timeZone: student.schoolTimezone }).format(now));
  const who = firstName(student.fullName);
  const greeting = who ? `${s.greet[greetingFor(hour)]}, ${who}` : s.greet[greetingFor(hour)];
  const longDate = new Intl.DateTimeFormat(locale, { dateStyle: "full", timeZone: student.schoolTimezone }).format(now);
  const dateOf = (iso: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: student.schoolTimezone }).format(new Date(iso));
  const dayOf = (day: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: "UTC" }).format(new Date(`${day}T00:00:00Z`));
  const timeOf = (iso: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone: student.schoolTimezone }).format(new Date(iso));

  if (current.error || mine.error) {
    return (
      <main lang={locale} className="mx-auto flex w-full max-w-[640px] flex-col gap-4 px-4 pt-6 pb-36">
        <EmptyState title={c.loadError} action={<Link href="/app/subscription">{c.retry}</Link>} />
      </main>
    );
  }

  if (!semester) {
    return (
      <main lang={locale} className="student-in mx-auto flex w-full max-w-[640px] flex-col gap-5 px-4 pt-[max(1.5rem,env(safe-area-inset-top))] pb-36 sm:px-6">
        <Banner eyebrow={longDate} title={greeting} lines={[]} art="semester" />
        <EmptyState title={c.noSemesterTitle} body={c.noSemesterBody} />
      </main>
    );
  }

  const rows = (mine.data ?? []) as SubscriptionRow[];
  const subscription = subscriptionToShow(rows, semester.id);
  const { again } = await searchParams;
  const showForm = !subscription || (again === "1" && !isLive(subscription.status));
  const ofSemester = rows.filter((r) => r.semester_id === semester.id);

  const [stop, events, proof, stops] = await Promise.all([
    subscription && !showForm ? supabase.from("stops").select("name").eq("id", subscription.stop_id).maybeSingle() : null,
    ofSemester.length ? supabase.from("subscription_events").select("id, subscription_id, action, note, created_at").in("subscription_id", ofSemester.map((r) => r.id)).order("created_at").limit(200) : null,
    subscription?.proof_path && !showForm ? supabase.storage.from("proofs").createSignedUrl(subscription.proof_path, 600) : null,
    showForm ? supabase.from("stops").select("id, name").eq("active", true).order("name").limit(500) : null,
  ]);

  const semesterName = `${s.semesters[semester.name as keyof typeof s.semesters] ?? semester.name} ${semester.year}`;
  const art = showForm ? "ticket1" : { approved: "verified", pending: "waiting", rejected: "papers", revoked: "papers", expired: "semester" }[subscription!.status];
  const lines = [showForm ? format(c.heading, { semester: semesterName }) : semesterName, ...(upcoming ? [format(c.starts, { date: dayOf(semester.start_date) })] : [])];
  const history = buildRequestHistory(ofSemester, (events?.data ?? []) as SubscriptionEvent[]);
  const known = Object.fromEntries(rows.map((r) => [r.id, r.status]));

  return (
    <main lang={locale} className="student-in mx-auto flex w-full max-w-[640px] flex-col gap-5 px-4 pt-[max(1.5rem,env(safe-area-inset-top))] pb-36 sm:px-6">
      <LiveSubscriptions studentId={student.userId} known={known} copy={c.live} />
      <Banner eyebrow={longDate} title={greeting} lines={lines} art={art} />
      {showForm ? (
        <SubscribeForm copy={c} semesterId={semester.id} schoolId={student.schoolId} studentId={student.userId} stops={stops?.data ?? []} />
      ) : (
        <StatusCard
          copy={c}
          subscription={subscription!}
          stopName={stop?.data?.name ?? ""}
          sentOn={dateOf(subscription!.created_at)}
          proofUrl={proof?.data?.signedUrl ?? null}
          requestAgainHref={isLive(subscription!.status) ? null : "/app/subscription?again=1"}
        />
      )}
      {/* Offered once to everyone, in any browser (on an iPhone it explains the Home Screen step); "Not now" is remembered. */}
      <PushOptIn copy={s.push} locale={locale} compact />
      <RequestHistory copy={c} history={history} dateOf={dateOf} timeOf={timeOf} />
    </main>
  );
}
