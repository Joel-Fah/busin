"use server";

import { revalidatePath } from "next/cache";

import { requireAdmin } from "@/lib/auth";
import type { LatLng } from "@/lib/geo";
import { isUuid } from "@/lib/ids";
import { createClient } from "@/lib/supabase/server";

export type RefreshState = { status: "idle" | "done" | "too_soon" | "failed" };

/** Counts the school's boardings again now (the database allows it once every five minutes and checks the admin). */
export async function refreshLoads(): Promise<RefreshState> {
  await requireAdmin();
  const supabase = await createClient();
  const { error } = await supabase.rpc("admin_refresh_stop_loads");
  if (error) return { status: error.code === "PT429" ? "too_soon" : "failed" };
  revalidatePath("/insights");
  return { status: "done" };
}

export type RoutePreview =
  | { status: "ok"; line: LatLng[]; legs: { from: string; to: string; distanceM: number; durationS: number }[]; distanceM: number; durationS: number }
  | { status: "error"; error: string };

/**
 * The school's route with suggested stops put in, drawn along roads by the route-directions function (a preview: nothing
 * is stored). The function checks the admin and counts the call; without a token it says so and the page estimates.
 */
export async function previewRoute(stopIds: string[], extras: { lat: number; lng: number; name: string; after: number }[]): Promise<RoutePreview> {
  await requireAdmin();
  if (!Array.isArray(stopIds) || stopIds.length === 0 || stopIds.length > 200 || !stopIds.every(isUuid)) return { status: "error", error: "bad_request" };
  if (!Array.isArray(extras) || extras.length === 0 || extras.length > 10) return { status: "error", error: "bad_request" };
  const supabase = await createClient();
  try {
    const { data, error } = await supabase.functions.invoke("route-directions", { body: { preview: { stopIds, extras } } });
    if (error) {
      const context = (error as { context?: Response }).context;
      const body = context && typeof context.json === "function" ? ((await context.json().catch(() => null)) as { error?: string } | null) : null;
      return { status: "error", error: body?.error ?? "unavailable" };
    }
    const road = data as { geometry?: { coordinates?: [number, number][] }; legs?: { from: string; to: string; distance_m: number; duration_s: number }[]; distance_m?: number; duration_s?: number } | null;
    const coords = road?.geometry?.coordinates ?? [];
    if (coords.length < 2) return { status: "error", error: "routing_failed" };
    return {
      status: "ok",
      line: coords.map(([lng, lat]) => ({ lat, lng })),
      legs: (road?.legs ?? []).map((l) => ({ from: l.from, to: l.to, distanceM: l.distance_m, durationS: l.duration_s })),
      distanceM: road?.distance_m ?? 0,
      durationS: road?.duration_s ?? 0,
    };
  } catch {
    return { status: "error", error: "unavailable" };
  }
}
