import { busLabel } from "@/lib/buses";
import { createClient } from "@/lib/supabase/server";

export type BusOption = { id: string; plate: string; name: string | null; label: string; inService: boolean };
export type DriverOption = { id: string; name: string };

// A school has a handful of buses and drivers. The caps keep the form light if that ever changes.
const MAX_OPTIONS = 200;

/**
 * What a trip can be given: buses in service (plus the bus the trip already has, even if it was
 * taken out of service since) and verified staff as drivers.
 */
export async function loadTripOptions(currentBusId?: string): Promise<{
  buses: BusOption[];
  drivers: DriverOption[];
  failed: boolean;
}> {
  const supabase = await createClient();
  const [buses, drivers] = await Promise.all([
    supabase.from("buses").select("id, plate, name, in_service").order("plate", { ascending: true }).limit(MAX_OPTIONS),
    supabase
      .from("profiles")
      .select("id, full_name, email")
      .eq("role", "staff")
      .eq("status", "verified")
      .order("full_name", { ascending: true })
      .limit(MAX_OPTIONS),
  ]);

  if (buses.error || drivers.error || !buses.data || !drivers.data) return { buses: [], drivers: [], failed: true };
  return {
    buses: buses.data
      .filter((bus) => bus.in_service || bus.id === currentBusId)
      .map((bus) => ({ id: bus.id, plate: bus.plate, name: bus.name, label: busLabel(bus), inService: bus.in_service })),
    drivers: drivers.data.map((row) => ({ id: row.id, name: row.full_name || row.email })),
    failed: false,
  };
}

/** Every bus and every staff member, for the column filters: a past trip may have a bus now out of service. */
export async function loadTripFilterOptions(): Promise<{ buses: { id: string; label: string }[]; drivers: DriverOption[] }> {
  const supabase = await createClient();
  const [buses, drivers] = await Promise.all([
    supabase.from("buses").select("id, plate, name").order("plate", { ascending: true }).limit(MAX_OPTIONS),
    supabase.from("profiles").select("id, full_name, email").eq("role", "staff").order("full_name", { ascending: true }).limit(MAX_OPTIONS),
  ]);
  return {
    buses: (buses.data ?? []).map((bus) => ({ id: bus.id, label: busLabel(bus) })),
    drivers: (drivers.data ?? []).map((row) => ({ id: row.id, name: row.full_name || row.email })),
  };
}
