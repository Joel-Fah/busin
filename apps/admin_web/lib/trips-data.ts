import { createClient } from "@/lib/supabase/server";

export type BusOption = { id: string; plate: string; inService: boolean };
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
    supabase.from("buses").select("id, plate, in_service").order("plate", { ascending: true }).limit(MAX_OPTIONS),
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
      .map((bus) => ({ id: bus.id, plate: bus.plate, inService: bus.in_service })),
    drivers: drivers.data.map((row) => ({ id: row.id, name: row.full_name || row.email })),
    failed: false,
  };
}
