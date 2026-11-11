"use server";

import { revalidatePath } from "next/cache";

import { requireAdmin } from "@/lib/auth";
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
