import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { Search01Icon } from "@hugeicons/core-free-icons";

import { FlashToast } from "@/components/FlashToast";
import { JoinRequestActions } from "@/components/people/JoinRequestActions";
import { Avatar } from "@/components/ui/Avatar";
import { Button, ButtonLink } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { Input } from "@/components/ui/Input";
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
import { PAGE_SIZE, PAGE_SIZES, first, lastPage, pageRange, parsePage, parsePageSize, sizeParam } from "@/lib/pagination";
import {
  accountTone,
  isPeopleDone,
  isPeopleErrorKey,
  parseRoleFilter,
  parseSearch,
  ROLE_FILTERS,
  type RoleFilter,
  ROLES,
  roleTabCounts,
  roleTone,
  searchFilter,
} from "@/lib/people";
import { createClient } from "@/lib/supabase/server";

import { declineMember, verifyMember } from "./actions";

export const metadata: Metadata = { title: "People" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ role?: string | string[]; q?: string | string[]; page?: string | string[]; size?: string | string[]; done?: string | string[]; error?: string | string[] }>;

export default function PeoplePage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <PeopleList searchParams={searchParams} />
    </Suspense>
  );
}

function href(role: RoleFilter, q: string, page = 1, size = PAGE_SIZE): string {
  const params = new URLSearchParams();
  if (role !== "all") params.set("role", role);
  if (q) params.set("q", q);
  const perPage = sizeParam(size);
  if (perPage) params.set("size", String(perPage));
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
  const size = parsePageSize(query.size);
  const doneParam = first(query.done);
  const done = isPeopleDone(doneParam) ? doneParam : null;
  const errorParam = first(query.error);
  const errorKey = isPeopleErrorKey(errorParam) ? errorParam : null;
  const { from, to } = pageRange(page, size);

  const supabase = await createClient();
  const verifying = role === "verify";
  let request = supabase
    .from("profiles")
    .select("id, full_name, email, role, status, matricule, created_at, join_requested_at", { count: "exact" })
    // The queue is oldest request first, so no one waits forever; the other lists are newest first.
    .order(verifying ? "join_requested_at" : "created_at", { ascending: verifying })
    .range(from, to);
  if (verifying) request = request.eq("role", "student").eq("status", "pending").not("join_requested_at", "is", null);
  else if (role !== "all") request = request.eq("role", role);
  if (q) request = request.or(searchFilter(q));

  let toVerify = supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "student").eq("status", "pending").not("join_requested_at", "is", null);
  if (q) toVerify = toVerify.or(searchFilter(q));

  // Counts only, no rows: one per role for the numbers on the tabs, following the search.
  const [listed, verifyCount, ...counted] = await Promise.all([
    request,
    toVerify,
    ...ROLES.map((r) => {
      let counting = supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", r);
      if (q) counting = counting.or(searchFilter(q));
      return counting;
    }),
  ]);
  const counts = roleTabCounts(Object.fromEntries(ROLES.map((r, index) => [r, counted[index].count])), verifyCount.count);

  // A page past the last one is not a failure: the database answers "range not satisfiable" and there is nothing there.
  const { data, count } = listed;
  const error = listed.error?.code === "PGRST103" ? null : listed.error;
  const total = count ?? 0;
  const rows = data ?? [];

  const tabs: TabItem[] = ROLE_FILTERS.map((filter) => ({
    id: filter,
    label: t.people.filters[filter],
    href: href(filter, q, 1, size),
    count: counts[filter],
    tone: filter === "verify" ? (counts.verify > 0 ? "warn" : "neutral") : filter === "admin" ? "info" : filter === "staff" ? "warn" : "neutral",
  }));

  return (
    <>
      <PageHeader
        title={t.people.title}
        subtitle={t.people.subtitle}
        help={{
          label: t.help.open,
          title: t.people.help.title,
          intro: t.people.help.intro,
          scenarios: Object.values(t.people.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
      />

      <StickyToolbar>
        <form method="get" action="/people" role="search" className="flex w-full max-w-2xl flex-wrap items-end gap-3">
          {role !== "all" ? <input type="hidden" name="role" value={role} /> : null}
          {sizeParam(size) ? <input type="hidden" name="size" value={size} /> : null}
          <Input
            id="q"
            name="q"
            type="search"
            label={t.people.search.label}
            icon={Search01Icon}
            defaultValue={q}
            placeholder={t.people.search.placeholder}
            maxLength={64}
            autoComplete="off"
            className="min-w-64 flex-1"
          />
          <Button type="submit" variant="secondary">
            {t.people.search.button}
          </Button>
          {q ? (
            <ButtonLink variant="ghost" href={href(role, "", 1, size)}>
              {t.people.search.clear}
            </ButtonLink>
          ) : null}
        </form>

        <Tabs label={t.people.filtersLabel} items={tabs} active={role} />
      </StickyToolbar>

      {done ? <FlashToast message={t.people.done[done]} /> : null}
      {errorKey ? <Notice tone="bad">{t.people.errors[errorKey]}</Notice> : null}
      {verifying ? <p className="max-w-2xl text-sm text-muted">{t.people.verify.intro}</p> : null}

      {error ? (
        <Notice tone="bad">{t.people.loadError}</Notice>
      ) : rows.length === 0 ? (
        <EmptyState illustration={verifying ? "/illustrations/verified.webp" : "/illustrations/staff.webp"} title={verifying && !q ? t.people.verify.empty : t.people.empty} />
      ) : (
        <>
          <TableCard>
            <DataTable minWidth="40rem">
              <Head>
                <Th>{t.people.columns.person}</Th>
                {verifying ? (
                  <>
                    <Th>{t.people.columns.asked}</Th>
                    <Th>{t.people.columns.actions}</Th>
                  </>
                ) : (
                  <>
                    <Th>{t.people.columns.role}</Th>
                    <Th>{t.people.columns.status}</Th>
                    <Th>{t.people.columns.joined}</Th>
                  </>
                )}
              </Head>
              <tbody>
                {rows.map((row) => (
                  <Tr key={row.id}>
                    <Td>
                      <div className="flex items-center gap-3">
                        <Avatar name={row.full_name || row.email} url={null} size={40} />
                        <div className="min-w-0">
                          <Link href={`/people/${row.id}`} className="font-semibold text-fg no-underline hover:text-link">
                            {row.full_name || row.email}
                          </Link>
                          <p className="text-xs break-all text-muted">
                            {row.email}
                            {row.matricule ? ` / ${row.matricule}` : ""}
                          </p>
                        </div>
                      </div>
                    </Td>
                    {verifying ? (
                      <>
                        <Td className="text-muted">{formatDate(row.join_requested_at ?? row.created_at, locale, admin.schoolTimezone)}</Td>
                        <Td>
                          <JoinRequestActions id={row.id} copy={t.people.verify} verify={verifyMember} decline={declineMember} />
                        </Td>
                      </>
                    ) : (
                      <>
                        <Td>
                          <Chip tone={roleTone(row.role)}>{t.role[row.role]}</Chip>
                        </Td>
                        <Td>
                          <Chip tone={accountTone(row.status)}>{t.accountStatus[row.status]}</Chip>
                        </Td>
                        <Td className="text-muted">{formatDate(row.created_at, locale, admin.schoolTimezone)}</Td>
                      </>
                    )}
                  </Tr>
                ))}
              </tbody>
            </DataTable>
          </TableCard>

          <Pager
            range={format(t.people.range, { from: from + 1, to: from + rows.length, total })}
            label={t.people.paginationLabel}
            previous={page > 1 ? { href: href(role, q, page - 1, size), label: t.people.previous } : undefined}
            next={page < lastPage(total, size) ? { href: href(role, q, page + 1, size), label: t.people.next } : undefined}
            perPage={{
              label: t.pager.perPage,
              groupLabel: t.pager.perPageLabel,
              current: size,
              options: PAGE_SIZES.map((n) => ({ size: n, href: href(role, q, 1, n) })),
            }}
          />
        </>
      )}
    </>
  );
}
