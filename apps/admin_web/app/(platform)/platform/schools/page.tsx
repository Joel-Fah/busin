import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { PlusSignIcon, School01Icon } from "@hugeicons/core-free-icons";

import { LevelChip } from "@/components/platform/LevelChip";
import { SignalChip } from "@/components/platform/SignalChip";
import { SchoolLogo } from "@/components/SchoolLogo";
import { ButtonLink } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Icon } from "@/components/ui/Icon";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { StickyToolbar } from "@/components/ui/StickyToolbar";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";
import { Tabs, type TabItem } from "@/components/ui/Tabs";
import { requirePlatformAdmin } from "@/lib/auth";
import { supabaseConfig } from "@/lib/env";
import { format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { daysSince } from "@/lib/platform-overview";
import { LEVEL_KEYS, LEVEL_TONES, contactedText, levelCounts, levelFromParam, parseSchoolRows } from "@/lib/platform-health";
import { logoUrl } from "@/lib/school";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Schools" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ level?: string | string[] }>;

export default function PlatformSchoolsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <Schools searchParams={searchParams} />
    </Suspense>
  );
}

async function Schools({ searchParams }: { searchParams: SearchParams }) {
  await requirePlatformAdmin();
  const { locale, t } = await getMessages();
  const p = t.platform;
  const level = levelFromParam((await searchParams).level);
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("platform_schools");
  const all = parseSchoolRows(data);
  const rows = level === null ? all : all.filter((row) => row.level === level);
  const { byLevel } = levelCounts(all);
  const url = supabaseConfig().url;

  // Worst first, as the list is sorted.
  const tabs: TabItem[] = [
    { id: "all", label: p.list.all, href: "/platform/schools", count: all.length },
    ...([3, 2, 1, 0] as const).map((l) => ({
      id: LEVEL_KEYS[l],
      label: p.levels[LEVEL_KEYS[l]],
      href: `/platform/schools?level=${LEVEL_KEYS[l]}`,
      count: byLevel[l],
      tone: byLevel[l] > 0 ? LEVEL_TONES[l] : undefined,
    })),
  ];

  const lastAction = (iso: string | null) => {
    const days = daysSince(iso);
    if (days === null) return p.schools.never;
    if (days === 0) return p.schools.today;
    if (days === 1) return p.schools.oneDayAgo;
    return format(p.schools.daysAgo, { n: days });
  };

  return (
    <>
      <PageHeader
        title={p.list.title}
        action={
          <ButtonLink href="/platform/schools/new" icon={PlusSignIcon}>
            {p.onboarding.newSchool}
          </ButtonLink>
        }
        help={{
          label: t.help.open,
          title: p.help.schools.title,
          intro: p.help.schools.intro,
          scenarios: Object.values(p.help.schools.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
      />
      <StickyToolbar>
        <Tabs label={p.list.filterLabel} items={tabs} active={level === null ? "all" : LEVEL_KEYS[level]} />
      </StickyToolbar>

      {error ? (
        <Notice tone="bad">{p.list.loadError}</Notice>
      ) : rows.length === 0 ? (
        <EmptyState title={p.list.empty} />
      ) : (
        <TableCard>
          <DataTable minWidth="56rem">
            <Head>
              <Th>{p.schools.school}</Th>
              <Th>{p.list.level}</Th>
              <Th>{p.list.reasons}</Th>
              <Th>{p.list.people}</Th>
              <Th>{p.list.lastAction}</Th>
            </Head>
            <tbody>
              {rows.map((row) => (
                <Tr key={row.id}>
                  <Td>
                    <Link
                      href={`/platform/schools/${row.id}`}
                      aria-label={format(p.list.open, { school: row.name })}
                      className="flex items-center gap-3 rounded-sm text-fg no-underline focus-visible:outline-3 focus-visible:outline-focus"
                    >
                      <SchoolLogo url={logoUrl(row.logoPath, url)} fallback={<Icon icon={School01Icon} size={22} className="text-brand" />} />
                      <span className="font-semibold">{row.name}</span>
                    </Link>
                  </Td>
                  <Td>
                    <div className="flex flex-col items-start gap-1">
                      <LevelChip level={row.level} labels={p.levels} />
                      {row.score !== null ? <span className="text-xs text-muted tabular-nums">{format(p.school.score, { score: row.score })}</span> : null}
                    </div>
                  </Td>
                  <Td className="max-w-md">
                    {row.reasons.length === 0 ? (
                      <span className="text-muted">{p.list.noReason}</span>
                    ) : (
                      <div className="flex flex-wrap gap-1.5">
                        {row.reasons.slice(0, 3).map((reason) => (
                          <SignalChip key={reason.signal} signal={reason} copy={p.health} locale={locale} paused={Boolean(row.snoozed[reason.signal])} />
                        ))}
                      </div>
                    )}
                    {row.lastOutreachAt ? <p className="m-0 mt-1 text-xs text-muted">{contactedText(row.lastOutreachAt, p.outreach)}</p> : null}
                  </Td>
                  <Td className="tabular-nums">{format(p.list.peopleValue, { students: row.students, staff: row.staff })}</Td>
                  <Td>{lastAction(row.lastAdminActionAt)}</Td>
                </Tr>
              ))}
            </tbody>
          </DataTable>
        </TableCard>
      )}
    </>
  );
}
