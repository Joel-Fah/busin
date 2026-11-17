"use server";

import { supabaseConfig } from "@/lib/env";
import { createClient } from "@/lib/supabase/server";

import { isProvider, normalizeCameroonPhone, startErrorOf, type StartError } from "./mobile-money";
import { requireStudent } from "./session";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export type StartedPayment = { paymentId: string; status: string; failureCode: string | null; amount: number; fee: number; total: number; provider: string };
export type StartResult = { ok: true; payment: StartedPayment } | { ok: false; error: StartError };
export type CheckResult = { ok: true; status: string; failureCode: string | null } | { ok: false; error: StartError };

/**
 * Calls the `payments` Edge Function (ADR 0029) as the signed-in student: their own access token, so the database
 * decides what they may pay. The browser never talks to pawaPay or holds a key; this server action only forwards.
 */
async function callPayments(body: Record<string, unknown>): Promise<{ status: number; json: unknown } | { offline: true }> {
  await requireStudent();
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session) return { status: 401, json: { error: "not_allowed" } };
  const { url, key } = supabaseConfig();
  let response: Response;
  try {
    response = await fetch(`${url}/functions/v1/payments`, {
      method: "POST",
      headers: { authorization: `Bearer ${session.access_token}`, apikey: key, "content-type": "application/json" },
      body: JSON.stringify(body),
      cache: "no-store",
      // pawaPay answers within seconds; past this the payment, already stored, is finished by the reconciler.
      signal: AbortSignal.timeout(45_000),
    });
  } catch {
    return { offline: true };
  }
  let json: unknown = null;
  try {
    json = await response.json();
  } catch {
    // A gateway error page: the status says enough.
  }
  return { status: response.status, json };
}

/**
 * Starts paying a pending request ("subscription") or a later part ("installment") by mobile money. The operator is
 * sent only when the student chose it; otherwise the function asks pawaPay which network the number is on.
 */
export async function startMobileMoneyPayment(input: { purpose: string; target: string; phone: string; provider?: string | null }): Promise<StartResult> {
  if ((input.purpose !== "subscription" && input.purpose !== "installment") || !UUID.test(input.target)) return { ok: false, error: "not_found" };
  if (typeof input.phone !== "string" || input.phone.length > 40 || !normalizeCameroonPhone(input.phone)) return { ok: false, error: "bad_phone" };
  const result = await callPayments({
    action: "start",
    purpose: input.purpose,
    target: input.target,
    phone: input.phone,
    ...(isProvider(input.provider) ? { provider: input.provider } : {}),
  });
  if ("offline" in result) return { ok: false, error: "payments_unavailable" };
  const json = result.json as Record<string, unknown> | null;
  if (result.status !== 200 || !json || typeof json.payment_id !== "string") return { ok: false, error: startErrorOf(result.status, json) };
  return {
    ok: true,
    payment: {
      paymentId: json.payment_id,
      status: String(json.status ?? "initiated"),
      failureCode: typeof json.failure_code === "string" ? json.failure_code : null,
      amount: Number(json.amount_xaf),
      fee: Number(json.fee_xaf),
      total: Number(json.total_xaf),
      provider: String(json.provider ?? ""),
    },
  };
}

/** Asks pawaPay again about the student's own payment ("I approved, check again") and answers where it stands. */
export async function checkMobileMoneyPayment(paymentId: string): Promise<CheckResult> {
  if (typeof paymentId !== "string" || !UUID.test(paymentId)) return { ok: false, error: "not_found" };
  const result = await callPayments({ action: "check", payment_id: paymentId });
  if ("offline" in result) return { ok: false, error: "payments_unavailable" };
  const json = result.json as Record<string, unknown> | null;
  if (result.status !== 200 || !json || typeof json.status !== "string") return { ok: false, error: startErrorOf(result.status, json) };
  return { ok: true, status: json.status, failureCode: typeof json.failure_code === "string" ? json.failure_code : null };
}
