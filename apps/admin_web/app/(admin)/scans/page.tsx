import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { Avatar } from "@/components/ui/Avatar";
import { ColumnFilter } from "@/components/ui/ColumnFilter";
import { EmptyState } from "@/components/ui/EmptyState";
import { FilterChips, type FilterChip } from "@/components/ui/FilterChips";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Pager } from "@/components/ui/Pager";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";

import { busLabel } from "@/lib/buses";
import { requireAdmin } from "@/lib/auth";
import { chipText, filterText } from "@/lib/filter-text";
import { VALUE_TOKEN } from "@/lib/filters";
import { format, type Locale } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { PAGE_SIZE, PAGE_SIZES, lastPage, pageRange, parsePage } from "@/lib/pagination";
import { dayBounds, parseScanFilters, scansHref } from "@/lib/scans";
import { createClient } from "@/lib/supabase/server";
import { DIRECTIONS, isDirection } from "@/lib/trips";

export const metadata: Metadata = { title: "Boardings" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{
  trip?: string | string[];
  stop?: string | string[];
  date?: string | string[];
  bus?: string | string[];
  direction?: string | string[];
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
  const size = filters.size ?? PAGE_SIZE;
  const { from, to } = pageRange(page, size);

  const supabase = await createClient();
  let request = supabase
    .from("scans")
    // The trip comes with the boarding (an inner join), which is also how the bus and direction filters reach it.
    .select("id, trip_id, student_id, stop_id, scanned_at, trip:trips!scans_trip_id_school_id_fkey!inner(bus_id, direction)", { count: "exact" })
    .order("scanned_at", { ascending: false })
    .range(from, to);
  if (filters.trip) request = request.eq("trip_id", filters.trip);
  if (filters.stop) request = request.eq("stop_id", filters.stop);
  if (filters.bus) request = request.eq("trip.bus_id", filters.bus);
  if (filters.direction) request = request.eq("trip.direction", filters.direction);
  if (filters.date) {
    const bounds = dayBounds(filters.date, admin.schoolTimezone);
    request = request.gte("scanned_at", bounds.from).lt("scanned_at", bounds.to);
  }

  const [listed, stopOptions, busOptions, chipTrip] = await Promise.all([
    request,
    supabase.from("stops").select("id, name").order("name", { ascending: true }).limit(500),
    supabase.from("buses").select("id, plate, name").order("plate", { ascending: true }).limit(200),
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
  const [students, stops] = await Promise.all([
    studentIds.length ? supabase.from("profiles").select("id, full_name, email, matricule").in("id", studentIds) : { data: [] },
    stopIds.length ? supabase.from("stops").select("id, name").in("id", stopIds) : { data: [] },
  ]);

  const studentById = new Map((students.data ?? []).map((row) => [row.id, row]));
  const stopById = new Map((stops.data ?? []).map((row) => [row.id, row.name]));
  const plateById = new Map((busOptions.data ?? []).map((row) => [row.id, busLabel(row)]));

  const chipLabel =
    chipTrip.data && isDirection(chipTrip.data.direction)
      ? `${formatTime(chipTrip.data.scheduled_start, locale, admin.schoolTimezone)} / ${plateById.get(chipTrip.data.bus_id) ?? "-"} / ${t.trips.direction[chipTrip.data.direction]}`
      : null;
  const text = filterText(t);
  const cf = t.columnFilter;
  const without = (change: Partial<typeof filters>) => scansHref({ ...filters, ...change });
  const stopList = stopOptions.data ?? [];
  const dayLabel = filters.date
    ? new Intl.DateTimeFormat(locale, { dateStyle: "long", timeZone: "UTC" }).format(new Date(`${filters.date}T00:00:00Z`))
    : null;
  const chips: FilterChip[] = [
    ...(dayLabel ? [{ label: t.scans.columns.time, value: dayLabel, href: without({ date: null }) }] : []),
    ...(filters.stop ? [{ label: t.scans.columns.stop, value: stopList.find((stop) => stop.id === filters.stop)?.name ?? "-", href: without({ stop: null }) }] : []),
    ...(filters.bus ? [{ label: t.scans.columns.bus, value: plateById.get(filters.bus) ?? "-", href: without({ bus: null }) }] : []),
    ...(filters.direction ? [{ label: t.scans.columns.direction, value: t.trips.direction[filters.direction], href: without({ direction: null }) }] : []),
  ];
  const anyFilter = Boolean(filters.trip) || chips.length > 0;

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

      <FilterChips
        chips={chips}
        clearAllHref={without({ date: null, stop: null, bus: null, direction: null })}
        {...chipText(t)}
      />

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
                <Th>
                  <ColumnFilter
                    kind="date"
                    label={t.scans.columns.time}
                    value={filters.date}
                    clearHref={without({ date: null })}
                    allLabel={cf.anyDay}
                    pickerLabel={cf.day}
                    hrefTemplate={scansHref({ ...filters, date: VALUE_TOKEN })}
                    locale={locale}
                    pickerText={t.pickers.date}
                    placeholder={cf.anyDay}
                    {...text}
                  />
                </Th>
                <Th>{t.scans.columns.student}</Th>
                <Th>
                  <ColumnFilter
                    label={t.scans.columns.stop}
                    value={filters.stop}
                    clearHref={without({ stop: null })}
                    allLabel={cf.allStops}
                    options={stopList.map((stop) => ({ value: stop.id, label: stop.name, href: without({ stop: stop.id }) }))}
                    {...text}
                  />
                </Th>
                <Th>
                  <ColumnFilter
                    label={t.scans.columns.bus}
                    value={filters.bus}
                    clearHref={without({ bus: null })}
                    allLabel={cf.allBuses}
                    options={(busOptions.data ?? []).map((bus) => ({ value: bus.id, label: busLabel(bus), href: without({ bus: bus.id }) }))}
                    {...text}
                  />
                </Th>
                <Th>
                  <ColumnFilter
                    label={t.scans.columns.direction}
                    value={filters.direction}
                    clearHref={without({ direction: null })}
                    allLabel={cf.bothDirections}
                    options={DIRECTIONS.map((direction) => ({ value: direction, label: t.trips.direction[direction], href: without({ direction }) }))}
                    {...text}
                  />
                </Th>
              </Head>
              <tbody>
                {rows.map((row) => {
                  const student = studentById.get(row.student_id);
                  const trip = row.trip;
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
            next={page < lastPage(total, size) ? { href: scansHref(filters, page + 1), label: t.scans.next } : undefined}
            perPage={{
              label: t.pager.perPage,
              groupLabel: t.pager.perPageLabel,
              current: size,
              options: PAGE_SIZES.map((n) => ({ size: n, href: scansHref({ ...filters, size: n }) })),
            }}
          />
        </>
      )}
    </>
  );
}
