// Finishes payments whose result never arrived, and sends refunds (ADR 0029): every two minutes the scheduler calls
// this with a shared secret (private.dispatch_payment_checks, Vault names payments_reconcile_url and
// payments_reconcile_secret) when a payment has been open for more than two minutes or a refund waits. Each payment's
// status is asked from pawaPay and applied once through settle_payment; one pawaPay has never heard of is failed after
// 15 minutes. Refunds waiting are sent (their id is pawaPay's idempotency key, so sending twice is safe), and those
// sent are checked, through settle_refund. Payouts planned on Monday (private.plan_payouts) are sent and checked the
// same way, through settle_payout. Once a day it also records pawaPay's wallet balance beside what the books say it
// should hold (platform console, ADR 0029).
//
// Secrets: PAYMENTS_RECONCILE_SECRET (sent in the x-reconcile-secret header), PAWAPAY_API_TOKEN, PAWAPAY_BASE_URL.

import { createClient } from "npm:@supabase/supabase-js@2";

import { isProvider, pawaPay, settleArgs, settleRefundArgs } from "../_shared/pawapay.ts";
import { sameSecret } from "../_shared/push.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

const service = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "", {
  auth: { persistSession: false },
});

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const expected = Deno.env.get("PAYMENTS_RECONCILE_SECRET") ?? "";
  if (!expected || !sameSecret(request.headers.get("x-reconcile-secret") ?? "", expected)) return json({ error: "forbidden" }, 403);
  const token = (Deno.env.get("PAWAPAY_API_TOKEN") ?? "").trim();
  const baseUrl = (Deno.env.get("PAWAPAY_BASE_URL") ?? "").trim();
  if (!token || !baseUrl) return json({ error: "payments_unavailable" }, 503);
  const client = pawaPay({ baseUrl, token, fetch });

  const { data, error } = await service.rpc("payments_to_check", { p_limit: 50 });
  if (error) return json({ error: "could not read the open payments" }, 500);
  const ids = ((data ?? []) as { id: string }[]).map((r) => r.id);

  let settled = 0;
  let unanswered = 0;
  // A few at a time, to stay well inside pawaPay's limits.
  for (let i = 0; i < ids.length; i += 5) {
    await Promise.all(
      ids.slice(i, i + 5).map(async (id) => {
        const state = await client.depositStatus(id);
        if (!state) {
          unanswered++;
          return;
        }
        const { error } = await service.rpc("settle_payment", settleArgs(id, state));
        if (!error) settled++;
      }),
    );
  }
  // Refunds: send those waiting, check those sent.
  const { data: due, error: dueError } = await service.rpc("refunds_to_send", { p_limit: 50 });
  if (dueError) return json({ error: "could not read the refunds" }, 500);
  let refunds = 0;
  for (const r of (due ?? []) as { id: string; payment_id: string; total_xaf: number; action: string }[]) {
    if (r.action === "send") {
      const sent = await client.initiateRefund({ id: r.id, depositId: r.payment_id, amountXaf: r.total_xaf });
      if (sent.kind === "accepted" || sent.kind === "duplicate") {
        await service.rpc("settle_refund", { p_id: r.id, p_status: sent.kind === "accepted" ? "ACCEPTED" : "DUPLICATE_IGNORED" });
      } else if (sent.kind === "rejected") {
        await service.rpc("settle_refund", { p_id: r.id, p_status: "REJECTED", p_failure_code: sent.failureCode });
      } else {
        // No clear answer: ask; if pawaPay has it, apply it, otherwise it stays queued and is sent again next time.
        const state = await client.refundStatus(r.id);
        if (state?.found) await service.rpc("settle_refund", settleRefundArgs(r.id, state));
      }
    } else {
      const state = await client.refundStatus(r.id);
      if (state) await service.rpc("settle_refund", settleRefundArgs(r.id, state));
    }
    refunds++;
  }
  // Payouts: the same, to the school's confirmed number.
  const { data: owed, error: owedError } = await service.rpc("payouts_to_send", { p_limit: 50 });
  if (owedError) return json({ error: "could not read the payouts" }, 500);
  let payouts = 0;
  for (const p of (owed ?? []) as { id: string; amount_xaf: number; provider: string; phone: string; action: string }[]) {
    if (p.action === "send" && isProvider(p.provider)) {
      const sent = await client.initiatePayout({ id: p.id, phone: p.phone, provider: p.provider, amountXaf: p.amount_xaf });
      if (sent.kind === "accepted" || sent.kind === "duplicate") {
        await service.rpc("settle_payout", { p_id: p.id, p_status: sent.kind === "accepted" ? "ACCEPTED" : "DUPLICATE_IGNORED" });
      } else if (sent.kind === "rejected") {
        await service.rpc("settle_payout", { p_id: p.id, p_status: "REJECTED", p_failure_code: sent.failureCode });
      } else {
        const state = await client.payoutStatus(p.id);
        if (state?.found) await service.rpc("settle_payout", settleRefundArgs(p.id, state));
      }
    } else if (p.action === "check") {
      const state = await client.payoutStatus(p.id);
      if (state) await service.rpc("settle_payout", settleRefundArgs(p.id, state));
    }
    payouts++;
  }
  // The wallet against the books, once a day.
  let wallet: number | null = null;
  const { data: snapshotDue } = await service.rpc("wallet_snapshot_due");
  if (snapshotDue === true) {
    wallet = await client.walletXaf();
    if (wallet !== null) await service.rpc("record_wallet_balance", { p_balance_xaf: wallet });
  }
  return json({ checked: ids.length, settled, unanswered, refunds, payouts, wallet: wallet !== null });
});
