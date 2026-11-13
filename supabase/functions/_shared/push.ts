// The logic of sending push notifications, kept free of Deno and network calls so Node can test it
// (node --test supabase/functions/_shared). The Edge Function in ../send-push/index.ts only wires it up.
// Design: docs/decisions/0010-push-notifications.md.

export type Locale = "en" | "fr";
export type Kind = "subscription_approved" | "subscription_rejected" | "subscription_revoked" | "school_notice" | "bus_near_stop" | "crew_assigned";

/** One claimed notification, as claim_notifications returns it. */
export type Claimed = {
  id: number;
  kind: string;
  ref_id: string | null;
  tokens: { token: string; platform: string; locale: string }[];
};

// The wording lives here, not in the database: the database says what happened, this says how to put it.
// Nothing personal goes in: no names, no reasons. The app shows the details after it opens.
const TEXT: Record<Kind, Record<Locale, { title: string; body: string }>> = {
  subscription_approved: {
    en: { title: "You are subscribed", body: "Your subscription was approved. Open BusIn to show your boarding code." },
    fr: { title: "Vous êtes abonné", body: "Votre abonnement a été approuvé. Ouvrez BusIn pour afficher votre code d’embarquement." },
  },
  subscription_rejected: {
    en: { title: "Request not approved", body: "Your school has decided on your subscription. Open BusIn to see why." },
    fr: { title: "Demande non approuvée", body: "Votre école a statué sur votre abonnement. Ouvrez BusIn pour en connaître la raison." },
  },
  // An approved subscription was taken back by the school. The reason is shown in the app, not here.
  subscription_revoked: {
    en: { title: "Subscription revoked", body: "Your school revoked your bus subscription. Open BusIn to see why." },
    fr: { title: "Abonnement révoqué", body: "Votre école a révoqué votre abonnement au bus. Ouvrez BusIn pour en connaître la raison." },
  },
  // A change from the school (for now: the dates of a semester the student is subscribed to). Always sent.
  school_notice: {
    en: { title: "News from your school", body: "Your school changed something about your bus service. Open BusIn to see what." },
    fr: { title: "Du nouveau de votre école", body: "Votre école a modifié quelque chose sur votre service de bus. Ouvrez BusIn pour voir quoi." },
  },
  // The bus is a few minutes from the student's stop (they chose how many). No stop, bus or time in the text.
  bus_near_stop: {
    en: { title: "Your bus is almost here", body: "It is a few minutes from your stop. Open BusIn to follow it." },
    fr: { title: "Votre bus arrive", body: "Il est à quelques minutes de votre arrêt. Ouvrez BusIn pour le suivre." },
  },
  // A staff member was put on a trip's crew by a colleague who started it in the field (ADR 0020). No names, no bus.
  crew_assigned: {
    en: { title: "You were added to a trip", body: "A colleague started a trip with you on board. Open BusIn Ops to see it." },
    fr: { title: "Vous avez été ajouté à un trajet", body: "Un collègue a démarré un trajet avec vous à bord. Ouvrez BusIn Ops pour le voir." },
  },
};

export function isKind(value: string): value is Kind {
  return value === "subscription_approved" || value === "subscription_rejected" || value === "subscription_revoked" || value === "school_notice" || value === "bus_near_stop" || value === "crew_assigned";
}

export function asLocale(value: string): Locale {
  return value === "fr" ? "fr" : "en";
}

/** The FCM HTTP v1 request body for one phone. */
export function buildMessage(token: string, kind: Kind, refId: string | null, locale: Locale) {
  const text = TEXT[kind][locale];
  return {
    message: {
      token,
      notification: { title: text.title, body: text.body },
      // Only ids: the app looks the details up itself, signed in as the student.
      data: { kind, ...(refId ? { ref_id: refId } : {}) },
      android: { priority: "HIGH", notification: { channel_id: "busin_updates" } },
      apns: { payload: { aps: { sound: "default" } } },
    },
  };
}

export type SendResult = { status: number; body: unknown };
export type Outcome = "sent" | "dead-token" | "retry" | "fatal";

/**
 * What an FCM answer means for us. A token Firebase no longer knows is forgotten; a hiccup is retried;
 * a refusal that retrying cannot fix (bad credentials, malformed request) is reported and not hammered.
 */
export function classify(result: SendResult): Outcome {
  if (result.status >= 200 && result.status < 300) return "sent";
  const details = JSON.stringify(result.body ?? "");
  if (result.status === 404 || details.includes("UNREGISTERED")) return "dead-token";
  if (result.status === 400 && details.includes("INVALID_ARGUMENT") && details.includes("registration token")) return "dead-token";
  if (result.status === 429 || result.status >= 500 || result.status === 0) return "retry";
  return "fatal";
}

export type Deps = {
  send: (message: ReturnType<typeof buildMessage>) => Promise<SendResult>;
  completeNotification: (id: number, error: string | null) => Promise<void>;
  dropToken: (token: string) => Promise<void>;
};

export type BatchReport = { processed: number; sent: number; deadTokens: number; failed: number };

/**
 * Sends each claimed notification to every phone of the student, then reports the outcome. A notification is
 * finished when every phone was reached or dropped as dead (including a student with no phones). If any phone
 * hit a retryable or fatal error it is reported as failed, so the database keeps it queued for another try
 * (up to five in all). A fatal error on one phone does not stop the others.
 */
export async function processBatch(deps: Deps, rows: Claimed[]): Promise<BatchReport> {
  const report: BatchReport = { processed: 0, sent: 0, deadTokens: 0, failed: 0 };

  for (const row of rows) {
    report.processed++;
    if (!isKind(row.kind)) {
      // A kind this version does not know: do not retry it forever.
      await deps.completeNotification(row.id, `unknown kind ${row.kind}`.slice(0, 300));
      report.failed++;
      continue;
    }

    let problem: string | null = null;
    for (const phone of row.tokens) {
      let result: SendResult;
      try {
        result = await deps.send(buildMessage(phone.token, row.kind, row.ref_id, asLocale(phone.locale)));
      } catch {
        result = { status: 0, body: "network error" };
      }
      const outcome = classify(result);
      if (outcome === "sent") {
        report.sent++;
      } else if (outcome === "dead-token") {
        await deps.dropToken(phone.token);
        report.deadTokens++;
      } else {
        problem = `${outcome}: ${result.status}`;
      }
    }

    await deps.completeNotification(row.id, problem);
    if (problem) report.failed++;
  }
  return report;
}

// ---------------------------------------------------------------------------- Google service account

export type ServiceAccount = { client_email: string; private_key: string; token_uri: string; project_id: string };

const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

function base64url(bytes: Uint8Array | string): string {
  const raw = typeof bytes === "string" ? new TextEncoder().encode(bytes) : bytes;
  let binary = "";
  for (const b of raw) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): Uint8Array {
  const body = pem.replace(/-----BEGIN [A-Z ]+-----/, "").replace(/-----END [A-Z ]+-----/, "").replace(/\s+/g, "");
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

/** The signed assertion Google exchanges for an access token (RS256, one hour). */
export async function createAssertion(account: ServiceAccount, nowSeconds: number): Promise<string> {
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(
    JSON.stringify({ iss: account.client_email, scope: SCOPE, aud: account.token_uri, iat: nowSeconds, exp: nowSeconds + 3600 }),
  );
  const key = await crypto.subtle.importKey("pkcs8", pemToDer(account.private_key), { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const signature = new Uint8Array(await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`)));
  return `${header}.${claims}.${base64url(signature)}`;
}

/** Compares two secrets without stopping at the first difference. */
export function sameSecret(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}
