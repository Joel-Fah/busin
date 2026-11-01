import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { requireAdmin } from "@/lib/auth";
import { format, type Locale } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { PAGE_SIZE, lastPage, pageRange, parsePage } from "@/lib/pagination";
import { STATUS_FILTERS, isDirection, isTripStatus, parseStatusFilter, statusPill, type StatusFilter } from "@/lib/trips";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Trips" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ status?: string | string[]; page?: string | string[] }>;

export default function TripsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
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

  const { data, count, error } = await request;
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

  return (
    <>
      <header className="page-head">
        <h1>{t.trips.title}</h1>
        <p>{t.trips.subtitle}</p>
      </header>

      <div className="row">
        <Link className="btn btn-primary" href="/trips/new">
          {t.trips.add}
        </Link>
      </div>

      <nav className="tabs" aria-label={t.trips.filtersLabel}>
        {STATUS_FILTERS.map((filter) => (
          <Link key={filter} href={href(filter)} aria-current={filter === status ? "page" : undefined}>
            {t.trips.filters[filter]}
          </Link>
        ))}
      </nav>

      {error ? (
        <p className="notice" role="alert">
          {t.trips.loadError}
        </p>
      ) : rows.length === 0 ? (
        <p className="card">{t.trips.empty}</p>
      ) : (
        <>
          <div className="table-wrap card">
            <table>
              <thead>
                <tr>
                  <th scope="col">{t.trips.columns.start}</th>
                  <th scope="col">{t.trips.columns.bus}</th>
                  <th scope="col">{t.trips.columns.direction}</th>
                  <th scope="col">{t.trips.columns.driver}</th>
                  <th scope="col">{t.trips.columns.status}</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.id}>
                    <td>
                      <Link href={`/trips/${row.id}`}>{formatStart(row.scheduled_start, locale, admin.schoolTimezone)}</Link>
                    </td>
                    <td>{plates.get(row.bus_id) ?? "-"}</td>
                    <td>{isDirection(row.direction) ? t.trips.direction[row.direction] : "-"}</td>
                    <td>{(row.driver_id && drivers.get(row.driver_id)) || t.trips.noDriver}</td>
                    <td>
                      {isTripStatus(row.status) ? (
                        <span className={statusPill(row.status)}>{t.trips.status[row.status]}</span>
                      ) : null}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="pager">
            <p>{format(t.trips.range, { from: from + 1, to: from + rows.length, total })}</p>
            <nav className="row" aria-label={t.trips.paginationLabel}>
              {page > 1 ? (
                <Link className="btn btn-secondary" href={href(status, page - 1)}>
                  {t.trips.previous}
                </Link>
              ) : null}
              {page < lastPage(total, PAGE_SIZE) ? (
                <Link className="btn btn-secondary" href={href(status, page + 1)}>
                  {t.trips.next}
                </Link>
              ) : null}
            </nav>
          </div>
        </>
      )}
    </>
  );
}
