/** Pure helpers for the buses pages. Kept separate so they are unit tested. */

export const MAX_PLATE_LENGTH = 20;
export const MAX_NAME_LENGTH = 40;
export const MAX_CAPACITY = 200;

export type BusInput = { plate: string; name: string | null; capacity: number; inService: boolean };

export type BusFormError = "plate" | "name" | "capacity";

/** Plates are stored in capitals with single spaces, so "lt 123  ab" and "LT 123 AB" are the same bus. */
export function normalizePlate(raw: unknown): string {
  return typeof raw === "string" ? raw.trim().replace(/\s+/g, " ").toUpperCase() : "";
}

/** A name is trimmed with single spaces; an empty one means the bus has no name. */
export function normalizeName(raw: unknown): string | null {
  const name = typeof raw === "string" ? raw.trim().replace(/\s+/g, " ") : "";
  return name === "" ? null : name;
}

/** What a bus is called wherever it is shown: its name when it has one, otherwise its plate. */
export function busLabel(bus: { name?: string | null; plate: string }): string {
  return bus.name?.trim() ? bus.name.trim() : bus.plate;
}

/** Validates the bus form fields. The database repeats these rules; this gives clear messages. */
export function parseBusForm(form: {
  get(name: string): unknown;
}): { ok: true; value: BusInput } | { ok: false; error: BusFormError } {
  const plate = normalizePlate(form.get("plate"));
  if (plate.length < 1 || plate.length > MAX_PLATE_LENGTH) return { ok: false, error: "plate" };

  const name = normalizeName(form.get("name"));
  if (name !== null && name.length > MAX_NAME_LENGTH) return { ok: false, error: "name" };

  const rawCapacity = form.get("capacity");
  const text = typeof rawCapacity === "string" ? rawCapacity.trim() : "";
  const capacity = /^\d{1,3}$/.test(text) ? Number(text) : NaN;
  if (!Number.isInteger(capacity) || capacity < 1 || capacity > MAX_CAPACITY) return { ok: false, error: "capacity" };

  // An unchecked box is simply absent from the form.
  return { ok: true, value: { plate, name, capacity, inService: form.get("in_service") === "on" } };
}

export type BusSaveErrorKey = "plate_taken" | "name_taken" | "invalid" | "not_found" | "generic";

/** Maps a database error from saving a bus. 23505 is a unique rule: the name (its index is named) or the plate. */
export function busSaveErrorKey(code: string | undefined, message?: string): BusSaveErrorKey {
  switch (code) {
    case "23505":
      return message?.includes("buses_school_name_key") ? "name_taken" : "plate_taken";
    case "23514":
      return "invalid";
    case "PGRST116":
      return "not_found";
    default:
      return "generic";
  }
}

export type BusFormErrorKey = BusFormError | BusSaveErrorKey;

const FORM_ERRORS: readonly string[] = ["plate", "name", "capacity", "plate_taken", "name_taken", "invalid", "not_found", "generic"];

export function isBusFormErrorKey(value: string | undefined): value is BusFormErrorKey {
  return value !== undefined && FORM_ERRORS.includes(value);
}

export type BusDone = "created" | "saved";

export function isBusDone(value: string | undefined): value is BusDone {
  return value === "created" || value === "saved";
}
