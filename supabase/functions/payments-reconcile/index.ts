// Finishes payments whose result never arrived (ADR 0029): every two minutes the scheduler calls this with a shared
// secret (private.dispatch_payment_checks, Vault names payments_reconcile_url and payments_reconcile_secret) when a
// payment has been open for more than two minutes. Each one's status is asked from pawaPay and applied once through
// settle_payment; one pawaPay has never heard of is failed after 15 minutes.
//
// Secrets: PAYMENTS_RECONCILE_SECRET (sent in the x-reconcile-secret header), PAWAPAY_API_TOKEN, PAWAPAY_BASE_URL.

import { createClient } from "npm:@supabase/supabase-js@2";

import { pawaPay, settleArgs } from "../_shared/pawapay.ts";
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
  return json({ checked: ids.length, settled, unanswered });
});
