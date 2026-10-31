import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { requireAdmin } from "@/lib/auth";
import { format, type Locale } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { PAGE_SIZE, lastPage, pageRange, parsePage } from "@/lib/pagination";
import {
  ROLE_FILTERS,
  accountPill,
  initials,
  parseRoleFilter,
  parseSearch,
  rolePill,
  searchFilter,
  type RoleFilter,
} from "@/lib/people";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "People" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ role?: string | string[]; q?: string | string[]; page?: string | string[] }>;

export default function PeoplePage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <PeopleList searchParams={searchParams} />
    </Suspense>
  );
}

function href(role: RoleFilter, q: string, page = 1): string {
  const params = new URLSearchParams();
  if (role !== "all") params.set("role", role);
  if (q) params.set("q", q);
  if (page > 1) params.set("page", String(page));
  const query = params.toString();
  return query ? `/people?${query}` : "/people";
}

function formatDate(value: string, locale: Locale, timeZone: string): string {
  return new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone }).format(new Date(value));
}

async function PeopleList({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const query = await searchParams;
  const role = parseRoleFilter(query.role);
  const q = parseSearch(query.q);
  const page = parsePage(query.page);
  const { from, to } = pageRange(page);

  const supabase = await createClient();
  let request = supabase
    .from("profiles")
    .select("id, full_name, email, role, status, matricule, created_at", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(from, to);
  if (role !== "all") request = request.eq("role", role);
  if (q) request = request.or(searchFilter(q));

  const { data, count, error } = await request;
  const total = count ?? 0;
  const rows = data ?? [];

  return (
    <>
      <header className="page-head">
        <h1>{t.people.title}</h1>
        <p>{t.people.subtitle}</p>
      </header>

      <form method="get" action="/people" role="search" className="search-form">
        {role !== "all" ? <input type="hidden" name="role" value={role} /> : null}
        <label htmlFor="q" className="visually-hidden">
          {t.people.search.label}
        </label>
        <input
          id="q"
          name="q"
          type="search"
          defaultValue={q}
          placeholder={t.people.search.label}
          maxLength={64}
          className="search-input"
        />
        <button type="submit" className="btn btn-secondary">
          {t.people.search.button}
        </button>
        {q ? (
          <Link className="btn btn-secondary" href={href(role, "")}>
            {t.people.search.clear}
          </Link>
        ) : null}
      </form>

      <nav className="tabs" aria-label={t.people.filtersLabel}>
        {ROLE_FILTERS.map((filter) => (
          <Link key={filter} href={href(filter, q)} aria-current={filter === role ? "page" : undefined}>
            {t.people.filters[filter]}
          </Link>
        ))}
      </nav>

      {error ? (
        <p className="notice" role="alert">
          {t.people.loadError}
        </p>
      ) : rows.length === 0 ? (
        <p className="card">{t.people.empty}</p>
      ) : (
        <>
          <div className="table-wrap card">
            <table>
              <thead>
                <tr>
                  <th scope="col">{t.people.columns.person}</th>
                  <th scope="col">{t.people.columns.role}</th>
                  <th scope="col">{t.people.columns.status}</th>
                  <th scope="col">{t.people.columns.joined}</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.id}>
                    <td>
                      <div className="person">
                        <span className="avatar" aria-hidden="true">
                          {initials(row.full_name, row.email)}
                        </span>
                        <span>
                          <Link href={`/people/${row.id}`}>{row.full_name || row.email}</Link>
                          <span className="muted block">
                            {row.email}
                            {row.matricule ? ` / ${row.matricule}` : ""}
                          </span>
                        </span>
                      </div>
                    </td>
                    <td>
                      <span className={rolePill(row.role)}>{t.role[row.role]}</span>
                    </td>
                    <td>
                      <span className={accountPill(row.status)}>{t.accountStatus[row.status]}</span>
                    </td>
                    <td>{formatDate(row.created_at, locale, admin.schoolTimezone)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="pager">
            <p>{format(t.people.range, { from: from + 1, to: from + rows.length, total })}</p>
            <nav className="row" aria-label={t.people.paginationLabel}>
              {page > 1 ? (
                <Link className="btn btn-secondary" href={href(role, q, page - 1)}>
                  {t.people.previous}
                </Link>
              ) : null}
              {page < lastPage(total, PAGE_SIZE) ? (
                <Link className="btn btn-secondary" href={href(role, q, page + 1)}>
                  {t.people.next}
                </Link>
              ) : null}
            </nav>
          </div>
        </>
      )}
    </>
  );
}
