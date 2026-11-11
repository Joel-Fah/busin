// Place search for "My area" (docs/decisions/0013-coarse-home-area.md). Called by the student app with the student's
// own token. All decisions are in ../_shared/places.ts, which has the tests; this file only connects them.
//
// Secret (set with `supabase secrets set`, never in git; locally from supabase/.env):
//   MAPBOX_API_KEY  a Mapbox token allowed to geocode, without a URL restriction (a server sends no referrer)
// SUPABASE_URL and SUPABASE_ANON_KEY are provided by the platform.

import { createClient } from "npm:@supabase/supabase-js@2";

import { cleanQuery, mapboxUrl, parsePlaces, type Bias } from "../_shared/places.ts";

const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "content-type": "application/json" } });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response(null, { headers: cors });
  if (request.method !== "POST") return json({ error: "method not allowed" }, 405);

  const authorization = request.headers.get("authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return json({ error: "unauthorized" }, 401);

  let input: { q?: unknown; language?: unknown };
  try {
    input = await request.json();
  } catch {
    return json({ error: "invalid body" }, 400);
  }
  const query = cleanQuery(input.q);
  if (!query) return json({ places: [] });

  // Trimmed: a stray space or line ending in the secret would make every search come back empty.
  const token = (Deno.env.get("MAPBOX_API_KEY") ?? "").trim();
  if (!token) return json({ error: "search is not configured" }, 503);

  // The student's own token: the database checks who they are and counts the search.
  const supabase = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
    auth: { persistSession: false },
    global: { headers: { authorization } },
  });
  const { data, error } = await supabase.rpc("claim_place_search");
  if (error) {
    if (error.code === "PT429") return json({ error: "too many searches" }, 429);
    if (error.code === "42501") return json({ error: "forbidden" }, 403);
    return json({ error: "could not search" }, 500);
  }
  const bias = ((data ?? []) as Bias[])[0] ?? null;

  const response = await fetch(mapboxUrl(query, bias, typeof input.language === "string" ? input.language : "en", token));
  if (!response.ok) return json({ error: "search failed" }, 502);
  return json({ places: parsePlaces(await response.json()) });
});
