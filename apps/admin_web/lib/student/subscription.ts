/**
 * The subscription tab's rules, ported from the student app (subscription_providers.dart, request_history.dart,
 * proof_picker.dart) and kept pure so each is a unit test.
 */
export type SubscriptionStatus = "pending" | "approved" | "rejected" | "expired" | "revoked";

export type SubscriptionRow = {
  id: string;
  semester_id: string;
  stop_id: string;
  status: SubscriptionStatus;
  proof_path: string | null;
  review_note: string | null;
  created_at: string;
  /** School billing (ADR 0022): how it is paid, the month it covers (null: the whole semester), and its price. */
  payment_mode?: string;
  period_start?: string | null;
  period_end?: string | null;
  amount_xaf?: number | null;
  installment_plan?: string | null;
};

export type SubscriptionEvent = { id: number; subscription_id: string; action: "requested" | "approved" | "rejected" | "revoked" | "reinstated"; note: string | null; created_at: string };

/** Pending or approved: a request that still counts. */
export function isLive(status: SubscriptionStatus): boolean {
  return status === "pending" || status === "approved";
}

/** A live request still counts while its month (or its semester) has not ended. `today` is the school's day, YYYY-MM-DD. */
export function stillRunning(row: Pick<SubscriptionRow, "period_end">, today: string | null): boolean {
  return today === null || !row.period_end || row.period_end >= today;
}

/** The pending and approved requests that have not ended, earliest month first (a whole-semester one first). */
export function liveRequests(mine: SubscriptionRow[], today: string | null): SubscriptionRow[] {
  return mine.filter((s) => isLive(s.status) && stillRunning(s, today)).sort((a, b) => (a.period_start ?? "").localeCompare(b.period_start ?? ""));
}

/**
 * What to show for a semester: a live request wins (the earliest month first, with monthly billing); otherwise the newest
 * of the rest. A monthly subscription whose month has ended no longer counts: nothing is shown, so the form offers the new
 * month. The list arrives newest first.
 */
export function subscriptionToShow(mine: SubscriptionRow[], semesterId: string, today: string | null = null): SubscriptionRow | null {
  const inSemester = mine.filter((s) => s.semester_id === semesterId);
  const live = liveRequests(inSemester, today);
  if (live.length) return live[0];
  const newest = inSemester[0] ?? null;
  return newest && isLive(newest.status) ? null : newest;
}

/** The months a student may ask for (first days, YYYY-MM-01): this month and the next, overlapping the semester, not taken. */
export function monthChoices(semester: { start_date: string; end_date: string }, today: string, live: Pick<SubscriptionRow, "period_start">[]): string[] {
  const [year, month] = today.split("-").map(Number);
  const first = (y: number, m: number) => new Date(Date.UTC(y, m - 1, 1)).toISOString().slice(0, 10);
  const last = (y: number, m: number) => new Date(Date.UTC(y, m, 0)).toISOString().slice(0, 10);
  return [
    [year, month],
    [month === 12 ? year + 1 : year, month === 12 ? 1 : month + 1],
  ]
    .filter(([y, m]) => first(y, m) <= semester.end_date && last(y, m) >= semester.start_date)
    .map(([y, m]) => first(y, m))
    .filter((m) => !live.some((s) => s.period_start?.slice(0, 7) === m.slice(0, 7)));
}

/** A receipt sent for a part of a subscription paid in installments, with the school's decision (ADR 0022). */
export type ReceiptRow = {
  id: string;
  subscription_id: string;
  seq: number;
  proof_path: string | null;
  sent_at: string;
  decision: string | null;
  note: string | null;
  decided_at: string | null;
};

/** One line of a request's history: an operation on it, or a step of a receipt (sent, paid, not accepted). */
export type HistoryItem = {
  key: string;
  action: SubscriptionEvent["action"] | "partSent" | "partPaid" | "partRejected";
  at: string;
  note: string | null;
  seq?: number;
  proofPath?: string | null;
};

