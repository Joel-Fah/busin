import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import {
  Bus01Icon,
  Navigation03Icon,
  ReceiptTextIcon,
  School01Icon,
  Ticket03Icon,
  UserAdd01Icon,
  UserMultiple02Icon,
  Clock01Icon,
} from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { LevelChip } from "@/components/platform/LevelChip";
import { SchoolLogo } from "@/components/SchoolLogo";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Skeleton } from "@/components/ui/Skeleton";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";
import { requirePlatformAdmin } from "@/lib/auth";
import { supabaseConfig } from "@/lib/env";
import { format, type Messages } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { needingAttention, parseSchoolRows, signalSentence } from "@/lib/platform-health";
import { daysSince, parsePlatformOverview } from "@/lib/platform-overview";
import { logoUrl } from "@/lib/school";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Platform" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function PlatformOverviewPage() {
  return (
    <Suspense fallback={<OverviewSkeleton />}>
      <Overview />
    </Suspense>
  );
}

function OverviewSkeleton() {
  return (
    <div aria-hidden className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
        <Skeleton key={i} className="h-32 rounded-lg" />
      ))}
      <Skeleton className="h-72 rounded-lg sm:col-span-2 xl:col-span-4" />
    </div>
  );
}

/** One figure with its icon, title and a line of detail. */
function Figure({ icon, title, value, hint, testId }: { icon: IconSvgElement; title: string; value: number; hint?: string; testId?: string }) {
  return (
    <div data-testid={testId}>
    <Card className="flex h-full flex-col gap-3 p-6!">
      <div className="flex items-center gap-2 text-sm font-semibold text-muted">
        <Icon icon={icon} size={18} />
        <h2 className="m-0 text-sm font-semibold">{title}</h2>
      </div>
      <p className="m-0 text-3xl font-extrabold tracking-tight tabular-nums">{value}</p>
      {hint ? <p className="m-0 text-sm text-muted">{hint}</p> : null}
    </Card>
    </div>
  );
}

function lastAction(iso: string | null, copy: Messages["platform"]["schools"]): string {
  const days = daysSince(iso);
  if (days === null) return copy.never;
  if (days === 0) return copy.today;
  if (days === 1) return copy.oneDayAgo;
  return format(copy.daysAgo, { n: days });
}

