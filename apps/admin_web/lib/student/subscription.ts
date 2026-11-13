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
};

export type SubscriptionEvent = { id: number; subscription_id: string; action: "requested" | "approved" | "rejected" | "revoked" | "reinstated"; note: string | null; created_at: string };

/** Pending or approved: a request that still counts. */
export function isLive(status: SubscriptionStatus): boolean {
  return status === "pending" || status === "approved";
}

/** What to show for a semester: a live request wins; otherwise the newest of the rest. The list arrives newest first. */
export function subscriptionToShow(mine: SubscriptionRow[], semesterId: string): SubscriptionRow | null {
  const inSemester = mine.filter((s) => s.semester_id === semesterId);
  return inSemester.find((s) => isLive(s.status)) ?? inSemester[0] ?? null;
}

/** The semester's requests, latest first, each with what happened to it, latest first. */
export function buildRequestHistory(subscriptions: SubscriptionRow[], events: SubscriptionEvent[]) {
  const requests = [...subscriptions].sort((a, b) => b.created_at.localeCompare(a.created_at) || b.id.localeCompare(a.id));
  return requests.map((subscription) => ({
    subscription,
    events: events
      .filter((e) => e.subscription_id === subscription.id)
      .sort((a, b) => b.created_at.localeCompare(a.created_at) || b.id - a.id),
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

export type SubscribeProblem = "exists" | "ended" | "proof" | "unavailable" | "offline" | "type" | "tooLarge" | "failed";

/**
 * What a refused request means for the student, from the database's answer (as the app's `failureFor`): its short
 * reasons first, then the error class.
 */
export function subscribeProblem(error: { code?: string | null; message?: string | null }): SubscribeProblem {
  const message = error.message ?? "";
  if (message.includes("semester_ended")) return "ended";
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
