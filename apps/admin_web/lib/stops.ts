/** Pure helpers for the stops pages. Kept separate so they are unit tested. */

import { distanceMeters, isValidLatLng, type LatLng } from "@/lib/geo";

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

export type StopSaveErrorKey = "name_taken" | "too_close" | "invalid" | "not_found" | "generic";

/** Maps a database error from saving a stop. 23505 is the unique name per school; 22023 "stop_too_close" is the same place. */
export function stopSaveErrorKey(code: string | undefined, message?: string): StopSaveErrorKey {
  if (code === "22023" && message === "stop_too_close") return "too_close";
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

export type UsageLabels = { none: string; one: string; many: string; pending: string };

/** "12 students, 3 waiting" for a stop. Singular and zero have their own words. */
export function describeUsage(students: number, pending: number, labels: UsageLabels): string {
  const main = students === 0 ? labels.none : students === 1 ? labels.one : labels.many.replace("{count}", String(students));
  return pending > 0 ? `${main}, ${labels.pending.replace("{count}", String(pending))}` : main;
}

/** Closer than this to another stop is the same place: refused (the database refuses it too). */
export const SAME_PLACE_M = 25;
/** Closer than this, the administrator is asked whether they are sure. */
export const CLOSE_M = 200;

type Located = { id: string; name: string; active: boolean; position: LatLng | null };

export type NearbyStop = { stop: { id: string; name: string }; meters: number; kind: "same" | "close" };

/**
 * The closest other active stop to `position`, when it is within CLOSE_M: "same" under SAME_PLACE_M (refused), "close"
 * otherwise (ask first). `excludeId` leaves out the stop being edited. Null when nothing is near.
 */
export function nearbyStop(position: LatLng, stops: readonly Located[], excludeId?: string | null): NearbyStop | null {
  let best: { stop: Located; meters: number } | null = null;
  for (const stop of stops) {
    if (!stop.active || !stop.position || stop.id === excludeId) continue;
    const meters = distanceMeters(position, stop.position);
    if (!best || meters < best.meters) best = { stop, meters };
  }
  if (!best || best.meters >= CLOSE_M) return null;
  return { stop: { id: best.stop.id, name: best.stop.name }, meters: best.meters, kind: best.meters < SAME_PLACE_M ? "same" : "close" };
}
