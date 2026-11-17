/**
 * Reaching out to a school from the platform console (ADR 0027): the ready message for the signals chosen (in English
 * or French, whatever the console's own language), the links that open it in the owner's own email or WhatsApp, and what
 * the database returns about contacts and past contacts, read safely.
 */

import { format } from "@/lib/i18n/format";
import type { Locale, Messages } from "@/lib/i18n/messages";
import { signalSentence, type Signal, type SignalKey } from "@/lib/platform-health";
import { docToPlainText, MAX_TEXT, type RichDoc, type RichListItem } from "@/lib/rich-text";

export const CHANNELS = ["email", "whatsapp", "call", "notice", "meeting", "other"] as const;
export type Channel = (typeof CHANNELS)[number];
export const SNOOZE_DAYS = [0, 3, 7, 14, 30] as const;

export function isChannel(value: unknown): value is Channel {
  return typeof value === "string" && (CHANNELS as readonly string[]).includes(value);
}

/** Where in the school's portal each missing setup item is fixed. */
const SETUP_PATHS: Record<string, string> = {
  domain: "/school",
  billing: "/billing",
  semester: "/semesters",
  stops: "/stops",
  route: "/stops",
  buses: "/buses",
  staff: "/people",
};

const PATHS: Record<SignalKey, string> = {
  answer_time_days: "/subscriptions",
  oldest_pending_days: "/subscriptions",
  oldest_request_days: "/people?role=verify",
  oldest_receipt_days: "/subscriptions",
  answered_48h_pct: "/subscriptions",
  approval_rate_pct: "/school",
  profile_missing: "/school",
  setup_missing: "/profile",
  semester_days_left: "/semesters",
  scanned_trips_pct: "/trips",
  tracked_trips_pct: "/trips",
  cancelled_pct: "/trips",
  admin_idle_days: "/",
  new_students_change_pct: "/school",
};

/** The portal page where a school fixes what a signal says. */
export function signalPath(signal: Pick<Signal, "signal" | "detail">): string {
  if (signal.signal === "setup_missing" && signal.detail.length > 0) return SETUP_PATHS[signal.detail[0]] ?? PATHS.setup_missing;
  return PATHS[signal.signal];
}

export type ReadyMessage = { subject: string; body: string; notice: string; noticeDoc: RichDoc; link: string | null };

/**
 * What the message needs from one language's catalogue: passed in, so a page sends only this to the browser. `notice`
 * is the school portal's own words around a notice, for the preview of how the school will see it.
 */
export type MessageCopy = {
  health: Messages["platform"]["health"];
  message: Messages["platform"]["outreach"]["message"];
  notice: Pick<Messages["notices"], "from" | "open" | "dismiss" | "showMore" | "showLess" | "newTab">;
};

export function messageCopy(t: Messages): MessageCopy {
  const { from, open, dismiss, showMore, showLess, newTab } = t.notices;
  return { health: t.platform.health, message: t.platform.outreach.message, notice: { from, open, dismiss, showMore, showLess, newTab } };
}

/** The ready notice as rich text: the intro, then one bullet per point. */
function noticeDocOf(intro: string, points: string[]): RichDoc {
  const items: RichListItem[] = points.map((text) => ({ type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text }] }] }));
  return {
    type: "doc",
    content: [{ type: "paragraph", content: [{ type: "text", text: intro }] }, ...(items.length > 0 ? [{ type: "bulletList" as const, content: items }] : [])],
  };
}

/**
 * The message for a school about the chosen signals, in the chosen language: a greeting, one line per signal (what we
 * see, what helps, and the page that fixes it), and a closing. `noticeDoc` is the shorter rich text for the in-portal
 * notice (the intro, then one bullet per signal), `notice` its plain text; its button leads to `link` (the first
 * signal's page).
 */
export function readyMessage(schoolName: string, signals: Signal[], copy: MessageCopy, language: Locale, siteUrl: string): ReadyMessage {
  const t = copy;
  const m = copy.message;
  const base = siteUrl.replace(/\/$/, "");
  const lines = signals.map((signal) => {
    const sentence = signalSentence(signal, t.health, language);
    const tip = m.tips[signal.signal];
    return `- ${sentence}. ${tip} ${base}${signalPath(signal)}`;
  });
  const body = [
    format(m.greeting, { school: schoolName }),
    "",
    signals.length > 0 ? m.intro : m.introNone,
    ...lines,
    "",
    m.closing,
    "",
    m.signature,
  ].join("\n");
  const points = signals.map((signal) => `${signalSentence(signal, t.health, language)}. ${m.tips[signal.signal]}`);
  // Every signal fits in practice; the last ones are left out if the notice would pass the limit.
  let noticeDoc = noticeDocOf(m.noticeIntro, points);
  for (let n = points.length - 1; n >= 0 && docToPlainText(noticeDoc).length > MAX_TEXT; n--) noticeDoc = noticeDocOf(m.noticeIntro, points.slice(0, n));
  return {
    subject: format(m.subject, { school: schoolName }),
    body,
    notice: docToPlainText(noticeDoc),
    noticeDoc,
    link: signals.length > 0 ? signalPath(signals[0]) : null,
  };
}

