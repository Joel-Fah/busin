import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { Bus01Icon, CloudIcon, DatabaseIcon, Notification03Icon, Route01Icon, Search01Icon, SmartPhone01Icon, UserMultiple02Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { requirePlatformAdmin } from "@/lib/auth";
import { format, type Messages } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { PLAN_LIMITS, bytesText, parseSystemHealth, pressure, scheduleText, type Pressure } from "@/lib/platform-system";
import { createClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Health" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function PlatformHealthPage() {
  return (
    <Suspense fallback={<ListSkeleton />}>
      <SystemHealthView />
    </Suspense>
  );
}

const BAR = ["bg-ok", "bg-warn", "bg-bad"] as const;
const TONE = ["ok", "warn", "bad"] as const;

/** "12 min ago", "3 h ago": when something last happened, roughly. */
function ago(iso: string, copy: Messages["platform"]["system"]["ago"], now = Date.now()): string {
  const minutes = Math.max(0, Math.round((now - Date.parse(iso)) / 60_000));
  if (minutes < 1) return copy.now;
  if (minutes < 60) return format(copy.minutes, { n: minutes });
  if (minutes < 48 * 60) return format(copy.hours, { n: Math.round(minutes / 60) });
  return format(copy.days, { n: Math.round(minutes / 1440) });
}

/** One plan limit: what it is, how much is used of it, and a bar in the colour of how close it is. */
function Meter(props: { icon: IconSvgElement; title: string; hint?: string; used: string; limit: string; share: number; level: Pressure; labels: Messages["platform"]["system"]; testId: string }) {
  const { icon, title, hint, used, limit, share, level, labels, testId } = props;
  const percent = Math.min(100, Math.round(share * 100));
  return (
    <div data-testid={testId} data-pressure={level}>
      <Card className="flex h-full flex-col gap-3 p-6!">
        <div className="flex items-start justify-between gap-2">
          <div className="flex items-center gap-2 text-sm font-semibold text-muted">
            <Icon icon={icon} size={18} />
            <h3 className="m-0 text-sm font-semibold">{title}</h3>
          </div>
          <Chip tone={TONE[level]}>{labels.pressure[level]}</Chip>
        </div>
        <p className="m-0 text-2xl font-extrabold tracking-tight tabular-nums">{format(labels.percent, { n: percent })}</p>
        <div className="h-2 overflow-hidden rounded-full bg-surface-2" role="meter" aria-valuemin={0} aria-valuemax={100} aria-valuenow={percent} aria-label={title}>
          <div className={`h-full rounded-full ${BAR[level]}`} style={{ width: `${Math.max(2, percent)}%` }} />
        </div>
        <p className="m-0 text-xs text-muted tabular-nums">
          {format(labels.used, { used, limit })}
          {hint ? ` · ${hint}` : ""}
        </p>
      </Card>
    </div>
  );
}

/** A small card of "number label" pairs. */
function Counts({ icon, title, parts, note }: { icon: IconSvgElement; title: string; parts: [number, string][]; note?: string | null }) {
  return (
    <Card className="flex h-full flex-col gap-3 p-6!">
      <div className="flex items-center gap-2 text-sm font-semibold text-muted">
        <Icon icon={icon} size={18} />
        <h3 className="m-0 text-sm font-semibold">{title}</h3>
      </div>
      <ul className="m-0 flex list-none flex-wrap gap-x-5 gap-y-2 p-0">
        {parts.map(([n, label]) => (
          <li key={label} className="flex flex-col">
            <strong className="text-2xl font-extrabold tabular-nums">{n}</strong>
            <span className="text-xs text-muted">{label}</span>
          </li>
        ))}
      </ul>
      {note ? <p className="m-0 text-xs text-muted">{note}</p> : null}
    </Card>
  );
}

async function SystemHealthView() {
  await requirePlatformAdmin();
  const { locale, t } = await getMessages();
  const s = t.platform.system;
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("platform_system_health");
  const help = {
    label: t.help.open,
    title: s.help.title,
    intro: s.help.intro,
    scenarios: Object.values(s.help.scenarios),
    scenariosLabel: t.help.scenarios,
    closeLabel: t.help.close,
  };
  if (error) {
    return (
      <>
        <PageHeader title={s.title} help={help} />
        <Notice tone="bad">{s.loadError}</Notice>
      </>
    );
  }
  const h = parseSystemHealth(data);
  const n = (value: number) => new Intl.NumberFormat(locale === "fr" ? "fr-FR" : "en-GB").format(value);
  const timeOf = (iso: string) => new Intl.DateTimeFormat(locale, { hour: "2-digit", minute: "2-digit" }).format(new Date(iso));

  return (
    <>
      <PageHeader title={s.title} help={help} />

      <section aria-labelledby="limits" className="flex flex-col gap-3">
        <h2 id="limits" className="text-xl font-bold">
          {s.limits}
        </h2>
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <Meter
            testId="limit-database"
            icon={DatabaseIcon}
            title={s.database}
            used={bytesText(h.databaseBytes, locale)}
            limit={bytesText(PLAN_LIMITS.databaseBytes, locale)}
            share={h.databaseBytes / PLAN_LIMITS.databaseBytes}
            level={pressure(h.databaseBytes, PLAN_LIMITS.databaseBytes)}
            labels={s}
          />
          <Meter
            testId="limit-storage"
            icon={CloudIcon}
            title={s.storage}
            used={bytesText(h.storageBytes, locale)}
            limit={bytesText(PLAN_LIMITS.storageBytes, locale)}
            share={h.storageBytes / PLAN_LIMITS.storageBytes}
            level={pressure(h.storageBytes, PLAN_LIMITS.storageBytes)}
            labels={s}
          />
          <Meter
            testId="limit-accounts"
            icon={UserMultiple02Icon}
            title={s.accounts}
            hint={s.accountsHint}
            used={n(h.accounts.active30d)}
            limit={n(PLAN_LIMITS.activeAccounts)}
            share={h.accounts.active30d / PLAN_LIMITS.activeAccounts}
            level={pressure(h.accounts.active30d, PLAN_LIMITS.activeAccounts)}
            labels={s}
          />
          <Meter
            testId="limit-directions"
            icon={Route01Icon}
            title={s.directions}
            hint={s.directionsHint}
            used={n(h.usage.directionsMonth)}
            limit={n(PLAN_LIMITS.directionsPerMonth)}
            share={h.usage.directionsMonth / PLAN_LIMITS.directionsPerMonth}
            level={pressure(h.usage.directionsMonth, PLAN_LIMITS.directionsPerMonth)}
            labels={s}
          />
        </div>
        {h.storage.length > 0 ? (
          <details className="text-sm">
            <summary className="cursor-pointer font-semibold text-link">{s.buckets}</summary>
            <ul className="m-0 mt-2 flex list-none flex-wrap gap-2 p-0">
              {h.storage.map((b) => (
                <li key={b.bucket} className="rounded-md bg-surface px-3 py-2 shadow-soft">
                  <span className="font-semibold">{b.bucket}</span>{" "}
                  <span className="text-muted tabular-nums">
                    {bytesText(b.bytes, locale)} · {format(s.files, { n: b.files })}
                  </span>
                </li>
              ))}
            </ul>
          </details>
        ) : null}
      </section>

      <section aria-labelledby="jobs" className="flex flex-col gap-3">
        <h2 id="jobs" className="text-xl font-bold">
          {s.jobs}
        </h2>
        <Card className="p-2!">
          <ul className="m-0 flex list-none flex-col p-0" data-testid="jobs">
            {h.jobs.map((job) => {
              const failed = job.lastStatus === "failed";
              const name = (s.jobNames as Record<string, string>)[job.name] ?? job.name;
              return (
                <li key={job.name} data-job={job.name} className="flex flex-wrap items-center justify-between gap-3 border-b border-line px-4 py-3 last:border-0">
                  <div className="min-w-0">
                    <p className="m-0 font-semibold">{name}</p>
                    <p className="m-0 text-xs text-muted">
                      {scheduleText(job.schedule, s.schedule)} · {job.lastRunAt ? format(s.lastRun, { when: ago(job.lastRunAt, s.ago) }) : s.neverRan}
                    </p>
                  </div>
                  <div className="flex flex-wrap items-center gap-2">
                    {job.failures7d > 0 ? (
                      <span tabIndex={0} data-tip={job.lastError ?? undefined} className="text-xs text-muted focus-visible:outline-3 focus-visible:outline-focus">
                        {format(s.failures, { n: job.failures7d })}
                      </span>
                    ) : null}
                    <Chip tone={!job.active ? "neutral" : failed ? "bad" : "ok"}>{!job.active ? s.paused : failed ? s.failed : s.ok}</Chip>
                  </div>
                </li>
              );
            })}
          </ul>
        </Card>
      </section>

      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <div data-testid="push">
          <Counts
            icon={Notification03Icon}
            title={s.push}
            parts={[
              [h.push.sent7d, s.sent],
              [h.push.failed7d, s.failedPush],
              [h.push.waiting, s.waiting],
            ]}
            note={h.push.oldestWaitingAt ? format(s.oldestWaiting, { when: ago(h.push.oldestWaitingAt, s.ago) }) : null}
          />
        </div>
        <Counts
          icon={SmartPhone01Icon}
          title={s.phones}
          parts={[
            [h.devices.android, s.android],
            [h.devices.ios, s.ios],
            [h.devices.web, s.web],
            [h.devices.stale30d, s.stale],
          ]}
        />
        <Counts icon={Search01Icon} title={s.searches} parts={[[h.usage.placeSearchesMonth, s.searchesHint]]} />
      </section>

      <section aria-labelledby="quiet" className="flex flex-col gap-3" data-testid="quiet-trips">
        <div>
          <h2 id="quiet" className="text-xl font-bold">
            {s.quiet}
          </h2>
          <p className="text-sm text-muted">{s.quietHint}</p>
        </div>
        {h.quietTrips.length === 0 ? (
          <Card className="p-6!">
            <p className="m-0 text-sm text-muted">{s.quietNone}</p>
          </Card>
        ) : (
          <ul className="m-0 grid list-none gap-3 p-0 sm:grid-cols-2">
            {h.quietTrips.map((trip, index) => (
              <li key={`${trip.schoolId}-${index}`}>
                <Card className="flex items-center gap-3 p-5!">
                  <span className="grid size-10 shrink-0 place-items-center rounded-md bg-warn-bg text-warn">
                    <Icon icon={Bus01Icon} size={20} />
                  </span>
                  <div className="min-w-0">
                    <Link href={`/platform/schools/${trip.schoolId}`} className="font-semibold text-fg no-underline hover:text-link">
                      {trip.school}
                    </Link>
                    <p className="m-0 text-xs text-muted">
                      {format(s.quietSince, { when: timeOf(trip.startedAt), last: trip.lastPositionAt ? ago(trip.lastPositionAt, s.ago) : s.noPosition })}
                    </p>
                  </div>
                </Card>
              </li>
            ))}
          </ul>
        )}
      </section>
    </>
  );
}
