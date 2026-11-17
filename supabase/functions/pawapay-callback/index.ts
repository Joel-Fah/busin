// pawaPay's callbacks (ADR 0029). pawaPay posts a payment's final status here and retries up to 8 times over about 25
// minutes until it gets a 200; the same callback may come more than once, and settle_payment applies it once. Refunds
// and payouts are answered 200 and left to their own slice for now (the reconciler asks their status).
//
// Signed callbacks (RFC 9421) are checked against pawaPay's public keys, fetched from pawaPay and kept in memory. With
// signing off (PAWAPAY_SIGNED_CALLBACKS=off, for a sandbox without it), the callback is only a nudge: the status is asked
// from pawaPay itself, and only for payments BusIn has.
//
// Secrets: PAWAPAY_API_TOKEN, PAWAPAY_BASE_URL (as for `payments`), PAWAPAY_CALLBACK_URL (the exact address given to
// pawaPay, which it signs), PAWAPAY_SIGNED_CALLBACKS ("on" by default).

import { createClient } from "npm:@supabase/supabase-js@2";

import { callbackSubject, pawaPay, readDeposit, settleArgs, verifyCallback } from "../_shared/pawapay.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

const service = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "", {
  auth: { persistSession: false },
});

let keys: { id: string; key: string }[] = [];
let keysFetchedAt = 0;

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const token = (Deno.env.get("PAWAPAY_API_TOKEN") ?? "").trim();
  const baseUrl = (Deno.env.get("PAWAPAY_BASE_URL") ?? "").trim();
  if (!token || !baseUrl) return json({ error: "payments_unavailable" }, 503);
  const client = pawaPay({ baseUrl, token, fetch });

  const raw = await request.text();
  if (raw.length > 20000) return json({ error: "too_large" }, 413);
  const signed = (Deno.env.get("PAWAPAY_SIGNED_CALLBACKS") ?? "on").toLowerCase() !== "off";

  if (signed) {
    const url = (Deno.env.get("PAWAPAY_CALLBACK_URL") ?? "").trim() || request.url;
    const check = () => verifyCallback({ method: request.method, url, headers: request.headers, body: raw }, keys, Math.floor(Date.now() / 1000));
    let verdict = await check();
    // A new key at pawaPay: fetch the keys again, at most every 10 minutes.
    if (!verdict.ok && verdict.reason === "bad_signature" && Date.now() - keysFetchedAt > 10 * 60 * 1000) {
      keys = await client.publicKeys();
      keysFetchedAt = Date.now();
      verdict = await check();
    }
    if (!verdict.ok) {
      console.error("callback refused", verdict.reason);
      return json({ error: "bad_signature" }, 401);
    }
  }

  let body: unknown;
  try {
    body = JSON.parse(raw);
  } catch {
    return json({ error: "bad_request" }, 400);
  }
  const subject = callbackSubject(body);
  if (!subject || subject.kind !== "deposit") return json({ ok: true, ignored: true });

  let args: Record<string, unknown> | null = null;
  if (signed) {
    const state = readDeposit(body);
    if (state) args = settleArgs(subject.id, state);
  } else {
    const { data: known } = await service.from("payments").select("id").eq("id", subject.id).maybeSingle();
    if (!known) return json({ ok: true, ignored: true });
    const state = await client.depositStatus(subject.id);
    if (state) args = settleArgs(subject.id, state);
  }
  if (!args) return json({ ok: true, ignored: true });

  const { error } = await service.rpc("settle_payment", args);
  // A database failure: answer an error so pawaPay tries again.
  if (error) return json({ error: "not_saved" }, 500);
  return json({ ok: true });
});
