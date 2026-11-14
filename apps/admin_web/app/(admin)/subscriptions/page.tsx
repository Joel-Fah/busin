import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { Avatar } from "@/components/ui/Avatar";
import { Chip } from "@/components/ui/Chip";
import { ColumnFilter } from "@/components/ui/ColumnFilter";
import { EmptyState } from "@/components/ui/EmptyState";
import { FilterChips, type FilterChip } from "@/components/ui/FilterChips";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Pager } from "@/components/ui/Pager";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";
import { Tabs, type TabItem } from "@/components/ui/Tabs";
import { StickyToolbar } from "@/components/ui/StickyToolbar";
import { requireAdmin } from "@/lib/auth";
import { partsAttention } from "@/lib/billing";
import { chipText, filterText } from "@/lib/filter-text";
import { format, type Locale } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { PAGE_SIZES, lastPage } from "@/lib/pagination";
import { createClient } from "@/lib/supabase/server";
import {
  FILTERS,
  PAGE_SIZE,
  STATUSES,
  pageRange,
  parsePage,
  parseSubscriptionFilters,
  statusTone,
  subscriptionsHref,
  tabCounts,
  type SubscriptionFilters,
} from "@/lib/subscriptions";

export const metadata: Metadata = { title: "Subscriptions" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{
  status?: string | string[];
  semester?: string | string[];
  stop?: string | string[];
  page?: string | string[];
}>;

export default function SubscriptionsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <SubscriptionsList searchParams={searchParams} />
    </Suspense>
  );
}

function formatDateTime(value: string, locale: Locale, timeZone: string): string {
  return new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date(value));
}

