import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import {
  Bus01Icon,
  Calendar02Icon,
  Clock01Icon,
  FlagTriangleRightIcon,
  Navigation03Icon,
  ReceiptTextIcon,
  Ticket03Icon,
  UserMultiple02Icon,
} from "@hugeicons/core-free-icons";

import { BoardingsChart } from "@/components/overview/BoardingsChart";
import { Welcome, type Insight } from "@/components/overview/Welcome";
import { StatusMix, type MixPart } from "@/components/overview/StatusMix";
import { Tile } from "@/components/overview/Tile";
import { Avatar } from "@/components/ui/Avatar";
import { Chip } from "@/components/ui/Chip";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Skeleton } from "@/components/ui/Skeleton";
import { requireAdmin } from "@/lib/auth";
import { format } from "@/lib/i18n/messages";
import { getMessages } from "@/lib/i18n/server";
import { firstName, greetingFor, semesterProgress, waitingAge, weekTrend, type DayCount } from "@/lib/overview";
import { STATUSES } from "@/lib/subscriptions";
import { createClient } from "@/lib/supabase/server";
import { startOfDayInTimeZone } from "@/lib/time";
import { tripStatusTone } from "@/lib/trips";

export const metadata: Metadata = { title: "Overview" };

// The figures depend on who is signed in, so this page cannot be an instant navigation.
export const instant = false;

function OverviewSkeleton() {
  return (
    <div aria-hidden className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {[0, 1, 2, 3].map((i) => (
        <Skeleton key={i} className="h-40 rounded-lg" />
      ))}
      <Skeleton className="h-72 rounded-lg sm:col-span-2" />
      <Skeleton className="h-72 rounded-lg" />
      <Skeleton className="h-72 rounded-lg" />
    </div>
  );
}

export default function OverviewPage() {
  return (
    <Suspense fallback={<OverviewSkeleton />}>
      <Overview />
    </Suspense>
  );
}

// Each figure leads to where its detail lives.
const DESTINATIONS = {
  pendingSubscriptions: { href: "/subscriptions", icon: Ticket03Icon },
  students: { href: "/people?role=student", icon: UserMultiple02Icon },
  activeTrips: { href: "/trips?status=active", icon: Navigation03Icon },
  scansToday: { href: "/scans", icon: ReceiptTextIcon },
} as const;

type Figure = { key: "pendingSubscriptions" | "students" | "activeTrips" | "scansToday"; value: number | null };

const STATUS_COLOR: Record<(typeof STATUSES)[number], string> = {
  pending: "var(--warn)",
  approved: "var(--ok)",
  rejected: "var(--bad)",
  revoked: "color-mix(in srgb, var(--bad) 55%, transparent)",
  expired: "color-mix(in srgb, var(--fg) 35%, transparent)",
};

