// Erases the accounts whose deletion is due (ADR 0028). Not called by apps: the nightly scheduler calls it with the
// shared secret (private.dispatch_deletions, Vault names deletions_url and deletions_secret). The order and the failure
// rules are in ../_shared/erase.ts, which has the tests; this file connects them to Storage, Auth and the database.
//
// Secrets (set with `supabase secrets set`, never in git):
//   DELETIONS_SECRET  a long random value the caller sends in the x-deletions-secret header
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by the platform.

import { createClient } from "npm:@supabase/supabase-js@2";

import { eraseDue, type DueAccount } from "../_shared/erase.ts";
import { sameSecret } from "../_shared/push.ts";

const supabase = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "", {
  auth: { persistSession: false },
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "method not allowed" }, 405);
  const expected = Deno.env.get("DELETIONS_SECRET") ?? "";
  if (!expected || !sameSecret(request.headers.get("x-deletions-secret") ?? "", expected)) return json({ error: "forbidden" }, 403);

  const { data, error } = await supabase.rpc("due_account_deletions");
  if (error) return json({ error: "could not read the due accounts" }, 500);

  const outcome = await eraseDue((data ?? []) as DueAccount[], {
    async removeFiles(paths) {
      const { error } = await supabase.storage.from("proofs").remove(paths);
      if (error) throw new Error(error.message);
    },
    async deleteSignIn(userId) {
      const { error } = await supabase.auth.admin.deleteUser(userId, true);
      if (error) throw new Error(error.message);
    },
    async eraseProfile(userId) {
      const { error } = await supabase.rpc("erase_account", { p_user_id: userId });
      if (error) throw new Error(error.message);
    },
  });
  return json(outcome, outcome.failed.length > 0 ? 207 : 200);
});
