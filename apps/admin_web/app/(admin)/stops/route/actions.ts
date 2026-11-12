"use server";

import { revalidatePath } from "next/cache";

import { requireAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { createClient } from "@/lib/supabase/server";

export type RouteResult = { status: "saved" | "drawn" | "error"; error?: string };

/** Saves the order of the route. The database checks every stop is an active stop of the school, once each. */
export async function saveRouteOrder(stopIds: string[]): Promise<RouteResult> {
  await requireAdmin();
  if (!Array.isArray(stopIds) || stopIds.length === 0 || stopIds.length > 200 || !stopIds.every(isUuid)) return { status: "error", error: "empty_route" };
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_save_route", { p_stop_ids: stopIds });
  if (error) return { status: "error", error: error.code === "22023" ? error.message : "failed" };
  revalidatePath("/stops/route");
  return { status: "saved" };
}

/** Sets where the route ends: the campus point and its name. */
export async function saveCampus(lat: number, lng: number, name: string): Promise<RouteResult> {
  await requireAdmin();
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_set_campus", { p_lat: lat, p_lng: lng, p_name: name.trim().slice(0, 80) });
  if (error) return { status: "error", error: error.code === "22023" ? error.message : "failed" };
  revalidatePath("/stops/route");
  return { status: "saved" };
}

/**
 * Draws the saved route along roads through the route-directions function (Mapbox Directions with a server token,
 * ADR 0017). The function checks the admin again and counts the call.
 */
export async function drawRoute(): Promise<RouteResult> {
  await requireAdmin();
  const supabase = await createClient();
  try {
    const { data, error } = await supabase.functions.invoke("route-directions", { body: {} });
    if (error) {
      // The function answers with a JSON body naming the problem (no_token, too_many, no_campus, ...).
      const context = (error as { context?: Response }).context;
      const body = context && typeof context.json === "function" ? ((await context.json().catch(() => null)) as { error?: string } | null) : null;
      return { status: "error", error: body?.error ?? "unavailable" };
    }
    if (!(data as { stored?: boolean } | null)?.stored) return { status: "error", error: "stale" };
  } catch {
    return { status: "error", error: "unavailable" };
  }
  revalidatePath("/stops/route");
  return { status: "drawn" };
}
