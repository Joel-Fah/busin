import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import { Megaphone01Icon, School01Icon } from "@hugeicons/core-free-icons";

import { FlashToast } from "@/components/FlashToast";
import { HealthTrend } from "@/components/platform/HealthTrend";
import { LevelChip } from "@/components/platform/LevelChip";
import { OutreachHistory } from "@/components/platform/OutreachHistory";
import { ReachOut } from "@/components/platform/ReachOut";
import { SchoolLogo } from "@/components/SchoolLogo";
import { BackLink } from "@/components/ui/BackLink";
import { ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { StickyHeader } from "@/components/ui/StickyHeader";
import { requirePlatformAdmin } from "@/lib/auth";
import { supabaseConfig } from "@/lib/env";
import { en, fr, format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { siteUrl } from "@/lib/landing/site";
import { AREAS, parseSchoolDetail, signalSentence, thresholdsText } from "@/lib/platform-health";
import { messageCopy, parseContacts, parseSchoolOutreach } from "@/lib/platform-outreach";
import { isOutreachDone, isOutreachError } from "@/lib/platform-outreach-errors";
import { logoUrl } from "@/lib/school";
import { createClient } from "@/lib/supabase/server";

import { completeFollowUp, logOutreach, sendNotice } from "./actions";

export const metadata: Metadata = { title: "School" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

const first = (value: string | string[] | undefined) => (Array.isArray(value) ? value[0] : value);

export default function PlatformSchoolPage({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <School params={params} searchParams={searchParams} />
    </Suspense>
  );
}

async function School({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  await requirePlatformAdmin();
  const { id } = await params;
  if (!isUuid(id)) notFound();
  const query = await searchParams;
  const done = first(query.done);
  const failed = first(query.error);
  const { locale, t } = await getMessages();
  const p = t.platform;
  const supabase = await createClient();
  const [{ data, error }, contactsResult, outreachResult] = await Promise.all([
    supabase.rpc("platform_school", { p_school_id: id }),
    // Each view of the contacts is recorded in the platform audit (ADR 0027).
    supabase.rpc("platform_school_contacts", { p_school_id: id }),
    supabase.rpc("platform_school_outreach", { p_school_id: id }),
  ]);
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
  const dayOf = (iso: string) => new Intl.DateTimeFormat(locale, { day: "numeric", month: "long", timeZone: "UTC" }).format(new Date(`${iso.slice(0, 10)}T00:00:00Z`));
  const o = p.outreach;
  const contacts = parseContacts(contactsResult.data, { school: o.schoolLabel, admin: o.adminLabel });
  const outreach = parseSchoolOutreach(outreachResult.data);
  const snoozed = Object.fromEntries(Object.entries(outreach.snoozed).map(([signal, s]) => [signal, dayOf(s.until)]));
  // What a message may be about: the signals at Watch or worse, and any paused ones (they may still need a word).
  const talkable = school.signals.filter((s) => (s.value !== null && s.level > 0) || outreach.snoozed[s.signal]);
  const today = new Date().toISOString().slice(0, 10);

  return (
    <>
      {isOutreachDone(done) ? <FlashToast message={o.done[done]} /> : null}
      <BackLink href="/platform/schools">{p.school.back}</BackLink>

      <StickyHeader
        media={<SchoolLogo url={logoUrl(school.logoPath, supabaseConfig().url)} size="lg" className="shadow-soft" fallback={<Icon icon={School01Icon} size={32} className="text-brand" />} />}
        title={<h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">{school.name}</h1>}
        meta={
          <>
            <LevelChip level={school.level} labels={p.levels} />
            {school.score !== null ? <span className="text-sm text-muted tabular-nums">{format(p.school.score, { score: school.score })}</span> : null}
          </>
        }
        extra={school.createdAt ? <span className="text-sm text-muted">{format(p.school.created, { date: dateOf(school.createdAt) })}</span> : null}
        action={
          school.active ? (
            <ButtonLink href="#reach-out" variant="secondary" icon={Megaphone01Icon}>
              {o.jump}
            </ButtonLink>
          ) : null
        }
      />

      {isOutreachError(failed) ? <Notice tone="bad">{o.errors[failed]}</Notice> : null}

      {school.active ? null : <Notice tone="warn">{p.school.off}</Notice>}

      <div className="grid grid-cols-[minmax(0,1fr)] gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,22rem)]">
        <section aria-labelledby="signals" className="flex min-w-0 flex-col gap-4">
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
                        {snoozed[signal.signal] ? (
                          <p className="m-0 text-xs font-semibold text-muted" data-testid="signal-paused">
                            {format(o.paused, { date: snoozed[signal.signal] })}
                          </p>
                        ) : null}
                      </div>
                      <LevelChip level={signal.value === null ? 0 : signal.level} labels={p.levels} />
                    </li>
                  ))}
                </ul>
              </Card>
            );
          })}

          {school.active ? (
            // Clear of the sticky header when the "Reach out" button scrolls here.
            <Card className="scroll-mt-32 p-6!">
              <section id="reach-out" aria-labelledby="reach-out-title" className="scroll-mt-32">
                <h2 id="reach-out-title" className="text-xl font-bold">
                  {o.title}
                </h2>
                <p className="mb-5 text-sm text-muted">{o.hint}</p>
                <ReachOut
                  schoolId={school.id}
                  schoolName={school.name}
                  siteUrl={siteUrl()}
                  signals={talkable}
                  snoozed={snoozed}
                  contacts={contacts}
                  copy={{ en: messageCopy(en), fr: messageCopy(fr) }}
                  language={locale}
                  text={o}
                  titles={Object.fromEntries(Object.entries(p.health.signals).map(([key, c]) => [key, c.title]))}
                  dateText={t.pickers.date}
                  today={today}
                  sendNotice={sendNotice}
                  logOutreach={logOutreach}
                />
              </section>
            </Card>
          ) : null}
        </section>

        <aside className="flex min-w-0 flex-col gap-6">
          <Card className="p-6!">
            <h2 className="mb-3 text-base font-bold">{o.history}</h2>
            <OutreachHistory
              entries={outreach.log}
              schoolId={school.id}
              locale={locale}
              text={o}
              titles={Object.fromEntries(Object.entries(p.health.signals).map(([key, c]) => [key, c.title]))}
              completeFollowUp={completeFollowUp}
            />
          </Card>
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
