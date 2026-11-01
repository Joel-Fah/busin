"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireAdmin } from "@/lib/auth";
import { isUuid } from "@/lib/ids";
import { parseTripForm, tripSaveErrorKey, type TripFormErrorKey, type TripInput } from "@/lib/trips";
import { createClient } from "@/lib/supabase/server";

/**
 * Business rules the database does not state: a trip goes on a bus that is in service (or the bus
 * it already has) and on a verified staff member. Row Level Security still limits every row to
 * the admin's school, and the foreign keys keep both inside that school.
 */
async function checkAssignments(
  input: TripInput,
  currentBusId?: string,
): Promise<Extract<TripFormErrorKey, "bus_unavailable" | "driver_unavailable" | "generic"> | null> {
  const supabase = await createClient();

  const { data: bus, error: busError } = await supabase
    .from("buses")
    .select("id, in_service")
    .eq("id", input.busId)
    .maybeSingle();
  if (busError) return "generic";
  if (!bus || (!bus.in_service && bus.id !== currentBusId)) return "bus_unavailable";

  if (input.driverId) {
    const { data: driver, error: driverError } = await supabase
      .from("profiles")
      .select("id")
      .eq("id", input.driverId)
      .eq("role", "staff")
      .eq("status", "verified")
      .maybeSingle();
    if (driverError) return "generic";
    if (!driver) return "driver_unavailable";
  }
  return null;
}

/** Schedules a trip for the admin's school. */
export async function createTrip(formData: FormData): Promise<void> {
  const admin = await requireAdmin();

  const parsed = parseTripForm(formData, admin.schoolTimezone);
  if (!parsed.ok) redirect(`/trips/new?error=${parsed.error}`);
  const { busId, driverId, direction, scheduledStart } = parsed.value;

  const problem = await checkAssignments(parsed.value);
  if (problem) redirect(`/trips/new?error=${problem}`);

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("trips")
    .insert({
      school_id: admin.schoolId,
      bus_id: busId,
      driver_id: driverId,
      direction,
      scheduled_start: scheduledStart,
    })
    .select("id")
    .single();
  if (error || !data) redirect(`/trips/new?error=${tripSaveErrorKey(error?.code)}`);

  revalidatePath("/trips");
  redirect(`/trips/${data.id}?done=created`);
}

/**
 * Saves changes to a trip that has not started. The status filter in the update means a trip that
 * is active, finished or cancelled matches no row, so it cannot be changed from here.
 */
export async function updateTrip(formData: FormData): Promise<void> {
  const admin = await requireAdmin();

  const id = formData.get("id");
  if (!isUuid(id)) redirect("/trips");

  const parsed = parseTripForm(formData, admin.schoolTimezone);
  if (!parsed.ok) redirect(`/trips/${id}?error=${parsed.error}`);
  const { busId, driverId, direction, scheduledStart } = parsed.value;

  const supabase = await createClient();
  const { data: current } = await supabase
    .from("trips")
    .select("bus_id")
    .eq("id", id)
    .eq("status", "scheduled")
    .maybeSingle();
  if (!current) redirect(`/trips/${id}?error=not_editable`);

  const problem = await checkAssignments(parsed.value, current.bus_id);
  if (problem) redirect(`/trips/${id}?error=${problem}`);

  const { error } = await supabase
    .from("trips")
    .update({ bus_id: busId, driver_id: driverId, direction, scheduled_start: scheduledStart })
    .eq("id", id)
    .eq("status", "scheduled")
    .select("id")
    .single();
  if (error) redirect(`/trips/${id}?error=${tripSaveErrorKey(error.code)}`);

  revalidatePath("/trips");
  redirect(`/trips/${id}?done=saved`);
}
