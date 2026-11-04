import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { ArrowLeft01Icon, ArrowRight01Icon } from "@hugeicons/core-free-icons";

import { Avatar } from "@/components/ui/Avatar";
import { ButtonLink } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { PageHeader } from "@/components/ui/PageHeader";
import { Tabs, type TabItem } from "@/components/ui/Tabs";
import { StickyToolbar } from "@/components/ui/StickyToolbar";
import { requireAdmin } from "@/lib/auth";
import { format, type Locale } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { createClient } from "@/lib/supabase/server";
import {
  FILTERS,
  PAGE_SIZE,
  STATUSES,
  pageRange,
  parsePage,
  parseStatusFilter,
  statusTone,
  tabCounts,
  type StatusFilter,
} from "@/lib/subscriptions";

export const metadata: Metadata = { title: "Subscriptions" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ status?: string | string[]; page?: string | string[] }>;

export default function SubscriptionsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <SubscriptionsList searchParams={searchParams} />
    </Suspense>
  );
}

function href(status: StatusFilter, page = 1): string {
  const params = new URLSearchParams();
  if (status !== "pending") params.set("status", status);
  if (page > 1) params.set("page", String(page));
  const query = params.toString();
  return query ? `/subscriptions?${query}` : "/subscriptions";
}

function formatDateTime(value: string, locale: Locale, timeZone: string): string {
  return new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date(value));
}

async function SubscriptionsList({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const query = await searchParams;
  const status = parseStatusFilter(query.status);
  const page = parsePage(query.page);
  const { from, to } = pageRange(page);

  const supabase = await createClient();

  let request = supabase
    .from("subscriptions")
    .select(
      `id, status, created_at,
       student:profiles!subscriptions_student_id_school_id_fkey(full_name, email, matricule),
       semester:semesters!subscriptions_semester_id_school_id_fkey(name, year),
       stop:stops!subscriptions_stop_id_school_id_fkey(name)`,
      { count: "exact" },
    )
    // The review queue is worked oldest first; every other view shows the newest first.
    .order("created_at", { ascending: status === "pending" })
    .range(from, to);
  if (status !== "all") request = request.eq("status", status);

  // Counts only, no rows: one per status for the numbers on the tabs. Row Level Security limits each to this school.
  const [listed, ...counted] = await Promise.all([
    request,
    ...STATUSES.map((s) => supabase.from("subscriptions").select("id", { count: "exact", head: true }).eq("status", s)),
  ]);

  // A page past the last one is not a failure: the database answers "range not satisfiable" and there is simply nothing there.
  const outOfRange = listed.error?.code === "PGRST103";
  const { data, count } = listed;
  const error = outOfRange ? null : listed.error;
  const total = count ?? 0;
  const rows = data ?? [];
  const lastPage = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const counts = tabCounts(Object.fromEntries(STATUSES.map((s, index) => [s, counted[index].count])));

  const tabs: TabItem[] = FILTERS.map((filter) => ({
    id: filter,
    label: t.subscriptions.filters[filter],
    href: href(filter),
    count: counts[filter],
    tone: filter === "all" ? "neutral" : statusTone(filter),
  }));

  return (
    <>
      <PageHeader
        title={t.subscriptions.title}
        subtitle={t.subscriptions.subtitle}
        help={{
          label: t.help.open,
          title: t.subscriptions.help.title,
          intro: t.subscriptions.help.intro,
          scenarios: Object.values(t.subscriptions.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
      />

      <StickyToolbar>
        <Tabs label={t.subscriptions.filtersLabel} items={tabs} active={status} />
      </StickyToolbar>

      {error ? (
        <p className="rounded-md bg-bad-bg px-5 py-4 text-sm text-bad" role="alert">
          {t.subscriptions.loadError}
        </p>
      ) : rows.length === 0 ? (
        <EmptyState
          className="mt-2"
          illustration={status === "pending" ? "/illustrations/verified.webp" : "/illustrations/papers.webp"}
          title={status === "pending" ? t.subscriptions.emptyPending : t.subscriptions.emptyOther}
          body={status === "pending" ? t.subscriptions.emptyPendingHint : t.subscriptions.emptyOtherHint}
        />
      ) : (
        <>
          <div className="overflow-x-auto rounded-lg bg-surface shadow-soft">
            <table className="w-full min-w-[40rem] border-collapse text-left text-sm">
              <thead>
                <tr className="text-xs tracking-wide text-muted uppercase">
                  <th scope="col" className="px-5 py-4 font-semibold">
                    {t.subscriptions.columns.student}
                  </th>
                  <th scope="col" className="px-5 py-4 font-semibold">
                    {t.subscriptions.columns.semester}
                  </th>
                  <th scope="col" className="px-5 py-4 font-semibold">
                    {t.subscriptions.columns.stop}
                  </th>
                  <th scope="col" className="px-5 py-4 font-semibold">
                    {t.subscriptions.columns.submitted}
                  </th>
                  <th scope="col" className="px-5 py-4 font-semibold">
                    {t.subscriptions.columns.status}
                  </th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => {
                  const name = row.student?.full_name || row.student?.email || "";
                  return (
                    <tr key={row.id} className="border-t border-line transition-colors duration-(--dur-fast) hover:bg-surface-2">
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-3">
                          <Avatar name={name} url={null} size={40} />
                          <div className="min-w-0">
                            <Link href={`/subscriptions/${row.id}`} className="font-semibold text-fg no-underline hover:text-link">
                              {name}
                            </Link>
                            {row.student?.matricule ? <p className="text-xs text-muted">{row.student.matricule}</p> : null}
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-3.5">{row.semester ? `${t.semester[row.semester.name]} ${row.semester.year}` : ""}</td>
                      <td className="px-5 py-3.5">{row.stop?.name}</td>
                      <td className="px-5 py-3.5 text-muted">{formatDateTime(row.created_at, locale, admin.schoolTimezone)}</td>
                      <td className="px-5 py-3.5">
                        <Chip tone={statusTone(row.status)}>{t.status[row.status]}</Chip>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          <div className="flex flex-wrap items-center justify-between gap-3">
            <p className="text-sm text-muted">{format(t.subscriptions.range, { from: from + 1, to: from + rows.length, total })}</p>
            <nav className="flex gap-2" aria-label={t.subscriptions.paginationLabel}>
              {page > 1 ? (
                <ButtonLink variant="secondary" icon={ArrowLeft01Icon} href={href(status, page - 1)}>
                  {t.subscriptions.previous}
                </ButtonLink>
              ) : null}
              {page < lastPage ? (
                <ButtonLink variant="secondary" icon={ArrowRight01Icon} href={href(status, page + 1)}>
                  {t.subscriptions.next}
                </ButtonLink>
              ) : null}
            </nav>
          </div>
        </>
      )}
    </>
  );
}
