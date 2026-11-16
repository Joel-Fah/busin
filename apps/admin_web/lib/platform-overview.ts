/**
 * The platform console's first page (ADR 0027): what `platform_overview()` returns, read safely. The function returns
 * JSON, so every number is checked here: a missing or malformed value becomes 0 (or null), never a crash.
 */

export type PlatformTotals = {
  schoolsActive: number;
  schoolsInactive: number;
  students: number;
  staff: number;
  admins: number;
  pendingAccounts: number;
  suspendedAccounts: number;
  newAccounts7d: number;
  newAccounts30d: number;
  subscriptionsPending: number;
  subscriptionsApproved: number;
  subscriptionsRejected: number;
  tripsScheduled: number;
  tripsActive: number;
  tripsCompleted: number;
  tripsCancelled: number;
  scansToday: number;
  busesLive: number;
};

export type PlatformSchool = {
  id: string;
  name: string;
  shortName: string | null;
  logoPath: string | null;
  active: boolean;
  createdAt: string | null;
  students: number;
  staff: number;
  admins: number;
  waitingToJoin: number;
  subscriptionsPending: number;
  tripsActive: number;
  lastAdminActionAt: string | null;
};

export type PlatformOverview = { totals: PlatformTotals; schools: PlatformSchool[] };

type Raw = Record<string, unknown>;

function record(value: unknown): Raw {
  return value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Raw) : {};
}

function count(value: unknown): number {
  const n = typeof value === "number" ? value : typeof value === "string" ? Number(value) : NaN;
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : 0;
}

function text(value: unknown): string | null {
  return typeof value === "string" && value.trim() !== "" ? value : null;
}

const TOTALS: Record<keyof PlatformTotals, string> = {
  schoolsActive: "schools_active",
  schoolsInactive: "schools_inactive",
  students: "students",
  staff: "staff",
  admins: "admins",
  pendingAccounts: "pending_accounts",
  suspendedAccounts: "suspended_accounts",
  newAccounts7d: "new_accounts_7d",
  newAccounts30d: "new_accounts_30d",
  subscriptionsPending: "subscriptions_pending",
  subscriptionsApproved: "subscriptions_approved",
  subscriptionsRejected: "subscriptions_rejected",
  tripsScheduled: "trips_today_scheduled",
  tripsActive: "trips_today_active",
  tripsCompleted: "trips_today_completed",
  tripsCancelled: "trips_today_cancelled",
  scansToday: "scans_today",
  busesLive: "buses_live",
};

export function parsePlatformOverview(value: unknown): PlatformOverview {
  const raw = record(value);
  const rawTotals = record(raw.totals);
  const totals = Object.fromEntries(
    (Object.keys(TOTALS) as (keyof PlatformTotals)[]).map((key) => [key, count(rawTotals[TOTALS[key]])]),
  ) as PlatformTotals;

  const schools = (Array.isArray(raw.schools) ? raw.schools : [])
    .map(record)
    .filter((s) => text(s.id) && text(s.name))
    .map(
      (s): PlatformSchool => ({
        id: s.id as string,
        name: s.name as string,
        shortName: text(s.short_name),
        logoPath: text(s.logo_path),
        active: s.status === "active",
        createdAt: text(s.created_at),
        students: count(s.students),
        staff: count(s.staff),
        admins: count(s.admins),
        waitingToJoin: count(s.waiting_to_join),
        subscriptionsPending: count(s.subscriptions_pending),
        tripsActive: count(s.trips_active),
        lastAdminActionAt: text(s.last_admin_action_at),
      }),
    );

  return { totals, schools };
}

/** Whole days since a moment, for "last admin action 3 days ago". Null when there is no moment or it cannot be read. */
export function daysSince(iso: string | null, now: Date = new Date()): number | null {
  if (!iso) return null;
  const then = Date.parse(iso);
  if (Number.isNaN(then)) return null;
  return Math.max(0, Math.floor((now.getTime() - then) / 86_400_000));
}
