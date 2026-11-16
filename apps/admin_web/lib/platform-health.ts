/**
 * School health in the platform console (ADR 0027): what `platform_schools()` and `platform_school()` return, read
 * safely, and turned into plain sentences ("A request with its proof has waited 9 days"). The levels and thresholds are
 * decided in the database; this file only reads and words them.
 */

import { format } from "@/lib/i18n/format";

export const SIGNALS = [
  "answer_time_days",
  "oldest_pending_days",
  "oldest_request_days",
  "oldest_receipt_days",
  "answered_48h_pct",
  "approval_rate_pct",
  "profile_missing",
  "setup_missing",
  "semester_days_left",
  "scanned_trips_pct",
  "tracked_trips_pct",
  "cancelled_pct",
  "admin_idle_days",
  "new_students_change_pct",
] as const;
export type SignalKey = (typeof SIGNALS)[number];

export const AREAS = ["waiting", "conversion", "profile", "setup", "operations", "engagement"] as const;
export type Area = (typeof AREAS)[number];

/** 0 OK, 1 Watch, 2 Needs help, 3 Critical. */
export type Level = 0 | 1 | 2 | 3;
export const LEVEL_KEYS = ["ok", "watch", "needsHelp", "critical"] as const;
export type LevelKey = (typeof LEVEL_KEYS)[number];
/** Chip tones: a colour that always comes with its label. */
export const LEVEL_TONES = ["ok", "info", "warn", "bad"] as const;

export type Signal = {
  signal: SignalKey;
  area: Area;
  value: number | null;
  level: Level;
  weight: number;
  direction: "above" | "below";
  watch: number;
  needsHelp: number;
  critical: number;
  /** Capped at Watch because the school is in its first 14 days. */
  graced: boolean;
  /** What is missing, for the profile and setup signals. */
  detail: string[];
};

export type SchoolHealthRow = {
  id: string;
  name: string;
  shortName: string | null;
  logoPath: string | null;
  active: boolean;
  createdAt: string | null;
  students: number;
  staff: number;
  /** Null for a school that is switched off (not scored). */
  level: Level | null;
  score: number | null;
  reasons: Signal[];
  lastAdminActionAt: string | null;
  /** Signals paused after a contact, with the date they are paused until (ISO). */
  snoozed: Record<string, string>;
  lastOutreachAt: string | null;
};

export type SchoolDetail = {
  id: string;
  name: string;
  shortName: string | null;
  logoPath: string | null;
  active: boolean;
  createdAt: string | null;
  timezone: string | null;
  city: string | null;
  country: string | null;
  acceptsOpenSignup: boolean;
  publicListing: boolean;
  domains: string[];
  counts: { students: number; staff: number; admins: number };
  level: Level | null;
  score: number | null;
  signals: Signal[];
  history: { day: string; level: Level; score: number }[];
  adminActions: { action: string; at: string }[];
};

type Raw = Record<string, unknown>;

function record(value: unknown): Raw {
  return value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Raw) : {};
}

function num(value: unknown): number | null {
  const n = typeof value === "number" ? value : typeof value === "string" && value.trim() !== "" ? Number(value) : NaN;
  return Number.isFinite(n) ? n : null;
}

function count(value: unknown): number {
  const n = num(value);
  return n !== null && n > 0 ? Math.floor(n) : 0;
}

function text(value: unknown): string | null {
  return typeof value === "string" && value.trim() !== "" ? value : null;
}

function level(value: unknown): Level | null {
  const n = num(value);
  return n === 0 || n === 1 || n === 2 || n === 3 ? n : null;
}

function isSignal(value: unknown): value is SignalKey {
  return typeof value === "string" && (SIGNALS as readonly string[]).includes(value);
}

function isArea(value: unknown): value is Area {
  return typeof value === "string" && (AREAS as readonly string[]).includes(value);
}

/** One signal as the database gives it; unknown signals (from a newer database) are left out, never shown raw. */
export function parseSignal(value: unknown): Signal | null {
  const s = record(value);
  if (!isSignal(s.signal) || !isArea(s.area)) return null;
  return {
    signal: s.signal,
    area: s.area,
    value: num(s.value),
    level: level(s.level) ?? 0,
    weight: count(s.weight),
    direction: s.direction === "below" ? "below" : "above",
    watch: num(s.watch) ?? 0,
    needsHelp: num(s.needs_help) ?? 0,
    critical: num(s.critical) ?? 0,
    graced: s.graced === true,
    detail: Array.isArray(s.detail) ? s.detail.filter((d): d is string => typeof d === "string") : [],
  };
}

function signals(value: unknown): Signal[] {
  return (Array.isArray(value) ? value : []).map(parseSignal).filter((s): s is Signal => s !== null);
}

/** {"oldest_pending_days": {"until": "2026-11-23", ...}} as {"oldest_pending_days": "2026-11-23"}. */
export function snoozedUntil(value: unknown): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [signal, entry] of Object.entries(record(value))) {
    const until = text(record(entry).until);
    if (until) out[signal] = until;
  }
  return out;
}

export function parseSchoolRows(value: unknown): SchoolHealthRow[] {
  return (Array.isArray(value) ? value : [])
    .map(record)
    .filter((s) => text(s.id) && text(s.name))
    .map((s) => ({
      id: s.id as string,
      name: s.name as string,
      shortName: text(s.short_name),
      logoPath: text(s.logo_path),
      active: s.status === "active",
      createdAt: text(s.created_at),
      students: count(s.students),
      staff: count(s.staff),
      level: s.status === "active" ? level(s.level) : null,
      score: s.status === "active" ? num(s.score) : null,
      reasons: signals(s.reasons),
      lastAdminActionAt: text(s.last_admin_action_at),
      snoozed: snoozedUntil(s.snoozed),
      lastOutreachAt: text(s.last_outreach_at),
    }));
}

