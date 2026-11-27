/** Pure helpers for the school's campus point (ADR 0017). Kept separate so they are unit tested. */

import { isValidLatLng, type LatLng } from "@/lib/geo";
import { parseCoordinate } from "@/lib/stops";

export const MAX_CAMPUS_NAME_LENGTH = 80;

/** The database refuses points beyond these latitudes (web maps cannot show them). */
const MAX_CAMPUS_LAT = 85;

export type Campus = { name: string; position: LatLng };

export type CampusError = "invalid_point" | "invalid_name";

/** The same rules as `admin_set_campus`, checked first so the person gets a clear message. */
export function checkCampus(lat: number, lng: number, name: string): { ok: true; value: Campus } | { ok: false; error: CampusError } {
  if (typeof lat !== "number" || typeof lng !== "number" || !isValidLatLng(lat, lng) || Math.abs(lat) > MAX_CAMPUS_LAT) {
    return { ok: false, error: "invalid_point" };
  }
  const trimmed = typeof name === "string" ? name.trim().replace(/\s+/g, " ") : "";
  if (trimmed.length < 1 || trimmed.length > MAX_CAMPUS_NAME_LENGTH) return { ok: false, error: "invalid_name" };
  return { ok: true, value: { name: trimmed, position: { lat, lng } } };
}

/** Reads typed coordinates (a comma may be the decimal mark). Null unless they make a point the campus may be at. */
export function parseCampusPoint(fields: { lat: string; lng: string }): LatLng | null {
  const lat = parseCoordinate(fields.lat);
  const lng = parseCoordinate(fields.lng);
  if (lat === null || lng === null || !isValidLatLng(lat, lng) || Math.abs(lat) > MAX_CAMPUS_LAT) return null;
  return { lat, lng };
}

/** Reads the campus fields as typed. */
export function parseCampusFields(fields: { lat: string; lng: string; name: string }): ReturnType<typeof checkCampus> {
  const point = parseCampusPoint(fields);
  if (!point) return { ok: false, error: "invalid_point" };
  return checkCampus(point.lat, point.lng, fields.name);
}

/** The coordinates as the fields show them: six decimals, about 10 cm. */
export function coordinateFields(position: LatLng | null): { lat: string; lng: string } {
  return position ? { lat: position.lat.toFixed(6), lng: position.lng.toFixed(6) } : { lat: "", lng: "" };
}

