// Sends the push notifications waiting in the outbox. Not called by apps: a scheduler or a database webhook calls it
// with the shared secret (docs/decisions/0010-push-notifications.md). All decisions are in ../_shared/push.ts, which
// has the tests; this file only connects them to the database and to Firebase.
//
// Secrets (set with `supabase secrets set`, never in git):
//   FIREBASE_SERVICE_ACCOUNT  the Firebase service account JSON (the Cloud Messaging sender)
//   PUSH_SECRET               a long random value the caller sends in the x-push-secret header
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by the platform.

import { createClient } from "npm:@supabase/supabase-js@2";

import { createAssertion, processBatch, sameSecret, type Claimed, type ServiceAccount } from "../_shared/push.ts";

const supabase = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "", {
  auth: { persistSession: false },
});

let cachedToken: { value: string; expiresAt: number } | null = null;

async function accessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 60 > now) return cachedToken.value;

  const response = await fetch(account.token_uri, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: await createAssertion(account, now) }),
  });
  if (!response.ok) throw new Error(`token exchange failed: ${response.status}`);
  const body = (await response.json()) as { access_token: string; expires_in: number };
  cachedToken = { value: body.access_token, expiresAt: now + body.expires_in };
  return body.access_token;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "method not allowed" }, 405);

  const expected = Deno.env.get("PUSH_SECRET") ?? "";
  if (expected.length < 32 || !sameSecret(request.headers.get("x-push-secret") ?? "", expected)) {
    return json({ error: "unauthorized" }, 401);
  }

  // Check the configuration before claiming anything: a claim counts as an attempt, so a misconfigured
  // deployment must not use up the notifications' tries.
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) return json({ error: "Firebase is not configured" }, 503);
  let account: ServiceAccount;
  try {
    account = JSON.parse(raw) as ServiceAccount;
  } catch {
    return json({ error: "FIREBASE_SERVICE_ACCOUNT is not valid JSON" }, 503);
  }

  const { data, error } = await supabase.rpc("claim_notifications", { p_limit: 50 });
  if (error) return json({ error: "could not claim notifications" }, 500);
  const rows = (data ?? []) as Claimed[];
  if (rows.length === 0) return json({ processed: 0, sent: 0, deadTokens: 0, failed: 0 });

  let token: string;
  try {
    token = await accessToken(account);
  } catch {
    // Nothing was sent: report each claimed notification as failed so it is tried again later.
    await Promise.all(rows.map((r) => supabase.rpc("complete_notification", { p_id: r.id, p_error: "could not get a Firebase access token" })));
    return json({ error: "could not authenticate with Firebase" }, 502);
  }

  const endpoint = `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`;
  const report = await processBatch(
    {
      send: async (message) => {
        const response = await fetch(endpoint, {
          method: "POST",
          headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
          body: JSON.stringify(message),
        });
        return { status: response.status, body: await response.json().catch(() => null) };
      },
      completeNotification: async (id, failure) => {
        await supabase.rpc("complete_notification", { p_id: id, p_error: failure });
      },
      dropToken: async (value) => {
        await supabase.rpc("drop_device_token", { p_token: value });
      },
    },
    rows,
  );
  return json(report);
});
