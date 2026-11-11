// Draws the school's bus route along roads with Mapbox Directions (ADR 0017). Called by the admin portal's server with
// the admin's own token; the database checks the admin, counts the call (30 an hour, 300 a day per school) and returns
// the waypoints. The road is stored on the route, or, for a preview (a suggested route), only returned. The logic lives
// in ../_shared/route.ts, which has the tests.
//
// Body: {} to draw the saved route; or { preview: { stopIds: string[], extras?: [{ lat, lng, name, after }] } } (at most
// 10 extras, each after the stop at that position, -1 before the first).
// Secrets (never in git): MAPBOX_DIRECTIONS_TOKEN, a server token allowed to use Directions. Locally in
// supabase/functions/.env; on a hosted project with `supabase secrets set`. SUPABASE_URL, SUPABASE_ANON_KEY and
// SUPABASE_SERVICE_ROLE_KEY are provided by the platform.

import { createClient } from "npm:@supabase/supabase-js@2";

import { drawRoad, RoutingError, type Waypoint } from "../_shared/route.ts";

type Extra = { lat: number; lng: number; name?: string; after: number };
type Preview = { stopIds: string[]; extras?: Extra[] };

/** The `sub` of a JWT the platform has already verified, or null. */
function subjectOf(jwt: string): string | null {
  try {
    const payload = JSON.parse(atob(jwt.split(".")[1].replace(/-/g, "+").replace(/_/g, "/"))) as { sub?: unknown };
    return typeof payload.sub === "string" ? payload.sub : null;
  } catch {
    return null;
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

const service = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "", {
  auth: { persistSession: false },
});

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const token = (Deno.env.get("MAPBOX_DIRECTIONS_TOKEN") ?? "").trim();
  if (!token) return json({ error: "no_token" }, 503);

  const authorization = request.headers.get("authorization") ?? "";
  if (!authorization.toLowerCase().startsWith("bearer ")) return json({ error: "unauthorized" }, 401);
  // The admin's own client: the database decides what they may do.
  const user = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
    auth: { persistSession: false },
    global: { headers: { authorization } },
  });

  let preview: Preview | undefined;
  try {
    const body = (await request.json().catch(() => ({}))) as { preview?: Preview };
    preview = body.preview;
  } catch {
    return json({ error: "bad_request" }, 400);
  }
  if (preview && (!Array.isArray(preview.stopIds) || preview.stopIds.length > 200 || (preview.extras !== undefined && (!Array.isArray(preview.extras) || preview.extras.length > 10)))) {
    return json({ error: "bad_request" }, 400);
  }
  const extras = preview?.extras ?? [];

  const { data, error } = await user.rpc("route_waypoints", {
    p_stop_ids: preview?.stopIds ?? null,
    p_extra_lats: extras.length ? extras.map((e) => e.lat) : null,
    p_extra_lngs: extras.length ? extras.map((e) => e.lng) : null,
    p_extra_names: extras.length ? extras.map((e) => e.name ?? "") : null,
    p_extra_afters: extras.length ? extras.map((e) => e.after) : null,
  });
  if (error) {
    if (error.code === "PT429") return json({ error: "too_many" }, 429);
    if (error.code === "42501") return json({ error: "forbidden" }, 403);
    if (error.code === "22023") return json({ error: error.message }, 400);
    return json({ error: "failed" }, 500);
  }
  const rows = (data ?? []) as (Waypoint & { route_hash: string | null })[];
  const points: Waypoint[] = rows.map(({ seq, kind, id, name, lat, lng }) => ({ seq, kind, id, name, lat, lng }));

  let road;
  try {
    road = await drawRoad(points, token, (url) => fetch(url));
  } catch (e) {
    const code = e instanceof RoutingError ? e.code : "routing_failed";
    return json({ error: code }, code === "too_few_points" ? 400 : 502);
  }

  if (!preview) {
    // Who is calling: the platform has already verified the token (verify_jwt), so its subject names the admin.
    const userId = subjectOf(authorization.slice(7).trim());
    const { data: profile } = userId ? await user.from("profiles").select("school_id").eq("id", userId).single() : { data: null };
    const school = profile?.school_id as string | undefined;
    const hash = rows[0]?.route_hash ?? null;
    if (school && hash) {
      const { data: stored } = await service.rpc("service_store_route", {
        p_school: school,
        p_hash: hash,
        p_geojson: JSON.stringify(road.geometry),
        p_distance_m: road.distance_m,
        p_duration_s: road.duration_s,
        p_legs: road.legs,
      });
      return json({ ...road, stored: stored === true });
    }
  }
  return json({ ...road, stored: false });
});