async function SubscriptionsList({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const query = await searchParams;
  const filters = parseSubscriptionFilters(query);
  const status = filters.status;
  const page = parsePage(query.page);
  const size = filters.size ?? PAGE_SIZE;
  const { from, to } = pageRange(page, size);

  const supabase = await createClient();
  const todayIso = new Intl.DateTimeFormat("en-CA", { timeZone: admin.schoolTimezone }).format(new Date());

  // The same column filters narrow the list and the counts on the tabs, so a tab's number is what it would show. "Payments"
  // keeps the subscriptions with a later part waiting for a check or late (ADR 0022), through the parts joined below.
  const narrow = <Q extends { eq(column: string, value: string): Q; gt(column: string, value: number): Q; or(filters: string, options: { referencedTable: string }): Q }>(q: Q): Q => {
    let next = q;
    if (filters.semester) next = next.eq("semester_id", filters.semester);
    if (filters.stop) next = next.eq("stop_id", filters.stop);
    if (filters.payments) next = next.gt("parts.seq", 1).or(`status.eq.submitted,and(status.in.(due,rejected),due_date.lte.${todayIso})`, { referencedTable: "parts" });
    return next;
  };
  const parts = filters.payments ? "parts:subscription_installments!inner(seq, status, due_date)" : "parts:subscription_installments(seq, status, due_date)";

  let request = narrow(
    supabase
      .from("subscriptions")
      .select(
        `id, status, created_at, period_start, ${parts},
         student:profiles!subscriptions_student_id_school_id_fkey(full_name, email, matricule),
         semester:semesters!subscriptions_semester_id_school_id_fkey(name, year),
         stop:stops!subscriptions_stop_id_school_id_fkey(name)`,
        { count: "exact" },
      )
      // The review queue is worked oldest first; every other view shows the newest first.
      .order("created_at", { ascending: status === "pending" })
      .range(from, to),
  );
  if (status !== "all") request = request.eq("status", status);

  // Counts only, no rows: one per status for the numbers on the tabs. Row Level Security limits each to this school.
  const [listed, semesterOptions, stopOptions, ...counted] = await Promise.all([
    request,
    supabase.from("semesters").select("id, name, year").order("start_date", { ascending: false }).limit(100),
    supabase.from("stops").select("id, name").order("name", { ascending: true }).limit(500),
    ...STATUSES.map((s) => narrow(supabase.from("subscriptions").select(filters.payments ? `id, ${parts}` : "id", { count: "exact", head: true }).eq("status", s))),
  ]);

  // A page past the last one is not a failure: the database answers "range not satisfiable" and there is simply nothing there.
  const outOfRange = listed.error?.code === "PGRST103";
  const { data, count } = listed;
  const error = outOfRange ? null : listed.error;
  const total = count ?? 0;
  const rows = data ?? [];
  const counts = tabCounts(Object.fromEntries(STATUSES.map((s, index) => [s, counted[index].count])));

  const tabs: TabItem[] = FILTERS.map((filter) => ({
    id: filter,
    label: t.subscriptions.filters[filter],
    href: subscriptionsHref({ ...filters, status: filter }),
    count: counts[filter],
    tone: filter === "all" ? "neutral" : statusTone(filter),
  }));

  const text = filterText(t);
  const cf = t.columnFilter;
  const without = (change: Partial<SubscriptionFilters>) => subscriptionsHref({ ...filters, ...change });
  const semesters = (semesterOptions.data ?? []).map((semester) => ({
    id: semester.id,
    label: `${t.semester[semester.name]} ${semester.year}`,
  }));
  const stops = stopOptions.data ?? [];
  const chips: FilterChip[] = [
    ...(filters.semester
      ? [{ label: t.subscriptions.columns.semester, value: semesters.find((s) => s.id === filters.semester)?.label ?? "-", href: without({ semester: null }) }]
      : []),
    ...(filters.stop
      ? [{ label: t.subscriptions.columns.stop, value: stops.find((s) => s.id === filters.stop)?.name ?? "-", href: without({ stop: null }) }]
      : []),
    ...(filters.payments ? [{ label: t.subscriptions.payments, value: t.subscriptions.paymentsOn, href: without({ payments: false }) }] : []),
  ];
  const monthOf = (day: string) => new Intl.DateTimeFormat(locale, { month: "long", year: "numeric", timeZone: "UTC" }).format(new Date(`${day}T00:00:00Z`));
  const anyFilter = chips.length > 0;

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

      <FilterChips chips={chips} clearAllHref={without({ semester: null, stop: null, payments: false })} {...chipText(t)} />

      {error ? (
        <Notice tone="bad">{t.subscriptions.loadError}</Notice>
      ) : rows.length === 0 ? (
        <EmptyState
          className="mt-2"
          illustration={status === "pending" ? "/illustrations/verified.webp" : "/illustrations/papers.webp"}
          title={status === "pending" && !anyFilter ? t.subscriptions.emptyPending : t.subscriptions.emptyOther}
          body={anyFilter ? t.subscriptions.emptyFiltered : status === "pending" ? t.subscriptions.emptyPendingHint : t.subscriptions.emptyOtherHint}
        />
      ) : (
        <>
          <TableCard>
            <DataTable minWidth="40rem">
              <Head>
                <Th>{t.subscriptions.columns.student}</Th>
                <Th>
                  <ColumnFilter
                    label={t.subscriptions.columns.semester}
                    value={filters.semester}
                    clearHref={without({ semester: null })}
                    allLabel={cf.allSemesters}
                    options={semesters.map((semester) => ({ value: semester.id, label: semester.label, href: without({ semester: semester.id }) }))}
                    {...text}
                  />
                </Th>
                <Th>
                  <ColumnFilter
                    label={t.subscriptions.columns.stop}
                    value={filters.stop}
                    clearHref={without({ stop: null })}
                    allLabel={cf.allStops}
                    options={stops.map((stop) => ({ value: stop.id, label: stop.name, href: without({ stop: stop.id }) }))}
                    {...text}
                  />
                </Th>
                <Th>{t.subscriptions.columns.submitted}</Th>
                <Th>{t.subscriptions.columns.status}</Th>
              </Head>
              <tbody>
                {rows.map((row) => {
                  const name = row.student?.full_name || row.student?.email || "";
                  const attention = partsAttention(row.parts ?? [], todayIso);
                  return (
                    <Tr key={row.id}>
                      <Td>
                        <div className="flex items-center gap-3">
                          <Avatar name={name} url={null} size={40} />
                          <div className="min-w-0">
                            <Link href={`/subscriptions/${row.id}`} className="font-semibold text-fg no-underline hover:text-link">
                              {name}
                            </Link>
                            {row.student?.matricule ? <p className="text-xs text-muted">{row.student.matricule}</p> : null}
                          </div>
                        </div>
                      </Td>
                      <Td>
                        {row.semester ? `${t.semester[row.semester.name]} ${row.semester.year}` : ""}
                        {row.period_start ? <p className="text-xs text-muted capitalize">{monthOf(row.period_start)}</p> : null}
                      </Td>
                      <Td>{row.stop?.name}</Td>
                      <Td className="text-muted">{formatDateTime(row.created_at, locale, admin.schoolTimezone)}</Td>
                      <Td>
                        <span className="flex flex-wrap gap-1.5">
                          <Chip tone={statusTone(row.status)}>{t.status[row.status]}</Chip>
                          {attention ? (
                            <Chip tone={attention.kind === "overdue" ? "bad" : "warn"}>
                              {format(attention.kind === "overdue" ? t.subscriptions.partOverdue : t.subscriptions.partToCheck, { n: attention.seq })}
                            </Chip>
                          ) : null}
                        </span>
                      </Td>
                    </Tr>
                  );
                })}
              </tbody>
            </DataTable>
          </TableCard>

          <Pager
            range={format(t.subscriptions.range, { from: from + 1, to: from + rows.length, total })}
            label={t.subscriptions.paginationLabel}
            previous={page > 1 ? { href: subscriptionsHref(filters, page - 1), label: t.subscriptions.previous } : undefined}
            next={page < lastPage(total, size) ? { href: subscriptionsHref(filters, page + 1), label: t.subscriptions.next } : undefined}
            perPage={{
              label: t.pager.perPage,
              groupLabel: t.pager.perPageLabel,
              current: size,
              options: PAGE_SIZES.map((n) => ({ size: n, href: subscriptionsHref({ ...filters, size: n }) })),
            }}
          />
        </>
      )}
    </>
  );
}
