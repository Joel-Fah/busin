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
import { ColumnFilter } from "@/components/ui/ColumnFilter";
import { FilterChips, type FilterChip } from "@/components/ui/FilterChips";

import { requireAdmin } from "@/lib/auth";
import { chipText, filterText } from "@/lib/filter-text";
import { VALUE_TOKEN } from "@/lib/filters";
import { format, type Locale } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { PAGE_SIZE, PAGE_SIZES, lastPage, pageRange, parsePage } from "@/lib/pagination";
import {
  DIRECTIONS,
  NO_DRIVER,
  STATUS_FILTERS,
  TRIP_STATUSES,
  applyTripFilters,
  isDirection,
  isTripStatus,
  parseTripFilters,
  tripStatusTone,
  tripTabCounts,
  tripsHref,
  type TripFilters,
  type TripQuery,
} from "@/lib/trips";
import { loadTripFilterOptions } from "@/lib/trips-data";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Trips" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<TripQuery & { page?: string | string[] }>;

export default function TripsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <TripsList searchParams={searchParams} />
    </Suspense>
  );
}

function formatStart(value: string, locale: Locale, timeZone: string): string {
  return new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date(value));
}

async function TripsList({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const query = await searchParams;
  const filters = parseTripFilters(query);
  const status = filters.status;
  const page = parsePage(query.page);
  const size = filters.size ?? PAGE_SIZE;
  const { from, to } = pageRange(page, size);

  const supabase = await createClient();
  const narrow = <Q,>(q: Q) => applyTripFilters(q, filters, admin.schoolTimezone);
  let request = narrow(
    supabase
      .from("trips")
      .select("id, bus_id, driver_id, direction, status, scheduled_start", { count: "exact" })
      .order("scheduled_start", { ascending: false })
      .range(from, to),
  );
  // Archived trips have a tab of their own and are left out of every other one.
  request = status === "archived" ? request.not("archived_at", "is", null) : request.is("archived_at", null);
  if (status !== "all" && status !== "archived") request = request.eq("status", status);

  // Counts only, no rows: one per status for the numbers on the tabs, and one for the archive.
  // The counts follow the column filters, so a tab's number is what that tab would show.
  const [listed, archivedCount, options, ...counted] = await Promise.all([
    request,
    narrow(supabase.from("trips").select("id", { count: "exact", head: true }).not("archived_at", "is", null)),
    loadTripFilterOptions(),
    ...TRIP_STATUSES.map((st) =>
      narrow(supabase.from("trips").select("id", { count: "exact", head: true }).eq("status", st).is("archived_at", null)),
    ),
  ]);
  const counts = tripTabCounts(
    Object.fromEntries(TRIP_STATUSES.map((st, index) => [st, counted[index].count])),
    archivedCount.count,
  );

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

  const text = filterText(t);
  const cf = t.columnFilter;
  const plateOf = new Map(options.buses.map((bus) => [bus.id, bus.plate]));
  const driverName = new Map(options.drivers.map((driver) => [driver.id, driver.name]));
  const without = (change: Partial<TripFilters>) => tripsHref({ ...filters, ...change });
  const dayLabel = filters.date
    ? new Intl.DateTimeFormat(locale, { dateStyle: "long", timeZone: "UTC" }).format(new Date(`${filters.date}T00:00:00Z`))
    : null;
  const driverLabel = filters.driver === NO_DRIVER ? t.trips.noDriver : filters.driver ? (driverName.get(filters.driver) ?? "-") : null;

  const chips: FilterChip[] = [
    ...(dayLabel ? [{ label: t.trips.columns.start, value: dayLabel, href: without({ date: null }) }] : []),
    ...(filters.bus ? [{ label: t.trips.columns.bus, value: plateOf.get(filters.bus) ?? "-", href: without({ bus: null }) }] : []),
    ...(filters.direction ? [{ label: t.trips.columns.direction, value: t.trips.direction[filters.direction], href: without({ direction: null }) }] : []),
    ...(driverLabel ? [{ label: t.trips.columns.driver, value: driverLabel, href: without({ driver: null }) }] : []),
  ];
  const anyFilter = chips.length > 0;

  const tabs: TabItem[] = STATUS_FILTERS.map((filter) => ({
    id: filter,
    label: t.trips.filters[filter],
    href: tripsHref({ ...filters, status: filter }),
    count: counts[filter],
    tone: filter === "all" || filter === "archived" ? "neutral" : tripStatusTone(filter),
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

      <FilterChips
        chips={chips}
        clearAllHref={without({ date: null, bus: null, direction: null, driver: null })}
        {...chipText(t)}
      />

      {error ? (
        <Notice tone="bad">{t.trips.loadError}</Notice>
      ) : rows.length === 0 ? (
        <EmptyState illustration="/illustrations/bus-stop.webp" title={status === "archived" ? t.trips.emptyArchived : t.trips.empty} body={anyFilter ? t.trips.emptyFiltered : undefined} />
      ) : (
        <>
          <TableCard>
            <DataTable minWidth="40rem">
              <Head>
                <Th>
                  <ColumnFilter
                    kind="date"
                    label={t.trips.columns.start}
                    value={filters.date}
                    clearHref={without({ date: null })}
                    allLabel={cf.anyDay}
                    pickerLabel={cf.day}
                    hrefTemplate={tripsHref({ ...filters, date: VALUE_TOKEN })}
                    locale={locale}
                    pickerText={t.pickers.date}
                    placeholder={cf.anyDay}
                    {...text}
                  />
                </Th>
                <Th>
                  <ColumnFilter
                    label={t.trips.columns.bus}
                    value={filters.bus}
                    clearHref={without({ bus: null })}
                    allLabel={cf.allBuses}
                    options={options.buses.map((bus) => ({ value: bus.id, label: bus.plate, href: without({ bus: bus.id }) }))}
                    {...text}
                  />
                </Th>
                <Th>
                  <ColumnFilter
                    label={t.trips.columns.direction}
                    value={filters.direction}
                    clearHref={without({ direction: null })}
                    allLabel={cf.bothDirections}
                    options={DIRECTIONS.map((direction) => ({ value: direction, label: t.trips.direction[direction], href: without({ direction }) }))}
                    {...text}
                  />
                </Th>
                <Th>
                  <ColumnFilter
                    label={t.trips.columns.driver}
                    value={filters.driver}
                    clearHref={without({ driver: null })}
                    allLabel={cf.allDrivers}
                    options={[
                      { value: NO_DRIVER, label: t.trips.noDriver, href: without({ driver: NO_DRIVER }) },
                      ...options.drivers.map((driver) => ({ value: driver.id, label: driver.name, href: without({ driver: driver.id }) })),
                    ]}
                    {...text}
                  />
                </Th>
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
            previous={page > 1 ? { href: tripsHref(filters, page - 1), label: t.trips.previous } : undefined}
            next={page < lastPage(total, size) ? { href: tripsHref(filters, page + 1), label: t.trips.next } : undefined}
            perPage={{
              label: t.pager.perPage,
              groupLabel: t.pager.perPageLabel,
              current: size,
              options: PAGE_SIZES.map((n) => ({ size: n, href: tripsHref({ ...filters, size: n }) })),
            }}
          />
        </>
      )}
    </>
  );
}
