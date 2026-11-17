// Mobile money payments (ADR 0029). Called by the student apps (and the portal, for BusIn's invoice) with the person's
// own session. The database decides what may be paid and writes the payment first (start_payment); only then is pawaPay
// asked to send the PIN prompt. Whatever pawaPay answers, or if it does not answer, the result goes through
// settle_payment, and the callback and the reconciler finish the rest. The rules live in ../_shared/pawapay.ts, which
// has the tests.
//
// Body:
//   { action: "start", purpose: "subscription" | "installment" | "invoice", target: uuid, phone: string, provider? }
//     `provider` only when the payer chose the operator themselves; otherwise pawaPay predicts it from the number.
//     Answers { payment_id, status, failure_code, amount_xaf, fee_xaf, total_xaf, provider }.
//   { action: "check", payment_id: uuid }  asks pawaPay now about the caller's own open payment; answers its status.
// Refusals answer { error: code } (see ../_shared/payments-errors.ts).
//
// Secrets (never in git; locally in supabase/functions/.env, hosted with `supabase secrets set`):
//   PAWAPAY_API_TOKEN  the API token from pawaPay's dashboard (sandbox or production)
//   PAWAPAY_BASE_URL   https://api.sandbox.pawapay.io or https://api.pawapay.io
// SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are provided by the platform.

import { createClient } from "npm:@supabase/supabase-js@2";

import { guessProvider, isProvider, normalizeCameroonPhone, pawaPay, settleArgs, type Provider } from "../_shared/pawapay.ts";
import { refusal } from "../_shared/payments-errors.ts";

const OPEN = ["initiated", "accepted", "processing", "in_reconciliation"];
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

const service = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "", {
  auth: { persistSession: false },
});

async function settle(args: Record<string, unknown>): Promise<void> {
  const { error } = await service.rpc("settle_payment", args);
  // The callback or the reconciler will finish it; the payment is already stored.
  if (error) console.error("settle_payment failed", error.code);
}

async function statusOf(id: string) {
  const { data } = await service.from("payments").select("status, failure_code").eq("id", id).maybeSingle();
  return data as { status: string; failure_code: string | null } | null;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const token = (Deno.env.get("PAWAPAY_API_TOKEN") ?? "").trim();
  const baseUrl = (Deno.env.get("PAWAPAY_BASE_URL") ?? "").trim();
  if (!token || !/^https:\/\/api(\.sandbox)?\.pawapay\.io\/?$/.test(baseUrl)) return json({ error: "payments_unavailable" }, 503);
  const client = pawaPay({ baseUrl, token, fetch });

  const authorization = request.headers.get("authorization") ?? "";
  if (!authorization.toLowerCase().startsWith("bearer ")) return json({ error: "unauthorized" }, 401);
  // The caller's own client: the database decides what they may pay and read.
  const user = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
    auth: { persistSession: false },
    global: { headers: { authorization } },
  });

  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return json({ error: "bad_request" }, 400);
  }

  if (body.action === "check") {
    const id = typeof body.payment_id === "string" && UUID.test(body.payment_id) ? body.payment_id.toLowerCase() : null;
    if (!id) return json({ error: "bad_request" }, 400);
    const { data: own } = await user.from("payments").select("id, status").eq("id", id).maybeSingle();
    if (!own) return json({ error: "not_found" }, 404);
    if (OPEN.includes(own.status as string)) {
      const state = await client.depositStatus(id);
      if (state) await settle(settleArgs(id, state));
    }
    return json({ payment_id: id, ...(await statusOf(id)) });
  }

  if (body.action !== "start") return json({ error: "bad_request" }, 400);
  const phone = normalizeCameroonPhone(body.phone);
  if (!phone) return json({ error: "bad_phone" }, 400);
  let provider: Provider | null = isProvider(body.provider) ? body.provider : null;
  if (!provider) {
    const predicted = await client.predictProvider(phone);
    provider = predicted && isProvider(predicted.provider) ? predicted.provider : guessProvider(phone);
  }
  if (!provider) return json({ error: "unknown_provider" }, 400);

  const { data, error } = await user.rpc("start_payment", {
    p_purpose: body.purpose,
    p_target: body.target,
    p_provider: provider,
    p_phone: phone,
  });
  if (error) {
    const { status, code } = refusal(error);
    return json({ error: code }, status);
  }
  const row = (Array.isArray(data) ? data[0] : data) as { id: string; amount_xaf: number; fee_xaf: number; total_xaf: number };

  const initiation = await client.initiateDeposit({ id: row.id, phone, provider, totalXaf: row.total_xaf });
  if (initiation.kind === "accepted") {
    await settle({ p_id: row.id, p_status: "ACCEPTED" });
  } else if (initiation.kind === "rejected") {
    await settle({ p_id: row.id, p_status: "REJECTED", p_failure_code: initiation.failureCode, p_failure_message: initiation.failureMessage });
  } else if (initiation.kind === "unknown") {
    // No clear answer: pawaPay may still have it. Ask once now; the reconciler keeps asking after that.
    const state = await client.depositStatus(row.id);
    if (state?.found) await settle(settleArgs(row.id, state));
  }

  const now = await statusOf(row.id);
  return json({
    payment_id: row.id,
    status: now?.status ?? "initiated",
    failure_code: now?.failure_code ?? null,
    amount_xaf: row.amount_xaf,
    fee_xaf: row.fee_xaf,
    total_xaf: row.total_xaf,
    provider,
  });
});
