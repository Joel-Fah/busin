"use server";

import { revalidatePath } from "next/cache";

import { createClient } from "@/lib/supabase/server";

import { requireStudent } from "./session";

export type SettingsState = { saved: boolean; error: boolean };

/**
 * Saves what BusIn may tell the student: bus days (a bitmask, Monday = bit 0), bus near my stop and how many minutes
 * before, and the word when they board. Morning and evening reminders exist only in the app (ADR 0021): the web form
 * does not show them, so their saved values are passed back unchanged.
 */
export async function saveNotifications(_previous: SettingsState, formData: FormData): Promise<SettingsState> {
  await requireStudent();
  const supabase = await createClient();
  const { data: current, error: readError } = await supabase.rpc("my_notification_preferences");
  const now = current?.[0];
  if (readError || !now) return { saved: false, error: true };

  let days = 0;
  for (let day = 0; day < 7; day++) if (formData.get(`day${day}`) === "on") days |= 1 << day;
  const minutes = Number(formData.get("busNearMinutes"));
  const { error } = await supabase.rpc("set_notification_preferences", {
    p_riding_days: days,
    p_morning_on: now.morning_on,
    p_morning_time: now.morning_time.slice(0, 5),
    p_evening_on: now.evening_on,
    p_evening_time: now.evening_time.slice(0, 5),
    p_bus_near_on: formData.get("busNear") === "on",
    p_bus_near_minutes: Number.isInteger(minutes) && minutes >= 1 && minutes <= 30 ? minutes : now.bus_near_minutes,
    p_boarding_messages_on: formData.get("boarding") === "on",
  });
  if (error) return { saved: false, error: true };
  revalidatePath("/app/settings/notifications");
  return { saved: true, error: false };
}

/** Turns streaks (and the leaderboard place that comes with them) on or off. */
export async function setStreaks(formData: FormData): Promise<void> {
  await requireStudent();
  const supabase = await createClient();
  await supabase.rpc("set_streak_opt_in", { p_on: formData.get("on") === "true" });
  revalidatePath("/app/streaks");
}

/** How the student prefers to pay (ADR 0022), or null to forget it. Used after a request and from the profile. */
export async function setPaymentPreference(mode: "full" | "installments" | null): Promise<boolean> {
  await requireStudent();
  if (mode !== null && mode !== "full" && mode !== "installments") return false;
  const supabase = await createClient();
  // The generated types do not mark function arguments as nullable; the function takes null to mean "not chosen".
  const { error } = await supabase.rpc("set_payment_preference", { p_preference: mode as string });
  revalidatePath("/app/profile");
  revalidatePath("/app/subscription");
  revalidatePath("/app/settings/payment");
  return !error;
}