/** Opens the owner's own email with the message ready. */
export function mailtoHref(to: string, subject: string, body: string): string {
  return `mailto:${encodeURIComponent(to)}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
}

/** Opens WhatsApp with the message ready, for a number stored as E.164 (+237...). Null for a number it cannot use. */
export function whatsappHref(phone: string, text: string): string | null {
  const digits = phone.replace(/\D/g, "");
  if (digits.length < 7 || digits.length > 15) return null;
  return `https://wa.me/${digits}?text=${encodeURIComponent(text)}`;
}

export type Contact = { label: string; name: string | null; email: string | null; phone: string | null };

type Raw = Record<string, unknown>;
const record = (value: unknown): Raw => (value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Raw) : {});
const text = (value: unknown): string | null => (typeof value === "string" && value.trim() !== "" ? value : null);

/** The school's own contact details first, then each administrator. Entries with nothing to reach are left out. */
export function parseContacts(value: unknown, labels: { school: string; admin: string }): Contact[] {
  const raw = record(value);
  const contacts: Contact[] = [];
  const schoolPhone = text(raw.phone) ?? text(raw.phone_secondary);
  if (text(raw.email) || schoolPhone) contacts.push({ label: labels.school, name: null, email: text(raw.email), phone: schoolPhone });
  if (text(raw.phone) && text(raw.phone_secondary)) contacts.push({ label: labels.school, name: null, email: null, phone: text(raw.phone_secondary) });
  for (const admin of Array.isArray(raw.admins) ? raw.admins.map(record) : []) {
    if (!text(admin.email) && !text(admin.phone)) continue;
    contacts.push({ label: labels.admin, name: text(admin.name), email: text(admin.email), phone: text(admin.phone) });
  }
  return contacts;
}

export type OutreachEntry = {
  id: string;
  channel: Channel;
  signals: string[];
  note: string | null;
  snoozeUntil: string | null;
  followUpOn: string | null;
  followUpDoneAt: string | null;
  createdAt: string;
  noticeDismissedAt: string | null;
};

export type SchoolOutreach = { log: OutreachEntry[]; snoozed: Record<string, { until: string; contactedAt: string }> };

export function parseSnoozed(value: unknown): SchoolOutreach["snoozed"] {
  const raw = record(value);
  const snoozed: SchoolOutreach["snoozed"] = {};
  for (const [signal, entry] of Object.entries(raw)) {
    const e = record(entry);
    const until = text(e.until);
    const contactedAt = text(e.contacted_at);
    if (until && contactedAt) snoozed[signal] = { until, contactedAt };
  }
  return snoozed;
}

export function parseSchoolOutreach(value: unknown): SchoolOutreach {
  const raw = record(value);
  const log = (Array.isArray(raw.log) ? raw.log : [])
    .map(record)
    .filter((e) => text(e.id) && isChannel(e.channel) && text(e.created_at))
    .map(
      (e): OutreachEntry => ({
        id: e.id as string,
        channel: e.channel as Channel,
        signals: Array.isArray(e.signals) ? e.signals.filter((s): s is string => typeof s === "string") : [],
        note: text(e.note),
        snoozeUntil: text(e.snooze_until),
        followUpOn: text(e.follow_up_on),
        followUpDoneAt: text(e.follow_up_done_at),
        createdAt: e.created_at as string,
        noticeDismissedAt: text(e.notice_dismissed_at),
      }),
    );
  return { log, snoozed: parseSnoozed(raw.snoozed) };
}

/** A link from a notice stays inside the school's portal: a path, never another site. */
export function isPortalPath(value: unknown): value is string {
  // One slash, then a path: "//host" would leave the site.
  return typeof value === "string" && value.length <= 80 && /^\/([a-z0-9?=&-][a-z0-9/?=&-]*)?$/.test(value);
}