async function Overview() {
  await requirePlatformAdmin();
  const { locale, t } = await getMessages();
  const p = t.platform;
  const supabase = await createClient();
  const [{ data, error }, health] = await Promise.all([supabase.rpc("platform_overview"), supabase.rpc("platform_schools")]);
  const attention = needingAttention(parseSchoolRows(health.data));

  if (error) {
    return (
      <>
        <PageHeader title={p.title} subtitle={p.subtitle} />
        <Notice tone="bad">{t.overview.loadError}</Notice>
      </>
    );
  }

  const { totals, schools } = parsePlatformOverview(data);
  const url = supabaseConfig().url;

  return (
    <>
      <PageHeader title={p.title} subtitle={p.subtitle} />

      <section aria-label={p.title} className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Figure
          icon={School01Icon}
          title={p.totals.schools}
          value={totals.schoolsActive}
          hint={format(p.totals.schoolsHint, { active: totals.schoolsActive, inactive: totals.schoolsInactive })}
          testId="platform-schools"
        />
        <Figure
          icon={UserMultiple02Icon}
          title={p.totals.people}
          value={totals.students + totals.staff + totals.admins}
          hint={format(p.totals.peopleHint, { students: totals.students, staff: totals.staff, admins: totals.admins })}
          testId="platform-people"
        />
        <Figure
          icon={UserAdd01Icon}
          title={p.totals.newAccounts}
          value={totals.newAccounts30d}
          hint={format(p.totals.newAccountsHint, { week: totals.newAccounts7d, month: totals.newAccounts30d })}
        />
        <Figure
          icon={Clock01Icon}
          title={p.totals.waiting}
          value={totals.pendingAccounts + totals.subscriptionsPending}
          hint={format(p.totals.waitingHint, { accounts: totals.pendingAccounts, subscriptions: totals.subscriptionsPending })}
        />
        <Figure
          icon={Ticket03Icon}
          title={p.totals.subscriptions}
          value={totals.subscriptionsApproved}
          hint={format(p.totals.subscriptionsHint, {
            approved: totals.subscriptionsApproved,
            pending: totals.subscriptionsPending,
            rejected: totals.subscriptionsRejected,
          })}
        />
        <Figure
          icon={Navigation03Icon}
          title={p.totals.today}
          value={totals.tripsScheduled + totals.tripsActive + totals.tripsCompleted}
          hint={format(p.totals.todayHint, {
            scheduled: totals.tripsScheduled,
            active: totals.tripsActive,
            completed: totals.tripsCompleted,
            cancelled: totals.tripsCancelled,
          })}
        />
        <Figure icon={ReceiptTextIcon} title={p.totals.scans} value={totals.scansToday} />
        <Figure icon={Bus01Icon} title={p.totals.live} value={totals.busesLive} />
      </section>

      <section aria-labelledby="platform-needs-title" className="flex flex-col gap-4" data-testid="platform-needs">
        <div className="flex flex-wrap items-baseline justify-between gap-x-4">
          <div>
            <h2 id="platform-needs-title" className="text-xl font-bold">
              {p.needs.title}
            </h2>
            <p className="text-sm text-muted">{p.needs.hint}</p>
          </div>
          <Link href="/platform/schools" className="text-sm font-semibold text-link no-underline hover:text-fg">
            {p.needs.all}
          </Link>
        </div>
        {health.error ? (
          <Notice tone="bad">{p.list.loadError}</Notice>
        ) : attention.length === 0 ? (
          <Card className="p-6!">
            <p className="m-0 text-sm text-muted">{p.needs.none}</p>
          </Card>
        ) : (
          <ul className="m-0 grid list-none gap-4 p-0 md:grid-cols-2">
            {attention.slice(0, 6).map((school) => (
              <li key={school.id}>
                <Link href={`/platform/schools/${school.id}`} className="group block h-full no-underline">
                  <Card className="flex h-full flex-col gap-3 p-6! text-fg transition-transform duration-(--dur) ease-soft group-hover:-translate-y-0.5 motion-reduce:transition-none">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                      <span className="text-lg font-bold">{school.name}</span>
                      <LevelChip level={school.level} labels={p.levels} />
                    </div>
                    <ul className="m-0 flex list-disc flex-col gap-1 pl-5 text-sm">
                      {school.reasons.slice(0, 3).map((reason) => (
                        <li key={reason.signal}>{signalSentence(reason, p.health, locale)}</li>
                      ))}
                    </ul>
                  </Card>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section aria-labelledby="platform-schools-title" className="flex flex-col gap-4">
        <div>
          <h2 id="platform-schools-title" className="text-xl font-bold">
            {p.schools.title}
          </h2>
          <p className="text-sm text-muted">{p.schools.hint}</p>
        </div>
        {schools.length === 0 ? (
          <EmptyState title={p.schools.empty} />
        ) : (
          <TableCard>
            <DataTable minWidth="48rem">
              <Head>
                <Th>{p.schools.school}</Th>
                <Th>{p.schools.people}</Th>
                <Th>{p.schools.waiting}</Th>
                <Th>{p.schools.lastAction}</Th>
              </Head>
              <tbody>
                {schools.map((school) => (
                  <Tr key={school.id}>
                    <Td>
                      <div className="flex items-center gap-3">
                        <SchoolLogo
                          url={logoUrl(school.logoPath, url)}
                          fallback={<Icon icon={School01Icon} size={22} className="text-brand" />}
                        />
                        <div className="min-w-0">
                          <Link href={`/platform/schools/${school.id}`} className="font-semibold text-fg no-underline hover:text-link">
                            {school.name}
                          </Link>
                          <div className="mt-1 flex flex-wrap gap-1.5">
                            {school.active ? null : <Chip tone="warn">{p.schools.switchedOff}</Chip>}
                            {school.tripsActive > 0 ? <Chip tone="info">{format(p.schools.running, { n: school.tripsActive })}</Chip> : null}
                          </div>
                        </div>
                      </div>
                    </Td>
                    <Td className="tabular-nums">
                      {format(p.schools.peopleValue, { students: school.students, staff: school.staff, admins: school.admins })}
                    </Td>
                    <Td className="tabular-nums">
                      {format(p.schools.waitingValue, { subscriptions: school.subscriptionsPending, joins: school.waitingToJoin })}
                    </Td>
                    <Td>{lastAction(school.lastAdminActionAt, p.schools)}</Td>
                  </Tr>
                ))}
              </tbody>
            </DataTable>
          </TableCard>
        )}
      </section>
    </>
  );
}
