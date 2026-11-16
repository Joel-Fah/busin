import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { School01Icon } from "@hugeicons/core-free-icons";

import { HealthTrend } from "@/components/platform/HealthTrend";
import { LevelChip } from "@/components/platform/LevelChip";
import { SchoolLogo } from "@/components/SchoolLogo";
import { BackLink } from "@/components/ui/BackLink";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { requirePlatformAdmin } from "@/lib/auth";
import { supabaseConfig } from "@/lib/env";
import { format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { AREAS, parseSchoolDetail, signalSentence, thresholdsText } from "@/lib/platform-health";
import { logoUrl } from "@/lib/school";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "School" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;

export default function PlatformSchoolPage({ params }: { params: Params }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <School params={params} />
    </Suspense>
  );
}

async function School({ params }: { params: Params }) {
  await requirePlatformAdmin();
  const { id } = await params;
  if (!isUuid(id)) notFound();
  const { locale, t } = await getMessages();
  const p = t.platform;
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("platform_school", { p_school_id: id });
  if (error) {
    return (
      <>
        <BackLink href="/platform/schools">{p.school.back}</BackLink>
        <Notice tone="bad">{p.list.loadError}</Notice>
      </>
    );
  }
  const school = parseSchoolDetail(data);
  if (!school) notFound();

  const dateOf = (iso: string) => new Intl.DateTimeFormat(locale, { day: "numeric", month: "long", year: "numeric" }).format(new Date(iso));
  const timeOf = (iso: string) => new Intl.DateTimeFormat(locale, { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }).format(new Date(iso));

  return (
    <>
      <BackLink href="/platform/schools">{p.school.back}</BackLink>

      <header className="flex flex-wrap items-center gap-5">
        <SchoolLogo url={logoUrl(school.logoPath, supabaseConfig().url)} size="lg" className="shadow-soft" fallback={<Icon icon={School01Icon} size={32} className="text-brand" />} />
        <div className="min-w-0">
          <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">{school.name}</h1>
          <div className="mt-2 flex flex-wrap items-center gap-2">
            <LevelChip level={school.level} labels={p.levels} />
            {school.score !== null ? <span className="text-sm text-muted tabular-nums">{format(p.school.score, { score: school.score })}</span> : null}
            {school.createdAt ? <span className="text-sm text-muted">{format(p.school.created, { date: dateOf(school.createdAt) })}</span> : null}
          </div>
        </div>
      </header>

      {school.active ? null : <Notice tone="warn">{p.school.off}</Notice>}

      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,22rem)]">
        <section aria-labelledby="signals" className="flex flex-col gap-4">
          <div>
            <h2 id="signals" className="text-xl font-bold">
              {p.school.signals}
            </h2>
            <p className="text-sm text-muted">{p.school.signalsHint}</p>
          </div>
          {AREAS.map((area) => {
            const signals = school.signals.filter((s) => s.area === area);
            if (signals.length === 0) return null;
            return (
              <Card key={area} className="p-6!">
                <h3 className="mb-3 text-base font-bold">{p.areas[area]}</h3>
                <ul className="m-0 flex list-none flex-col gap-4 p-0">
                  {signals.map((signal) => (
                    <li key={signal.signal} data-testid={`signal-${signal.signal}`} className="flex flex-wrap items-start justify-between gap-x-4 gap-y-1">
                      <div className="min-w-0 flex-1">
                        <p className="m-0 font-semibold">{p.health.signals[signal.signal].title}</p>
                        <p className="m-0 text-sm">{signalSentence(signal, p.health, locale)}</p>
                        <p className="m-0 text-xs text-muted">{thresholdsText(signal, p.health, locale)}</p>
                        {signal.graced ? <p className="m-0 text-xs text-muted">{p.health.graced}</p> : null}
                      </div>
                      <LevelChip level={signal.value === null ? 0 : signal.level} labels={p.levels} />
                    </li>
                  ))}
                </ul>
              </Card>
            );
          })}
        </section>

        <aside className="flex flex-col gap-6">
          <Card className="p-6!">
            <h2 className="text-base font-bold">{p.school.trend}</h2>
            <p className="mb-4 text-sm text-muted">{p.school.trendHint}</p>
            {school.history.length === 0 ? (
              <p className="m-0 text-sm text-muted">{p.school.trendEmpty}</p>
            ) : (
              <HealthTrend
                history={school.history}
                locale={locale}
                label={p.school.trend}
                levels={p.levels}
                dayLabel={(day, level, score) => format(p.school.trendDay, { day, level, score })}
              />
            )}
          </Card>

          <Card className="p-6!">
            <h2 className="mb-3 text-base font-bold">{p.school.details}</h2>
            <dl className="m-0 grid gap-3 text-sm">
              <div>
                <dt className="text-muted">{p.list.people}</dt>
                <dd className="m-0 font-semibold tabular-nums">
                  {format(p.schools.peopleValue, { students: school.counts.students, staff: school.counts.staff, admins: school.counts.admins })}
                </dd>
              </div>
              <div>
                <dt className="text-muted">{p.school.domains}</dt>
                <dd className="m-0 mt-1 flex flex-wrap gap-1.5">
                  {school.domains.length === 0 ? <span className="font-semibold">{p.school.noDomains}</span> : school.domains.map((d) => <Chip key={d}>{d}</Chip>)}
                </dd>
              </div>
              <div>
                <dt className="text-muted">{p.school.openSignup}</dt>
                <dd className="m-0 font-semibold">{school.acceptsOpenSignup ? p.school.yes : p.school.no}</dd>
              </div>
              <div>
                <dt className="text-muted">{p.school.listed}</dt>
                <dd className="m-0 font-semibold">{school.publicListing ? p.school.yes : p.school.no}</dd>
              </div>
              {school.timezone ? (
                <div>
                  <dt className="text-muted">{p.school.timezone}</dt>
                  <dd className="m-0 font-semibold">{school.timezone}</dd>
                </div>
              ) : null}
            </dl>
          </Card>

          <Card className="p-6!">
            <h2 className="text-base font-bold">{p.school.actions}</h2>
            <p className="mb-3 text-sm text-muted">{p.school.actionsHint}</p>
            {school.adminActions.length === 0 ? (
              <p className="m-0 text-sm text-muted">{p.school.noActions}</p>
            ) : (
              <ul className="m-0 flex list-none flex-col gap-2 p-0 text-sm">
                {school.adminActions.map((a, index) => (
                  <li key={`${a.at}-${index}`} className="flex justify-between gap-3">
                    <code className="truncate text-xs">{a.action}</code>
                    <span className="shrink-0 text-muted tabular-nums">{timeOf(a.at)}</span>
                  </li>
                ))}
              </ul>
            )}
          </Card>
        </aside>
      </div>
    </>
  );
}