/** The steps of a receipt: sent (when it has a proof; paid at the office has none), then the school's decision. */
export function receiptItems(r: ReceiptRow): HistoryItem[] {
  return [
    ...(r.proof_path ? [{ key: `${r.id}-sent`, action: "partSent" as const, at: r.sent_at, note: null, seq: r.seq, proofPath: r.proof_path }] : []),
    ...(r.decision === "paid" ? [{ key: `${r.id}-paid`, action: "partPaid" as const, at: r.decided_at ?? r.sent_at, note: null, seq: r.seq }] : []),
    ...(r.decision === "rejected" ? [{ key: `${r.id}-rejected`, action: "partRejected" as const, at: r.decided_at ?? r.sent_at, note: r.note, seq: r.seq }] : []),
  ];
}

/** The semester's requests, latest first, each with what happened to it (its operations and its receipts), latest first. */
export function buildRequestHistory(subscriptions: SubscriptionRow[], events: SubscriptionEvent[], receipts: ReceiptRow[] = []) {
  const requests = [...subscriptions].sort((a, b) => b.created_at.localeCompare(a.created_at) || b.id.localeCompare(a.id));
  return requests.map((subscription) => ({
    subscription,
    events: [
      ...events.filter((e) => e.subscription_id === subscription.id).map((e): HistoryItem => ({ key: `e${e.id}`, action: e.action, at: e.created_at, note: e.note })),
      ...receipts.filter((r) => r.subscription_id === subscription.id).flatMap(receiptItems),
    ].sort((a, b) => b.at.localeCompare(a.at) || b.key.localeCompare(a.key)),
  }));
}

/** The three steps of a request and how far it got: sent, checking, decided. */
export function stageOf(status: SubscriptionStatus): { reached: 1 | 2 | 3; failed: boolean } {
  if (status === "pending") return { reached: 1, failed: false };
  if (status === "rejected" || status === "revoked") return { reached: 2, failed: true };
  return { reached: 3, failed: false };
}

export const PROOF_MAX_BYTES = 5 * 1024 * 1024;
/** The longest side of a proof photo after shrinking, as the app's picker. */
export const PROOF_MAX_SIDE = 1600;

/** The real type of an image from its first bytes, whatever its name says. Only what the proofs bucket accepts. */
export function sniffImageType(head: Uint8Array): "image/jpeg" | "image/png" | "image/webp" | null {
  if (head.length >= 3 && head[0] === 0xff && head[1] === 0xd8 && head[2] === 0xff) return "image/jpeg";
  if (head.length >= 8 && [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a].every((b, i) => head[i] === b)) return "image/png";
  const ascii = (from: number, to: number) => String.fromCharCode(...head.slice(from, to));
  if (head.length >= 12 && ascii(0, 4) === "RIFF" && ascii(8, 12) === "WEBP") return "image/webp";
  return null;
}

/** Where a proof goes: the student's own folder of their school's bucket, with a random name (no email, no date). */
export function proofPath(schoolId: string, studentId: string, randomHex: string, contentType: "image/jpeg" | "image/png" | "image/webp"): string {
  const ext = contentType === "image/png" ? "png" : contentType === "image/webp" ? "webp" : "jpg";
  return `${schoolId}/${studentId}/${randomHex}.${ext}`;
}

export type SubscribeProblem = "exists" | "ended" | "periodEnded" | "billing" | "payment" | "proof" | "unavailable" | "offline" | "type" | "tooLarge" | "failed";

/**
 * What a refused request means for the student, from the database's answer (as the app's `failureFor`): its short
 * reasons first, then the error class.
 */
export function subscribeProblem(error: { code?: string | null; message?: string | null }): SubscribeProblem {
  const message = error.message ?? "";
  if (message.includes("semester_ended")) return "ended";
  if (message.includes("period_ended")) return "periodEnded";
  if (message.includes("billing_not_set")) return "billing";
  // The school changed its billing meanwhile: read the page again.
  if (message.includes("installments_not_offered") || message.includes("month_required") || message.includes("month_not_allowed")) return "unavailable";
  if (message.includes("proof_required") || message.includes("proof_missing")) return "proof";
  if (error.code === "23503") return "unavailable";
  if (error.code === "23505" || error.code === "55000") return "exists";
  return "failed";
}

/** What a refused upload means: the storage limits are 5 MB and three image types. */
export function uploadProblem(error: { statusCode?: string | number; message?: string }): SubscribeProblem {
  const status = String(error.statusCode ?? "");
  const message = (error.message ?? "").toLowerCase();
  if (status === "413" || message.includes("size") || message.includes("too large")) return "tooLarge";
  if (status === "415" || message.includes("mime") || message.includes("type")) return "type";
  return "failed";
}
