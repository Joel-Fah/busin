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
  Tick02Icon,
  InboxIcon,
  ArrowRight01Icon,
} from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { FlashToast } from "@/components/FlashToast";
import { LevelChip } from "@/components/platform/LevelChip";
import { SignalChip } from "@/components/platform/SignalChip";
import { SchoolLogo } from "@/components/SchoolLogo";
import { Button } from "@/components/ui/Button";
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
import { contactedText, needingAttention, parseSchoolRows } from "@/lib/platform-health";
import { isChannel } from "@/lib/platform-outreach";
import { parseLeadCounts } from "@/lib/platform-leads";
import { daysSince, parsePlatformOverview } from "@/lib/platform-overview";
import { logoUrl } from "@/lib/school";
import { createClient } from "@/lib/supabase/server";

import { completeFollowUp } from "./schools/[id]/actions";

export const metadata: Metadata = { title: "Platform" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ done?: string | string[] }>;

export default function PlatformOverviewPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<OverviewSkeleton />}>
      <Overview searchParams={searchParams} />
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

/** One figure with its icon and title, and its breakdown as short "number label" pairs instead of a sentence. */
function Figure({ icon, title, value, parts = [], testId }: { icon: IconSvgElement; title: string; value: number; parts?: [number, string][]; testId?: string }) {
  return (
    <div data-testid={testId}>
      <Card className="flex h-full flex-col gap-3 p-6!">
        <div className="flex items-center gap-2 text-sm font-semibold text-muted">
          <Icon icon={icon} size={18} />
          <h2 className="m-0 text-sm font-semibold">{title}</h2>
        </div>
        <p className="m-0 text-3xl font-extrabold tracking-tight tabular-nums">{value}</p>
        {parts.length > 0 ? (
          <ul className="m-0 flex list-none flex-wrap gap-x-3 gap-y-1 p-0 text-xs">
            {parts.map(([n, label]) => (
              <li key={label}>
                <strong className="font-bold tabular-nums">{n}</strong> <span className="text-muted">{label}</span>
              </li>
            ))}
          </ul>
        ) : null}
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

async function Overview({ searchParams }: { searchParams: SearchParams }) {
  await requirePlatformAdmin();
  const { locale, t } = await getMessages();
  const p = t.platform;
  const supabase = await createClient();
  const [{ data, error }, health, followUpsResult, leadCountsResult] = await Promise.all([
    supabase.rpc("platform_overview"),
    supabase.rpc("platform_schools"),
    supabase.rpc("platform_follow_ups"),
    supabase.rpc("platform_lead_counts"),
  ]);
  const newLeads = parseLeadCounts(leadCountsResult.data).get("school", "new");
  const attention = needingAttention(parseSchoolRows(health.data));
  const followUps = followUpsResult.data ?? [];
  const query = await searchParams;
  const done = Array.isArray(query.done) ? query.done[0] : query.done;

  if (error) {
    return (
      <>
        <PageHeader title={p.title} subtitle={p.subtitle} />
        <Notice tone="bad">{t.overview.loadError}</Notice>
      </>
    );
  }

  const { totals, schools } = parsePlatformOverview(data);
  const q = p.totals.parts;
  const help = {
    label: t.help.open,
    title: p.help.overview.title,
    intro: p.help.overview.intro,
    scenarios: Object.values(p.help.overview.scenarios),
    scenariosLabel: t.help.scenarios,
    closeLabel: t.help.close,
  };
  const url = supabaseConfig().url;

  return (
    <>
      {done === "followUp" ? <FlashToast message={p.outreach.done.followUp} /> : null}
      <PageHeader title={p.title} subtitle={p.subtitle} help={help} />

      <section aria-label={p.title} className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Figure
          icon={School01Icon}
          title={p.totals.schools}
          value={totals.schoolsActive}
          parts={[[totals.schoolsActive, q.active], [totals.schoolsInactive, q.off]]}
          testId="platform-schools"
        />
        <Figure
          icon={UserMultiple02Icon}
          title={p.totals.people}
          value={totals.students + totals.staff + totals.admins}
          parts={[[totals.students, q.students], [totals.staff, q.staff], [totals.admins, q.admins]]}
          testId="platform-people"
        />
        <Figure
          icon={UserAdd01Icon}
          title={p.totals.newAccounts}
          value={totals.newAccounts30d}
          parts={[[totals.newAccounts7d, q.week], [totals.newAccounts30d, q.month]]}
        />
        <Figure
          icon={Clock01Icon}
          title={p.totals.waiting}
          value={totals.pendingAccounts + totals.subscriptionsPending}
          parts={[[totals.pendingAccounts, q.toVerify], [totals.subscriptionsPending, q.requests]]}
        />
        <Figure
          icon={Ticket03Icon}
          title={p.totals.subscriptions}
          value={totals.subscriptionsApproved}
          parts={[[totals.subscriptionsApproved, q.approved], [totals.subscriptionsPending, q.waiting], [totals.subscriptionsRejected, q.refused]]}
        />
        <Figure
          icon={Navigation03Icon}
          title={p.totals.today}
          value={totals.tripsScheduled + totals.tripsActive + totals.tripsCompleted}
          parts={[[totals.tripsScheduled, q.toCome], [totals.tripsActive, q.running], [totals.tripsCompleted, q.done], [totals.tripsCancelled, q.cancelled]]}
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
            
          </div>
          <Link href="/platform/schools" className="text-sm font-semibold text-link no-underline hover:text-fg">
            {p.needs.all}
          </Link>
        </div>
        {newLeads > 0 ? (
          <Link
            href="/platform/leads?kind=school&status=new"
            data-testid="platform-new-leads"
            className="flex items-center justify-between gap-3 rounded-lg bg-surface px-6 py-4 font-semibold text-fg no-underline shadow-soft hover:text-link"
          >
            <span className="inline-flex items-center gap-2">
              <Icon icon={InboxIcon} size={20} />
              {format(p.leads.newLeads, { n: newLeads })}
            </span>
            <Icon icon={ArrowRight01Icon} size={18} />
          </Link>
        ) : null}
        {followUps.length > 0 ? (
          <div data-testid="platform-follow-ups">
          <Card className="p-6!">
            <h3 className="mb-3 text-base font-bold">{p.outreach.followUps}</h3>
            <ul className="m-0 flex list-none flex-col gap-3 p-0">
              {followUps.map((f) => (
                <li key={f.id} className="flex flex-wrap items-center justify-between gap-3 text-sm">
                  <div className="min-w-0">
                    <Link href={`/platform/schools/${f.school_id}`} className="font-semibold text-fg no-underline hover:text-link">
                      {f.school_name}
                    </Link>
                    <span className="text-muted"> · {p.outreach.channels[isChannel(f.channel) ? f.channel : "other"]}</span>
                    {f.note ? <p className="m-0 truncate text-muted">{f.note}</p> : null}
                  </div>
                  <form action={completeFollowUp}>
                    <input type="hidden" name="outreach" value={f.id} />
                    <Button type="submit" variant="secondary" icon={Tick02Icon}>
                      {p.outreach.markDone}
                    </Button>
                  </form>
                </li>
              ))}
            </ul>
          </Card>
          </div>
        ) : null}
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
                    <div className="flex flex-wrap gap-1.5">
                      {school.reasons.slice(0, 3).map((reason) => (
                        <SignalChip key={reason.signal} signal={reason} copy={p.health} locale={locale} paused={Boolean(school.snoozed[reason.signal])} />
                      ))}
                    </div>
                    {school.lastOutreachAt ? <p className="m-0 text-xs text-muted">{contactedText(school.lastOutreachAt, p.outreach)}</p> : null}
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
