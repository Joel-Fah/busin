import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { requireAdmin } from "@/lib/auth";
import { format, type Locale } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { createClient } from "@/lib/supabase/server";
import {
  FILTERS,
  PAGE_SIZE,
  pageRange,
  parsePage,
  parseStatusFilter,
  pillClass,
  type StatusFilter,
} from "@/lib/subscriptions";

export const metadata: Metadata = { title: "Subscriptions" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ status?: string | string[]; page?: string | string[] }>;

export default function SubscriptionsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
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
  return new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone }).format(
    new Date(value),
  );
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

  const { data, count, error } = await request;
  const total = count ?? 0;
  const rows = data ?? [];
  const lastPage = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <>
      <header className="page-head">
        <h1>{t.subscriptions.title}</h1>
        <p>{t.subscriptions.subtitle}</p>
      </header>

      <nav className="tabs" aria-label={t.subscriptions.filtersLabel}>
        {FILTERS.map((filter) => (
          <Link key={filter} href={href(filter)} aria-current={filter === status ? "page" : undefined}>
            {t.subscriptions.filters[filter]}
          </Link>
        ))}
      </nav>

      {error ? (
        <p className="notice" role="alert">
          {t.subscriptions.loadError}
        </p>
      ) : rows.length === 0 ? (
        <p className="card">{t.subscriptions.empty}</p>
      ) : (
        <>
          <div className="table-wrap card">
            <table>
              <thead>
                <tr>
                  <th scope="col">{t.subscriptions.columns.student}</th>
                  <th scope="col">{t.subscriptions.columns.semester}</th>
                  <th scope="col">{t.subscriptions.columns.stop}</th>
                  <th scope="col">{t.subscriptions.columns.submitted}</th>
                  <th scope="col">{t.subscriptions.columns.status}</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.id}>
                    <td>
                      <Link href={`/subscriptions/${row.id}`}>{row.student?.full_name || row.student?.email}</Link>
                      {row.student?.matricule ? <span className="muted"> {row.student.matricule}</span> : null}
                    </td>
                    <td>{row.semester ? `${t.semester[row.semester.name]} ${row.semester.year}` : ""}</td>
                    <td>{row.stop?.name}</td>
                    <td>{formatDateTime(row.created_at, locale, admin.schoolTimezone)}</td>
                    <td>
                      <span className={pillClass(row.status)}>{t.status[row.status]}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="pager">
            <p>{format(t.subscriptions.range, { from: from + 1, to: from + rows.length, total })}</p>
            <nav className="row" aria-label={t.subscriptions.paginationLabel}>
              {page > 1 ? (
                <Link className="btn btn-secondary" href={href(status, page - 1)}>
                  {t.subscriptions.previous}
                </Link>
              ) : null}
              {page < lastPage ? (
                <Link className="btn btn-secondary" href={href(status, page + 1)}>
                  {t.subscriptions.next}
                </Link>
              ) : null}
            </nav>
          </div>
        </>
      )}
    </>
  );
}
