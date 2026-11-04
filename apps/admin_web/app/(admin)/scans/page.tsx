import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { FlagTriangleRightIcon } from "@hugeicons/core-free-icons";

import { Avatar } from "@/components/ui/Avatar";
import { Button, ButtonLink } from "@/components/ui/Button";
import { DatePicker } from "@/components/ui/DatePicker";
import { EmptyState } from "@/components/ui/EmptyState";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Pager } from "@/components/ui/Pager";
import { Select } from "@/components/ui/Select";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";

import { requireAdmin } from "@/lib/auth";
import { format, type Locale } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { PAGE_SIZE, lastPage, pageRange, parsePage } from "@/lib/pagination";
import { dayBounds, parseScanFilters, scansHref } from "@/lib/scans";
import { createClient } from "@/lib/supabase/server";
import { isDirection } from "@/lib/trips";

export const metadata: Metadata = { title: "Boardings" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{
  trip?: string | string[];
  stop?: string | string[];
  date?: string | string[];
  page?: string | string[];
}>;

export default function ScansPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <ScansList searchParams={searchParams} />
    </Suspense>
  );
}

function formatTime(value: string, locale: Locale, timeZone: string): string {
  return new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date(value));
}

async function ScansList({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const query = await searchParams;
  const filters = parseScanFilters(query);
  const page = parsePage(query.page);
  const { from, to } = pageRange(page);

  const supabase = await createClient();
  let request = supabase
    .from("scans")
    .select("id, trip_id, student_id, stop_id, scanned_at", { count: "exact" })
    .order("scanned_at", { ascending: false })
    .range(from, to);
  if (filters.trip) request = request.eq("trip_id", filters.trip);
  if (filters.stop) request = request.eq("stop_id", filters.stop);
  if (filters.date) {
    const bounds = dayBounds(filters.date, admin.schoolTimezone);
    request = request.gte("scanned_at", bounds.from).lt("scanned_at", bounds.to);
  }

  const [listed, stopOptions, chipTrip] = await Promise.all([
    request,
    supabase.from("stops").select("id, name").order("name", { ascending: true }).limit(500),
    filters.trip
      ? supabase.from("trips").select("id, bus_id, direction, scheduled_start").eq("id", filters.trip).maybeSingle()
      : Promise.resolve({ data: null }),
  ]);
  // A page past the last one is not a failure: the database answers "range not satisfiable" and there is nothing there.
  const { data, count } = listed;
  const error = listed.error?.code === "PGRST103" ? null : listed.error;
  const total = count ?? 0;
  const rows = data ?? [];

  // Names for this page only, so the list never loads every student, stop and trip.
  const studentIds = [...new Set(rows.map((row) => row.student_id))];
  const stopIds = [...new Set(rows.flatMap((row) => (row.stop_id ? [row.stop_id] : [])))];
  const tripIds = [...new Set(rows.map((row) => row.trip_id))];
  const [students, stops, trips] = await Promise.all([
    studentIds.length ? supabase.from("profiles").select("id, full_name, email, matricule").in("id", studentIds) : { data: [] },
    stopIds.length ? supabase.from("stops").select("id, name").in("id", stopIds) : { data: [] },
    tripIds.length ? supabase.from("trips").select("id, bus_id, direction").in("id", tripIds) : { data: [] },
  ]);
  const busIds = [...new Set([...(trips.data ?? []).map((trip) => trip.bus_id), ...(chipTrip.data ? [chipTrip.data.bus_id] : [])])];
  const buses = busIds.length ? await supabase.from("buses").select("id, plate").in("id", busIds) : { data: [] };

  const studentById = new Map((students.data ?? []).map((row) => [row.id, row]));
  const stopById = new Map((stops.data ?? []).map((row) => [row.id, row.name]));
  const tripById = new Map((trips.data ?? []).map((row) => [row.id, row]));
  const plateById = new Map((buses.data ?? []).map((row) => [row.id, row.plate]));

  const chipLabel =
    chipTrip.data && isDirection(chipTrip.data.direction)
      ? `${formatTime(chipTrip.data.scheduled_start, locale, admin.schoolTimezone)} / ${plateById.get(chipTrip.data.bus_id) ?? "-"} / ${t.trips.direction[chipTrip.data.direction]}`
      : null;
  const anyFilter = Boolean(filters.trip || filters.stop || filters.date);

  return (
    <>
      <PageHeader
        title={t.scans.title}
        subtitle={t.scans.subtitle}
        help={{
          label: t.help.open,
          title: t.scans.help.title,
          intro: t.scans.help.intro,
          scenarios: Object.values(t.scans.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
      />

      <form method="get" action="/scans" aria-label={t.scans.filtersLabel} className="flex flex-wrap items-end gap-3">
        {filters.trip ? <input type="hidden" name="trip" value={filters.trip} /> : null}
        <Select
          id="stop"
          name="stop"
          label={t.scans.filters.stop}
          icon={FlagTriangleRightIcon}
          defaultValue={filters.stop ?? ""}
          className="w-full sm:w-72"
          options={[{ value: "", label: t.scans.filters.allStops }, ...(stopOptions.data ?? []).map((stop) => ({ value: stop.id, label: stop.name }))]}
        />
        <DatePicker
          id="date"
          name="date"
          label={t.scans.filters.day}
          locale={locale}
          text={t.pickers.date}
          defaultValue={filters.date ?? ""}
          placeholder={t.scans.filters.anyDay}
          className="w-full sm:w-64"
        />
        <Button type="submit" variant="secondary">
          {t.scans.filters.apply}
        </Button>
        {anyFilter ? (
          <ButtonLink variant="ghost" href="/scans">
            {t.scans.filters.clear}
          </ButtonLink>
        ) : null}
      </form>

      {chipLabel ? (
        <div className="flex flex-wrap items-center gap-3 rounded-md bg-surface-2 px-5 py-3 text-sm">
          <span>
            {t.scans.filters.trip}: <strong>{chipLabel}</strong>
          </span>
          <Link href={scansHref({ ...filters, trip: null })} className="font-semibold text-fg no-underline hover:text-link">
            {t.scans.filters.removeTrip}
          </Link>
        </div>
      ) : null}

      {error ? (
        <Notice tone="bad">{t.scans.loadError}</Notice>
      ) : rows.length === 0 ? (
        <EmptyState illustration="/illustrations/ticket1.webp" title={anyFilter ? t.scans.emptyFiltered : t.scans.empty} />
      ) : (
        <>
          <TableCard>
            <DataTable minWidth="40rem">
              <Head>
                <Th>{t.scans.columns.time}</Th>
                <Th>{t.scans.columns.student}</Th>
                <Th>{t.scans.columns.stop}</Th>
                <Th>{t.scans.columns.bus}</Th>
                <Th>{t.scans.columns.direction}</Th>
              </Head>
              <tbody>
                {rows.map((row) => {
                  const student = studentById.get(row.student_id);
                  const trip = tripById.get(row.trip_id);
                  const name = student?.full_name || student?.email || "-";
                  return (
                    <Tr key={row.id}>
                      <Td className="text-muted">{formatTime(row.scanned_at, locale, admin.schoolTimezone)}</Td>
                      <Td>
                        <div className="flex items-center gap-3">
                          <Avatar name={name} url={null} size={40} />
                          <div className="min-w-0">
                            <Link href={`/people/${row.student_id}`} className="font-semibold text-fg no-underline hover:text-link">
                              {name}
                            </Link>
                            {student?.matricule ? <p className="text-xs text-muted">{student.matricule}</p> : null}
                          </div>
                        </div>
                      </Td>
                      <Td>{(row.stop_id && stopById.get(row.stop_id)) || t.scans.noStop}</Td>
                      <Td>{(trip && plateById.get(trip.bus_id)) || "-"}</Td>
                      <Td>{trip && isDirection(trip.direction) ? t.trips.direction[trip.direction] : "-"}</Td>
                    </Tr>
                  );
                })}
              </tbody>
            </DataTable>
          </TableCard>

          <Pager
            range={format(t.scans.range, { from: from + 1, to: from + rows.length, total })}
            label={t.scans.paginationLabel}
            previous={page > 1 ? { href: scansHref(filters, page - 1), label: t.scans.previous } : undefined}
            next={page < lastPage(total, PAGE_SIZE) ? { href: scansHref(filters, page + 1), label: t.scans.next } : undefined}
          />
        </>
      )}
    </>
  );
}
