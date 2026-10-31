/** Pure helpers for the stops pages. Kept separate so they are unit tested. */

import { isValidLatLng, type LatLng } from "@/lib/geo";

export const MAX_STOP_NAME_LENGTH = 120;

export type StopInput = { name: string; position: LatLng; active: boolean };

export type StopFormError = "name" | "location";

/** Reads a decimal number typed in a form. Accepts a comma as the decimal mark. */
export function parseCoordinate(raw: unknown): number | null {
  if (typeof raw !== "string") return null;
  const text = raw.trim().replace(",", ".");
  if (text === "" || !/^-?\d+(\.\d+)?$/.test(text)) return null;
  const value = Number(text);
  return Number.isFinite(value) ? value : null;
}

/** Validates the stop form fields. The database repeats these rules; this gives clear messages. */
export function parseStopForm(form: {
  get(name: string): unknown;
}): { ok: true; value: StopInput } | { ok: false; error: StopFormError } {
  const rawName = form.get("name");
  const name = typeof rawName === "string" ? rawName.trim().replace(/\s+/g, " ") : "";
  if (name.length < 1 || name.length > MAX_STOP_NAME_LENGTH) return { ok: false, error: "name" };

  const lat = parseCoordinate(form.get("lat"));
  const lng = parseCoordinate(form.get("lng"));
  if (lat === null || lng === null || !isValidLatLng(lat, lng)) return { ok: false, error: "location" };

  // An unchecked box is simply absent from the form.
  const active = form.get("active") === "on";
  return { ok: true, value: { name, position: { lat, lng }, active } };
}

export type StopSaveErrorKey = "name_taken" | "invalid" | "not_found" | "generic";

/** Maps a database error code from saving a stop. 23505 is the unique name per school. */
export function stopSaveErrorKey(code: string | undefined): StopSaveErrorKey {
  switch (code) {
    case "23505":
      return "name_taken";
    case "23514":
    case "22023":
    case "XX000":
      return "invalid";
    case "PGRST116":
      return "not_found";
    default:
      return "generic";
  }
}

export type StopFormErrorKey = StopFormError | StopSaveErrorKey;

export function isStopFormErrorKey(value: string | undefined): value is StopFormErrorKey {
  return (
    value === "name" ||
    value === "location" ||
    value === "name_taken" ||
    value === "invalid" ||
    value === "not_found" ||
    value === "generic"
  );
}

export type StopDone = "created" | "saved";

export function isStopDone(value: string | undefined): value is StopDone {
  return value === "created" || value === "saved";
}
