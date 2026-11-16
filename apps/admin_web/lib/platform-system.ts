/**
 * Usage, costs and system health in the platform console (ADR 0027, slice 6): what `platform_system_health()` returns,
 * read safely, set against the plan limits, and put in words.
 */

/**
 * The free allowances BusIn runs on (2026): Supabase Free (database, file storage, monthly active accounts) and Mapbox
 * (map directions per month; place search uses BusIn's own OpenStreetMap copy and costs nothing). Change them here when a
 * plan changes; the page then measures against the new numbers.
 */
export const PLAN_LIMITS = {
  databaseBytes: 500 * 1024 * 1024,
  storageBytes: 1024 * 1024 * 1024,
  activeAccounts: 50_000,
  directionsPerMonth: 100_000,
} as const;

/** 0 fine, 1 getting close (80 %), 2 nearly full (95 %). */
export type Pressure = 0 | 1 | 2;

export function pressure(used: number, limit: number): Pressure {
  if (limit <= 0) return 0;
  const share = used / limit;
  return share >= 0.95 ? 2 : share >= 0.8 ? 1 : 0;
}

export type Job = { name: string; schedule: string; active: boolean; lastRunAt: string | null; lastStatus: string | null; failures7d: number; lastError: string | null };
export type QuietTrip = { school: string; schoolId: string; startedAt: string; lastPositionAt: string | null };

export type SystemHealth = {
  databaseBytes: number;
  storage: { bucket: string; bytes: number; files: number }[];
  storageBytes: number;
  accounts: { total: number; active30d: number };
  usage: { directionsMonth: number; placeSearchesMonth: number };
  push: { sent7d: number; failed7d: number; waiting: number; oldestWaitingAt: string | null; lastError: string | null };
  devices: { android: number; ios: number; web: number; stale30d: number };
  jobs: Job[];
  quietTrips: QuietTrip[];
};

type Raw = Record<string, unknown>;
const record = (value: unknown): Raw => (value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Raw) : {});
const num = (value: unknown): number => {
  const n = typeof value === "number" ? value : typeof value === "string" ? Number(value) : NaN;
  return Number.isFinite(n) && n > 0 ? n : 0;
};
const text = (value: unknown): string | null => (typeof value === "string" && value.trim() !== "" ? value : null);
const list = (value: unknown) => (Array.isArray(value) ? value.map(record) : []);

export function parseSystemHealth(value: unknown): SystemHealth {
  const raw = record(value);
  const storage = list(raw.storage)
    .filter((b) => text(b.bucket))
    .map((b) => ({ bucket: b.bucket as string, bytes: num(b.bytes), files: num(b.files) }));
  const accounts = record(raw.accounts);
  const usage = record(raw.usage);
  const push = record(raw.push);
  const devices = record(raw.devices);
  return {
    databaseBytes: num(raw.database_bytes),
    storage,
    storageBytes: storage.reduce((sum, b) => sum + b.bytes, 0),
    accounts: { total: num(accounts.total), active30d: num(accounts.active_30d) },
    usage: { directionsMonth: num(usage.directions_month), placeSearchesMonth: num(usage.place_searches_month) },
    push: {
      sent7d: num(push.sent_7d),
      failed7d: num(push.failed_7d),
      waiting: num(push.waiting),
      oldestWaitingAt: text(push.oldest_waiting_at),
      lastError: text(push.last_error),
    },
    devices: { android: num(devices.android), ios: num(devices.ios), web: num(devices.web), stale30d: num(devices.stale_30d) },
    jobs: list(raw.jobs)
      .filter((j) => text(j.name))
      .map((j) => ({
        name: j.name as string,
        schedule: text(j.schedule) ?? "",
        active: j.active !== false,
        lastRunAt: text(j.last_run_at),
        lastStatus: text(j.last_status),
        failures7d: num(j.failures_7d),
        lastError: text(j.last_error),
      })),
    quietTrips: list(raw.quiet_trips)
      .filter((q) => text(q.school) && text(q.school_id) && text(q.started_at))
      .map((q) => ({ school: q.school as string, schoolId: q.school_id as string, startedAt: q.started_at as string, lastPositionAt: text(q.last_position_at) })),
  };
}

/** "512 MB", "1.2 GB": sizes as people read them. */
export function bytesText(bytes: number, locale: string): string {
  const units = ["B", "KB", "MB", "GB", "TB"];
  let value = bytes;
  let unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  const number = new Intl.NumberFormat(locale === "fr" ? "fr-FR" : "en-GB", { maximumFractionDigits: value < 10 && unit > 0 ? 1 : 0 }).format(value);
  return `${number} ${units[unit]}`;
}

export type ScheduleCopy = { everyMinute: string; hourly: string; daily: string; other: string };

/** A cron schedule in words for the simple patterns BusIn uses: every minute, hourly at :MM, daily at HH:MM UTC. */
export function scheduleText(schedule: string, copy: ScheduleCopy): string {
  const parts = schedule.trim().split(/\s+/);
  if (parts.length !== 5) return format(copy.other, { cron: schedule });
  const [minute, hour, day, month, weekday] = parts;
  const rest = day === "*" && month === "*" && weekday === "*";
  if (rest && minute === "*" && hour === "*") return copy.everyMinute;
  if (rest && /^\d+$/.test(minute) && hour === "*") return format(copy.hourly, { minute: minute.padStart(2, "0") });
  if (rest && /^\d+$/.test(minute) && /^\d+$/.test(hour)) return format(copy.daily, { time: `${hour.padStart(2, "0")}:${minute.padStart(2, "0")}` });
  return format(copy.other, { cron: schedule });
}

function format(template: string, values: Record<string, string>): string {
  return template.replace(/\{(\w+)\}/g, (match, key: string) => values[key] ?? match);
}

/** A job is failing when its last run failed; a job that never ran is not counted as failing. */
export function failingJobs(jobs: Job[]): Job[] {
  return jobs.filter((job) => job.lastStatus === "failed");
}

/** What needs a look, for "Needs you": limits at 80 % or more, a failing job, pushes waiting over 30 minutes, quiet buses. */
export function systemAttention(health: SystemHealth, now: Date = new Date()): number {
  const limits = [
    pressure(health.databaseBytes, PLAN_LIMITS.databaseBytes),
    pressure(health.storageBytes, PLAN_LIMITS.storageBytes),
    pressure(health.accounts.active30d, PLAN_LIMITS.activeAccounts),
    pressure(health.usage.directionsMonth, PLAN_LIMITS.directionsPerMonth),
  ].filter((p) => p > 0).length;
  const stuckPush = health.push.oldestWaitingAt && now.getTime() - Date.parse(health.push.oldestWaitingAt) > 30 * 60_000 ? 1 : 0;
  return limits + failingJobs(health.jobs).length + stuckPush + health.quietTrips.length;
}
