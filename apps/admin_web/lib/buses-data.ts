import { createClient } from "@/lib/supabase/server";

export type BusRow = { id: string; plate: string; name: string | null; capacity: number; inService: boolean };

// A school runs a handful of buses. The cap keeps the page light if that ever changes.
const MAX_BUSES = 200;

/** Buses of the admin's school, by plate (the list shows the name and the plate). Row Level Security limits the rows to that school. */
export async function loadBuses(): Promise<{ buses: BusRow[]; failed: boolean }> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("buses")
    .select("id, plate, name, capacity, in_service")
    .order("plate", { ascending: true })
    .limit(MAX_BUSES);

  if (error || !data) return { buses: [], failed: true };
  return {
    buses: data.map((row) => ({ id: row.id, plate: row.plate, name: row.name, capacity: row.capacity, inService: row.in_service })),
    failed: false,
  };
}
