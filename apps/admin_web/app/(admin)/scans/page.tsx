import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

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
    <Suspense fallback={<section aria-busy="true" />}>
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

  const [{ data, count, error }, stopOptions, chipTrip] = await Promise.all([
    request,
    supabase.from("stops").select("id, name").order("name", { ascending: true }).limit(500),
    filters.trip
      ? supabase.from("trips").select("id, bus_id, direction, scheduled_start").eq("id", filters.trip).maybeSingle()
      : Promise.resolve({ data: null }),
  ]);
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
      <header className="page-head">
        <h1>{t.scans.title}</h1>
        <p>{t.scans.subtitle}</p>
      </header>

      <form method="get" action="/scans" className="search-form" aria-label={t.scans.filtersLabel}>
        {filters.trip ? <input type="hidden" name="trip" value={filters.trip} /> : null}
        <div className="field">
          <label htmlFor="stop">{t.scans.filters.stop}</label>
          <select id="stop" name="stop" defaultValue={filters.stop ?? ""}>
            <option value="">{t.scans.filters.allStops}</option>
            {(stopOptions.data ?? []).map((stop) => (
              <option key={stop.id} value={stop.id}>
                {stop.name}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="date">{t.scans.filters.day}</label>
          <input id="date" name="date" type="date" defaultValue={filters.date ?? ""} />
        </div>
        <button type="submit" className="btn btn-secondary">
          {t.scans.filters.apply}
        </button>
        {anyFilter ? (
          <Link className="btn btn-secondary" href="/scans">
            {t.scans.filters.clear}
          </Link>
        ) : null}
      </form>

      {chipLabel ? (
        <p className="muted">
          {t.scans.filters.trip}: {chipLabel}{" "}
          <Link href={scansHref({ ...filters, trip: null })}>{t.scans.filters.removeTrip}</Link>
        </p>
      ) : null}

      {error ? (
        <p className="notice" role="alert">
          {t.scans.loadError}
        </p>
      ) : rows.length === 0 ? (
        <p className="card">{anyFilter ? t.scans.emptyFiltered : t.scans.empty}</p>
      ) : (
        <>
          <div className="table-wrap card">
            <table>
              <thead>
                <tr>
                  <th scope="col">{t.scans.columns.time}</th>
                  <th scope="col">{t.scans.columns.student}</th>
                  <th scope="col">{t.scans.columns.stop}</th>
                  <th scope="col">{t.scans.columns.bus}</th>
                  <th scope="col">{t.scans.columns.direction}</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => {
                  const student = studentById.get(row.student_id);
                  const trip = tripById.get(row.trip_id);
                  return (
                    <tr key={row.id}>
                      <td>{formatTime(row.scanned_at, locale, admin.schoolTimezone)}</td>
                      <td>
                        <Link href={`/people/${row.student_id}`}>{student?.full_name || student?.email || "-"}</Link>
                        {student?.matricule ? <span className="muted block">{student.matricule}</span> : null}
                      </td>
                      <td>{(row.stop_id && stopById.get(row.stop_id)) || t.scans.noStop}</td>
                      <td>{(trip && plateById.get(trip.bus_id)) || "-"}</td>
                      <td>{trip && isDirection(trip.direction) ? t.trips.direction[trip.direction] : "-"}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          <div className="pager">
            <p>{format(t.scans.range, { from: from + 1, to: from + rows.length, total })}</p>
            <nav className="row" aria-label={t.scans.paginationLabel}>
              {page > 1 ? (
                <Link className="btn btn-secondary" href={scansHref(filters, page - 1)}>
                  {t.scans.previous}
                </Link>
              ) : null}
              {page < lastPage(total, PAGE_SIZE) ? (
                <Link className="btn btn-secondary" href={scansHref(filters, page + 1)}>
                  {t.scans.next}
                </Link>
              ) : null}
            </nav>
          </div>
        </>
      )}
    </>
  );
}
