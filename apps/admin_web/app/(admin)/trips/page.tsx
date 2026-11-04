import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { Add01Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Pager } from "@/components/ui/Pager";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";
import { Tabs, type TabItem } from "@/components/ui/Tabs";
import { StickyToolbar } from "@/components/ui/StickyToolbar";

import { requireAdmin } from "@/lib/auth";
import { format, type Locale } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { PAGE_SIZE, lastPage, pageRange, parsePage } from "@/lib/pagination";
import {
  STATUS_FILTERS,
  TRIP_STATUSES,
  isDirection,
  isTripStatus,
  parseStatusFilter,
  tripStatusTone,
  tripTabCounts,
  type StatusFilter,
} from "@/lib/trips";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Trips" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ status?: string | string[]; page?: string | string[] }>;

export default function TripsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <TripsList searchParams={searchParams} />
    </Suspense>
  );
}

function href(status: StatusFilter, page = 1): string {
  const params = new URLSearchParams();
  if (status !== "all") params.set("status", status);
  if (page > 1) params.set("page", String(page));
  const query = params.toString();
  return query ? `/trips?${query}` : "/trips";
}

function formatStart(value: string, locale: Locale, timeZone: string): string {
  return new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date(value));
}

async function TripsList({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const query = await searchParams;
  const status = parseStatusFilter(query.status);
  const page = parsePage(query.page);
  const { from, to } = pageRange(page);

  const supabase = await createClient();
  let request = supabase
    .from("trips")
    .select("id, bus_id, driver_id, direction, status, scheduled_start", { count: "exact" })
    .order("scheduled_start", { ascending: false })
    .range(from, to);
  if (status !== "all") request = request.eq("status", status);

  // Counts only, no rows: one per status for the numbers on the tabs.
  const [listed, ...counted] = await Promise.all([
    request,
    ...TRIP_STATUSES.map((st) => supabase.from("trips").select("id", { count: "exact", head: true }).eq("status", st)),
  ]);
  const counts = tripTabCounts(Object.fromEntries(TRIP_STATUSES.map((st, index) => [st, counted[index].count])));

  // A page past the last one is not a failure: the database answers "range not satisfiable" and there is nothing there.
  const { data, count } = listed;
  const error = listed.error?.code === "PGRST103" ? null : listed.error;
  const total = count ?? 0;
  const rows = data ?? [];

  // Names for this page only, so the list never loads every bus and person.
  const busIds = [...new Set(rows.map((row) => row.bus_id))];
  const driverIds = [...new Set(rows.flatMap((row) => (row.driver_id ? [row.driver_id] : [])))];
  const [busRows, driverRows] = await Promise.all([
    busIds.length ? supabase.from("buses").select("id, plate").in("id", busIds) : { data: [] },
    driverIds.length ? supabase.from("profiles").select("id, full_name, email").in("id", driverIds) : { data: [] },
  ]);
  const plates = new Map((busRows.data ?? []).map((bus) => [bus.id, bus.plate]));
  const drivers = new Map((driverRows.data ?? []).map((row) => [row.id, row.full_name || row.email]));

  const tabs: TabItem[] = STATUS_FILTERS.map((filter) => ({
    id: filter,
    label: t.trips.filters[filter],
    href: href(filter),
    count: counts[filter],
    tone: filter === "all" ? "neutral" : tripStatusTone(filter),
  }));

  return (
    <>
      <PageHeader
        title={t.trips.title}
        subtitle={t.trips.subtitle}
        help={{
          label: t.help.open,
          title: t.trips.help.title,
          intro: t.trips.help.intro,
          scenarios: Object.values(t.trips.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
        action={
          <ButtonLink href="/trips/new" icon={Add01Icon}>
            {t.trips.add}
          </ButtonLink>
        }
      />

      <StickyToolbar>
        <Tabs label={t.trips.filtersLabel} items={tabs} active={status} />
      </StickyToolbar>

      {error ? (
        <Notice tone="bad">{t.trips.loadError}</Notice>
      ) : rows.length === 0 ? (
        <EmptyState illustration="/illustrations/bus-stop.webp" title={t.trips.empty} />
      ) : (
        <>
          <TableCard>
            <DataTable minWidth="40rem">
              <Head>
                <Th>{t.trips.columns.start}</Th>
                <Th>{t.trips.columns.bus}</Th>
                <Th>{t.trips.columns.direction}</Th>
                <Th>{t.trips.columns.driver}</Th>
                <Th>{t.trips.columns.status}</Th>
              </Head>
              <tbody>
                {rows.map((row) => (
                  <Tr key={row.id}>
                    <Td>
                      <Link href={`/trips/${row.id}`} className="font-semibold text-fg no-underline hover:text-link">
                        {formatStart(row.scheduled_start, locale, admin.schoolTimezone)}
                      </Link>
                    </Td>
                    <Td>{plates.get(row.bus_id) ?? "-"}</Td>
                    <Td>{isDirection(row.direction) ? t.trips.direction[row.direction] : "-"}</Td>
                    <Td className="text-muted">{(row.driver_id && drivers.get(row.driver_id)) || t.trips.noDriver}</Td>
                    <Td>{isTripStatus(row.status) ? <Chip tone={tripStatusTone(row.status)}>{t.trips.status[row.status]}</Chip> : null}</Td>
                  </Tr>
                ))}
              </tbody>
            </DataTable>
          </TableCard>

          <Pager
            range={format(t.trips.range, { from: from + 1, to: from + rows.length, total })}
            label={t.trips.paginationLabel}
            previous={page > 1 ? { href: href(status, page - 1), label: t.trips.previous } : undefined}
            next={page < lastPage(total, PAGE_SIZE) ? { href: href(status, page + 1), label: t.trips.next } : undefined}
          />
        </>
      )}
    </>
  );
}
