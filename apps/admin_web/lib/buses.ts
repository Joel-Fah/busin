/** Pure helpers for the buses pages. Kept separate so they are unit tested. */

export const MAX_PLATE_LENGTH = 20;
export const MAX_CAPACITY = 200;

export type BusInput = { plate: string; capacity: number; inService: boolean };

export type BusFormError = "plate" | "capacity";

/** Plates are stored in capitals with single spaces, so "lt 123  ab" and "LT 123 AB" are the same bus. */
export function normalizePlate(raw: unknown): string {
  return typeof raw === "string" ? raw.trim().replace(/\s+/g, " ").toUpperCase() : "";
}

/** Validates the bus form fields. The database repeats these rules; this gives clear messages. */
export function parseBusForm(form: {
  get(name: string): unknown;
}): { ok: true; value: BusInput } | { ok: false; error: BusFormError } {
  const plate = normalizePlate(form.get("plate"));
  if (plate.length < 1 || plate.length > MAX_PLATE_LENGTH) return { ok: false, error: "plate" };

  const rawCapacity = form.get("capacity");
  const text = typeof rawCapacity === "string" ? rawCapacity.trim() : "";
  const capacity = /^\d{1,3}$/.test(text) ? Number(text) : NaN;
  if (!Number.isInteger(capacity) || capacity < 1 || capacity > MAX_CAPACITY) return { ok: false, error: "capacity" };

  // An unchecked box is simply absent from the form.
  return { ok: true, value: { plate, capacity, inService: form.get("in_service") === "on" } };
}

export type BusSaveErrorKey = "plate_taken" | "invalid" | "not_found" | "generic";

/** Maps a database error code from saving a bus. 23505 is the unique plate per school. */
export function busSaveErrorKey(code: string | undefined): BusSaveErrorKey {
  switch (code) {
    case "23505":
      return "plate_taken";
    case "23514":
      return "invalid";
    case "PGRST116":
      return "not_found";
    default:
      return "generic";
  }
}

export type BusFormErrorKey = BusFormError | BusSaveErrorKey;

const FORM_ERRORS: readonly string[] = ["plate", "capacity", "plate_taken", "invalid", "not_found", "generic"];

export function isBusFormErrorKey(value: string | undefined): value is BusFormErrorKey {
  return value !== undefined && FORM_ERRORS.includes(value);
}

export type BusDone = "created" | "saved";

export function isBusDone(value: string | undefined): value is BusDone {
  return value === "created" || value === "saved";
}