async function Overview() {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const supabase = await createClient();
  const tiles = t.overview.tiles;

  const now = new Date();
  const startOfToday = startOfDayInTimeZone(admin.schoolTimezone, now);
  const endOfToday = startOfDayInTimeZone(admin.schoolTimezone, new Date(startOfToday.getTime() + 36 * 3_600_000));
  const todayIso = new Intl.DateTimeFormat("en-CA", { timeZone: admin.schoolTimezone }).format(now);

  // Counts, one small aggregate and a few capped lists: nothing here downloads a table. Row Level Security
  // limits every query to this school.
  const [students, activeTrips, scansToday, daily, busesTotal, busesInService, stops, semester, todaysTrips, waiting, ...byStatus] =
    await Promise.all([
      supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "student"),
      supabase.from("trips").select("id", { count: "exact", head: true }).eq("status", "active"),
      supabase.from("scans").select("id", { count: "exact", head: true }).gte("scanned_at", startOfToday.toISOString()),
      supabase.rpc("admin_boardings_by_day", { p_days: 14 }),
      supabase.from("buses").select("id", { count: "exact", head: true }),
      supabase.from("buses").select("id", { count: "exact", head: true }).eq("in_service", true),
      supabase.from("stops").select("id", { count: "exact", head: true }),
      supabase.from("semesters").select("name, year, start_date, end_date").lte("start_date", todayIso).gte("end_date", todayIso).order("start_date", { ascending: false }).limit(1),
      supabase
        .from("trips")
        .select("id, direction, status, scheduled_start, bus_id, driver_id", { count: "exact" })
        .is("archived_at", null)
        .gte("scheduled_start", startOfToday.toISOString())
        .lt("scheduled_start", endOfToday.toISOString())
        .order("scheduled_start", { ascending: true })
        .limit(6),
      supabase
        .from("subscriptions")
        .select("id, created_at, student_id")
        .eq("status", "pending")
        .order("created_at", { ascending: true })
        .limit(5),
      ...STATUSES.map((status) => supabase.from("subscriptions").select("id", { count: "exact", head: true }).eq("status", status)),
    ]);

  // Names for the short lists, fetched together for just the ids shown.
  const busIds = [...new Set((todaysTrips.data ?? []).map((trip) => trip.bus_id))];
  const personIds = [
    ...new Set([
      ...(todaysTrips.data ?? []).flatMap((trip) => (trip.driver_id ? [trip.driver_id] : [])),
      ...(waiting.data ?? []).map((row) => row.student_id),
    ]),
  ];
  const [busRows, personRows] = await Promise.all([
    busIds.length ? supabase.from("buses").select("id, plate").in("id", busIds) : { data: [], error: null },
    personIds.length ? supabase.from("profiles").select("id, full_name, email, matricule").in("id", personIds) : { data: [], error: null },
  ]);
  const plateOf = new Map((busRows.data ?? []).map((bus) => [bus.id, bus.plate]));
  const personOf = new Map((personRows.data ?? []).map((person) => [person.id, person]));
  const nameOf = (id: string | null) => {
    const person = id ? personOf.get(id) : undefined;
    return person?.full_name || person?.email || "";
  };

  const failed = [students, activeTrips, scansToday, daily, busesTotal, busesInService, stops, semester, todaysTrips, waiting, busRows, personRows, ...byStatus].some(
    (result) => result.error,
  );

  const counts = Object.fromEntries(STATUSES.map((status, index) => [status, byStatus[index].count ?? 0])) as Record<(typeof STATUSES)[number], number>;
  const figures: Figure[] = [
    { key: "pendingSubscriptions", value: counts.pending },
    { key: "students", value: students.count },
    { key: "activeTrips", value: activeTrips.count },
    { key: "scansToday", value: scansToday.count },
  ];

  const days: DayCount[] = (daily.data ?? []).map((row) => ({ day: row.day, boardings: row.boardings }));
  const trend = weekTrend(days);
  const fourteenTotal = days.reduce((total, d) => total + d.boardings, 0);
  const trendText =
    trend.change === null
      ? tiles.trendNone
      : trend.change === 0
        ? tiles.trendSame
        : format(trend.change > 0 ? tiles.trendUp : tiles.trendDown, { percent: Math.abs(trend.change) });

  const mix: MixPart[] = STATUSES.map((status) => ({
    key: status,
    label: t.status[status],
    count: counts[status],
    href: `/subscriptions?status=${status}`,
    color: STATUS_COLOR[status],
  }));
  const mixTotal = mix.reduce((total, part) => total + part.count, 0);

  const open = semester.data?.[0];
  const progress = open ? semesterProgress(open.start_date, open.end_date, todayIso) : null;
  const timeOf = (value: string) => new Intl.DateTimeFormat(locale, { timeStyle: "short", timeZone: admin.schoolTimezone }).format(new Date(value));
  const dateOf = (iso: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: "UTC" }).format(new Date(`${iso}T00:00:00Z`));
  const ageText = (since: string) => {
    const age = waitingAge(since, now);
    return format(age.unit === "hours" ? tiles.ageHours : tiles.ageDays, { n: age.value });
  };

  const hour = Number(new Intl.DateTimeFormat("en-GB", { hour: "2-digit", hourCycle: "h23", timeZone: admin.schoolTimezone }).format(now));
  const who = firstName(admin.fullName);
  const greeting = who ? `${tiles.welcome[greetingFor(hour)]}, ${who}` : tiles.welcome[greetingFor(hour)];
  const waitingCount = counts.pending;
  const summary =
    waitingCount === 0
      ? format(tiles.welcome.clear, { n: scansToday.count ?? 0 })
      : waitingCount === 1
        ? tiles.welcome.waitingOne
        : format(tiles.welcome.waitingMany, { n: waitingCount });
  // Two to four cards: what asks for action first, then what is running, then the day so far. Boardings and today's trips always exist, so there are never fewer than two.
  const oldest = (waiting.data ?? [])[0];
  const insights: Insight[] = [
    ...(waitingCount > 0
      ? [{ key: "pending", href: "/subscriptions", icon: Ticket03Icon, value: String(waitingCount), label: t.overview.pendingSubscriptions, attention: true }]
      : []),
    ...(oldest
      ? [{ key: "oldest", href: `/subscriptions/${oldest.id}`, icon: Clock01Icon, value: ageText(oldest.created_at), label: tiles.welcome.oldest }]
      : []),
    ...((activeTrips.count ?? 0) > 0
      ? [{ key: "running", href: "/trips?status=active", icon: Navigation03Icon, value: String(activeTrips.count), label: t.overview.activeTrips }]
      : []),
    { key: "boardings", href: "/scans", icon: ReceiptTextIcon, value: String(scansToday.count ?? 0), label: t.overview.scansToday },
    { key: "tripsToday", href: "/trips", icon: Calendar02Icon, value: String(todaysTrips.count ?? 0), label: tiles.welcome.tripsToday },
  ].slice(0, 4);
  const longDate = new Intl.DateTimeFormat(locale, { dateStyle: "full", timeZone: admin.schoolTimezone }).format(now);

  return (
    <>
      <PageHeader
        title={t.overview.title}
        subtitle={format(t.overview.subtitle, { school: admin.schoolName })}
        help={{
          label: t.help.open,
          title: t.overview.help.title,
          intro: t.overview.help.intro,
          scenarios: Object.values(t.overview.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
      />

      {failed ? (
        <Notice tone="bad">{t.overview.loadError}</Notice>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4" aria-label={t.overview.title}>
          {figures.map((figure) => {
            const { href, icon } = DESTINATIONS[figure.key];
            // What needs attention comes first and is set apart when there is something waiting.
            const waitingForYou = figure.key === "pendingSubscriptions" && (figure.value ?? 0) > 0;
            return (
              <Link
                key={figure.key}
                href={href}
                data-testid={`stat-${figure.key}`}
                className={
                  "group relative flex min-h-40 flex-col justify-between rounded-lg p-7 text-fg no-underline shadow-soft transition-shadow duration-(--dur) ease-soft " +
                  "hover:shadow-float focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus " +
                  (waitingForYou ? "bg-[color-mix(in_srgb,var(--accent)_18%,var(--surface))]" : "bg-surface")
                }
              >
                <Contour radius={28} inset={14} live />
                <span className="flex items-center justify-between gap-3">
                  <span className="stat-label text-sm font-semibold text-muted">{t.overview[figure.key]}</span>
                  <Icon icon={icon} size={22} />
                </span>
                <span className="stat-value text-5xl font-extrabold tracking-tight tabular-nums">{figure.value ?? 0}</span>
              </Link>
            );
          })}

          <Welcome greeting={greeting} date={longDate} summary={summary} insights={insights} />

          <Tile title={tiles.boardingsTitle} action={{ href: "/scans", label: t.nav.scans }} className="sm:col-span-2" testId="tile-boardings">
            <div className="mb-4 flex flex-wrap items-center gap-x-3 gap-y-1">
              <p className="m-0 text-3xl font-extrabold tracking-tight tabular-nums">{fourteenTotal}</p>
              <p className="m-0 text-sm text-muted">{trendText}</p>
            </div>
            <BoardingsChart
              days={days}
              locale={locale}
              label={tiles.boardingsChart}
              todayLabel={tiles.today}
              barLabel={(day, n) => format(tiles.boardingsBar, { day, n })}
            />
          </Tile>

          <Tile title={tiles.mixTitle} action={{ href: "/subscriptions?status=all", label: t.subscriptions.filters.all }} testId="tile-mix">
            {mixTotal === 0 ? (
              <p className="m-0 text-sm text-muted">{tiles.mixEmpty}</p>
            ) : (
              <>
                <p className="m-0 mb-4 text-sm text-muted">{format(tiles.mixTotal, { n: mixTotal })}</p>
                <StatusMix parts={mix} />
              </>
            )}
          </Tile>

          <Tile title={tiles.semesterTitle} action={{ href: "/semesters", label: t.nav.semesters }} testId="tile-semester">
            {open && progress ? (
              <div className="flex flex-1 flex-col justify-between gap-5">
                <div>
                  <p className="m-0 text-2xl font-extrabold tracking-tight">
                    {t.semester[open.name]} {open.year}
                  </p>
                  <p className="m-0 mt-1 text-sm text-muted">{format(tiles.semesterEnds, { date: dateOf(open.end_date) })}</p>
                </div>
                <div>
                  <div
                    role="progressbar"
                    aria-valuemin={0}
                    aria-valuemax={progress.total}
                    aria-valuenow={progress.day}
                    aria-label={format(tiles.semesterDay, { day: progress.day, total: progress.total })}
                    className="h-3 w-full overflow-hidden rounded-xs bg-surface-2"
                  >
                    <span className="block h-full rounded-xs bg-accent" style={{ width: `${progress.percent}%` }} />
                  </div>
                  <p className="m-0 mt-2 text-sm font-semibold tabular-nums">{format(tiles.semesterDay, { day: progress.day, total: progress.total })}</p>
                </div>
              </div>
            ) : (
              <div>
                <p className="m-0 font-semibold">{tiles.semesterNone}</p>
                <p className="m-0 mt-1 text-sm text-muted">{tiles.semesterNoneHint}</p>
              </div>
            )}
          </Tile>

          <Tile title={tiles.tripsTitle} action={{ href: "/trips", label: tiles.tripsAll }} className="sm:col-span-2" testId="tile-trips">
            {(todaysTrips.data ?? []).length === 0 ? (
              <div>
                <p className="m-0 font-semibold">{tiles.tripsEmpty}</p>
                <p className="m-0 mt-1 text-sm text-muted">{tiles.tripsEmptyHint}</p>
              </div>
            ) : (
              <ul className="m-0 grid list-none gap-1 p-0">
                {(todaysTrips.data ?? []).map((trip) => (
                  <li key={trip.id}>
                    <Link
                      href={`/trips/${trip.id}`}
                      className="flex items-center gap-3 rounded-sm px-2 py-2 text-fg no-underline hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus"
                    >
                      <span className="w-20 shrink-0 whitespace-nowrap text-sm font-bold tabular-nums">{timeOf(trip.scheduled_start)}</span>
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-sm font-semibold">
                          {plateOf.get(trip.bus_id) ?? ""} <span className="font-normal text-muted">{t.trips.direction[trip.direction]}</span>
                        </span>
                        <span className="block truncate text-xs text-muted">{trip.driver_id ? nameOf(trip.driver_id) : t.trips.noDriver}</span>
                      </span>
                      <Chip tone={tripStatusTone(trip.status)}>{t.trips.status[trip.status]}</Chip>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </Tile>

          <Tile title={tiles.waitingTitle} action={{ href: "/subscriptions", label: tiles.waitingAll }} testId="tile-waiting">
            {(waiting.data ?? []).length === 0 ? (
              <div>
                <p className="m-0 font-semibold">{tiles.waitingEmpty}</p>
                <p className="m-0 mt-1 text-sm text-muted">{tiles.waitingEmptyHint}</p>
              </div>
            ) : (
              <ul className="m-0 grid list-none gap-1 p-0">
                {(waiting.data ?? []).map((row) => (
                  <li key={row.id}>
                    <Link
                      href={`/subscriptions/${row.id}`}
                      className="flex items-center gap-3 rounded-sm px-2 py-1.5 text-fg no-underline hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus"
                    >
                      <Avatar name={nameOf(row.student_id)} url={null} size={32} />
                      <span className="min-w-0 flex-1 truncate text-sm font-semibold">{nameOf(row.student_id)}</span>
                      <Chip tone="warn">{ageText(row.created_at)}</Chip>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </Tile>

          <Tile title={tiles.fleetTitle} testId="tile-fleet">
            <div className="grid flex-1 gap-3">
              <Link
                href="/buses"
                className="flex items-center gap-4 rounded-sm bg-surface-2 p-4 text-fg no-underline focus-visible:outline-3 focus-visible:outline-focus"
              >
                <Icon icon={Bus01Icon} size={24} />
                <span className="flex-1">
                  <span className="block text-sm text-muted">{tiles.busesInService}</span>
                  <span className="block text-2xl font-extrabold tabular-nums">
                    {busesInService.count ?? 0}{" "}
                    <span className="text-sm font-medium text-muted">{format(tiles.busesOf, { total: busesTotal.count ?? 0 })}</span>
                  </span>
                </span>
              </Link>
              <Link
                href="/stops"
                className="flex items-center gap-4 rounded-sm bg-surface-2 p-4 text-fg no-underline focus-visible:outline-3 focus-visible:outline-focus"
              >
                <Icon icon={FlagTriangleRightIcon} size={24} />
                <span className="flex-1">
                  <span className="block text-sm text-muted">{tiles.stops}</span>
                  <span className="block text-2xl font-extrabold tabular-nums">{stops.count ?? 0}</span>
                </span>
              </Link>
            </div>
          </Tile>
        </div>
      )}
    </>
  );
}