export function parseSchoolDetail(value: unknown): SchoolDetail | null {
  const raw = record(value);
  const school = record(raw.school);
  if (!text(school.id) || !text(school.name)) return null;
  const counts = record(raw.counts);
  const active = school.status === "active";
  return {
    id: school.id as string,
    name: school.name as string,
    shortName: text(school.short_name),
    logoPath: text(school.logo_path),
    active,
    createdAt: text(school.created_at),
    timezone: text(school.timezone),
    city: text(school.city),
    country: text(school.country),
    acceptsOpenSignup: school.accepts_open_signup === true,
    publicListing: school.public_listing === true,
    domains: Array.isArray(school.domains) ? school.domains.filter((d): d is string => typeof d === "string") : [],
    counts: { students: count(counts.students), staff: count(counts.staff), admins: count(counts.admins) },
    level: active ? level(raw.level) : null,
    score: active ? num(raw.score) : null,
    signals: signals(raw.signals),
    history: (Array.isArray(raw.history) ? raw.history : [])
      .map(record)
      .filter((h) => text(h.day) && level(h.level) !== null)
      .map((h) => ({ day: h.day as string, level: level(h.level) as Level, score: count(h.score) })),
    adminActions: (Array.isArray(raw.admin_actions) ? raw.admin_actions : [])
      .map(record)
      .filter((a) => text(a.action) && text(a.at))
      .map((a) => ({ action: a.action as string, at: a.at as string })),
  };
}

/** Filter for the schools list: a level key in the address, or everything. */
export function levelFromParam(value: string | string[] | undefined): Level | null {
  const key = Array.isArray(value) ? value[0] : value;
  const index = (LEVEL_KEYS as readonly string[]).indexOf(key ?? "");
  return index >= 0 ? (index as Level) : null;
}

/** `zero`, when given, words a value of 0 ("Nothing missing", "An administrator acted today"). */
export type SignalCopy = { title: string; sentence: string; none: string; ended?: string; zero?: string };
export type HealthCopy = {
  signals: Record<SignalKey, SignalCopy>;
  /** Names of the missing profile and setup items, by key. */
  items: Record<string, string>;
  thresholdsAbove: string;
  thresholdsBelow: string;
  unit: { days: string; pct: string; count: string };
};

function unitOf(signal: SignalKey): keyof HealthCopy["unit"] {
  if (signal.endsWith("_pct")) return "pct";
  if (signal === "profile_missing" || signal === "setup_missing") return "count";
  return "days";
}

/** A number as people read it: no needless decimals, a minus sign kept. */
export function shown(value: number, locale: string): string {
  return new Intl.NumberFormat(locale === "fr" ? "fr-FR" : "en-GB", { maximumFractionDigits: 1 }).format(value);
}

/**
 * The signal as one plain sentence: "A request with its proof has waited 9 days". For the profile and setup signals, the
 * missing items are named. A signal that does not apply yet says so.
 */
export function signalSentence(signal: Signal, copy: HealthCopy, locale: string): string {
  const c = copy.signals[signal.signal];
  if (signal.value === null) return c.none;
  if (signal.signal === "semester_days_left" && signal.value < 0 && c.ended) return c.ended;
  if (signal.value === 0 && c.zero) return c.zero;
  const items = signal.detail.map((key) => copy.items[key] ?? key).join(", ");
  return format(c.sentence, { value: shown(signal.value, locale), items });
}

/** "To watch above 2, needs help above 4, critical above 7 (days)". */
export function thresholdsText(signal: Signal, copy: HealthCopy, locale: string): string {
  const template = signal.direction === "above" ? copy.thresholdsAbove : copy.thresholdsBelow;
  return format(template, {
    watch: shown(signal.watch, locale),
    needsHelp: shown(signal.needsHelp, locale),
    critical: shown(signal.critical, locale),
    unit: copy.unit[unitOf(signal.signal)],
  });
}

/**
 * Schools that need the platform's attention first: Critical, then Needs help; the lowest score first within a level. A
 * school whose serious signals were all paused after a contact waits until the pause ends.
 */
export function needingAttention(rows: SchoolHealthRow[]): SchoolHealthRow[] {
  return rows
    .filter((row) => row.level !== null && row.level >= 2)
    .filter((row) => {
      const serious = row.reasons.filter((reason) => reason.level >= 2);
      return serious.length === 0 || serious.some((reason) => !row.snoozed[reason.signal]);
    })
    .sort((a, b) => (b.level ?? 0) - (a.level ?? 0) || (a.score ?? 100) - (b.score ?? 100) || a.name.localeCompare(b.name));
}

/** How many schools sit at each level, for the filter chips. Switched-off schools are counted apart. */
export function levelCounts(rows: SchoolHealthRow[]): { byLevel: [number, number, number, number]; off: number } {
  const byLevel: [number, number, number, number] = [0, 0, 0, 0];
  let off = 0;
  for (const row of rows) {
    if (row.level === null) off += 1;
    else byLevel[row.level] += 1;
  }
  return { byLevel, off };
}

/** "Contacted today", "Contacted 3 days ago": when the platform last reached out to the school. */
export function contactedText(iso: string, copy: { contactedToday: string; contactedDaysAgo: string }, now: Date = new Date()): string {
  const days = Math.max(0, Math.floor((now.getTime() - Date.parse(iso)) / 86_400_000));
  return days === 0 ? copy.contactedToday : format(copy.contactedDaysAgo, { n: days });
}
