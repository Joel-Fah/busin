"use server";

import { revalidatePath } from "next/cache";

import { requireAdmin } from "@/lib/auth";
import { supabaseConfig } from "@/lib/env";
import { isUuid } from "@/lib/ids";
import {
  isOpenPayment,
  normalizeCameroonPhone,
  parsePayoutProposal,
  parseRefundDecision,
  parseSchoolRefund,
  payoutErrorKey,
  refundErrorKey,
  type PaymentActionState,
} from "@/lib/payments";
import { isProvider, startErrorOf, type StartError } from "@/lib/student/mobile-money";
import { createClient } from "@/lib/supabase/server";


function refresh(): void {
  revalidatePath("/payments");
  revalidatePath("/subscriptions", "layout");
}

/**
 * Decides on a student's refund request: all of it, part of it, or declined with a reason they read. The database
 * function `admin_decide_refund` checks the administrator, the refund's state and the amount again, and audits it.
 */
export async function decideRefund(_previous: PaymentActionState, formData: FormData): Promise<PaymentActionState> {
  await requireAdmin();
  const parsed = parseRefundDecision(formData);
  if (!parsed.ok) return { ok: false, error: parsed.error };
  const { refund, approve, amount, note } = parsed.value;

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_decide_refund", {
    p_refund: refund,
    p_approve: approve,
    ...(amount !== null ? { p_amount: amount } : {}),
    ...(note !== null ? { p_note: note } : {}),
  });
  if (error) return { ok: false, error: refundErrorKey(error.code, error.message) };
  refresh();
  return { ok: true, done: approve ? "approved" : "declined" };
}

/** Refunds a completed payment on the school's own decision (`admin_refund_payment`), with an amount and a reason. */
export async function refundPayment(_previous: PaymentActionState, formData: FormData): Promise<PaymentActionState> {
  await requireAdmin();
  const parsed = parseSchoolRefund(formData);
  if (!parsed.ok) return { ok: false, error: parsed.error };
  const { payment, amount, reason } = parsed.value;

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_refund_payment", { p_payment: payment, p_amount: amount, p_reason: reason });
  if (error) return { ok: false, error: refundErrorKey(error.code, error.message) };
  refresh();
  return { ok: true, done: "refunded" };
}

/** Proposes the school's payout number; another administrator (or BusIn) confirms it. Replaces a proposal still waiting. */
export async function proposePayoutAccount(_previous: PaymentActionState, formData: FormData): Promise<PaymentActionState> {
  await requireAdmin();
  const parsed = parsePayoutProposal(formData);
  if (!parsed.ok) return { ok: false, error: parsed.error };
  const { provider, phone, name } = parsed.value;

  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_propose_payout_account", { p_provider: provider, p_phone: phone, p_account_name: name });
  if (error) return { ok: false, error: payoutErrorKey(error.code, error.message) };
  refresh();
  return { ok: true, done: "proposed" };
}

/** Confirms a proposed payout number. The database refuses the administrator who proposed it (`same_admin`). */
export async function confirmPayoutAccount(_previous: PaymentActionState, formData: FormData): Promise<PaymentActionState> {
  await requireAdmin();
  const account = formData.get("account");
  if (!isUuid(account)) return { ok: false, error: "not_found" };
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_confirm_payout_account", { p_account: account });
  if (error) return { ok: false, error: payoutErrorKey(error.code, error.message) };
  refresh();
  return { ok: true, done: "confirmed" };
}

/** Withdraws or refuses a proposed payout number. */
export async function declinePayoutAccount(_previous: PaymentActionState, formData: FormData): Promise<PaymentActionState> {
  await requireAdmin();
  const account = formData.get("account");
  if (!isUuid(account)) return { ok: false, error: "not_found" };
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_decline_payout_account", { p_account: account });
  if (error) return { ok: false, error: payoutErrorKey(error.code, error.message) };
  refresh();
  return { ok: true, done: "declined" };
}

// ---------------------------------------------------------------- paying BusIn's invoice

export type InvoicePaymentStart = { ok: true; paymentId: string; total: number } | { ok: false; error: StartError };
export type InvoicePaymentState = { status: string; failureCode: string | null; receiptNo: string | null } | null;

/**
 * Starts paying the school's open invoice by mobile money through the `payments` Edge Function, with the administrator's
 * own access token: the database decides what they may pay (`start_payment`, purpose `invoice`). The browser never talks
 * to pawaPay or holds a key; this only forwards.
 */
export async function startInvoicePayment(input: { invoice: string; phone: string; provider?: string | null }): Promise<InvoicePaymentStart> {
  await requireAdmin();
  if (!isUuid(input.invoice)) return { ok: false, error: "not_found" };
  if (typeof input.phone !== "string" || input.phone.length > 40 || !normalizeCameroonPhone(input.phone)) return { ok: false, error: "bad_phone" };

  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session) return { ok: false, error: "not_allowed" };
  const { url, key } = supabaseConfig();
  let response: Response;
  try {
    response = await fetch(`${url}/functions/v1/payments`, {
      method: "POST",
      headers: { authorization: `Bearer ${session.access_token}`, apikey: key, "content-type": "application/json" },
      body: JSON.stringify({
        action: "start",
        purpose: "invoice",
        target: input.invoice,
        phone: input.phone,
        ...(isProvider(input.provider) ? { provider: input.provider } : {}),
      }),
      cache: "no-store",
      // pawaPay answers within seconds; past this the payment, already stored, is finished by the reconciler.
      signal: AbortSignal.timeout(45_000),
    });
  } catch {
    return { ok: false, error: "payments_unavailable" };
  }
  let json: Record<string, unknown> | null = null;
  try {
    json = (await response.json()) as Record<string, unknown>;
  } catch {
    // A gateway error page: the status says enough.
  }
  if (response.status !== 200 || !json || typeof json.payment_id !== "string") return { ok: false, error: startErrorOf(response.status, json) };
  revalidatePath("/payments");
  return { ok: true, paymentId: json.payment_id, total: Number(json.total_xaf) || 0 };
}

/** Where a payment of the school's invoice stands, read through Row Level Security (the school's own payments only). */
export async function invoicePaymentState(paymentId: string): Promise<InvoicePaymentState> {
  await requireAdmin();
  if (!isUuid(paymentId)) return null;
  const supabase = await createClient();
  const { data } = await supabase.from("payments").select("status, failure_code, receipt_no").eq("id", paymentId).eq("purpose", "invoice").maybeSingle();
  if (!data) return null;
  if (!isOpenPayment(data.status)) revalidatePath("/payments");
  return { status: data.status, failureCode: data.failure_code, receiptNo: data.receipt_no };
}
