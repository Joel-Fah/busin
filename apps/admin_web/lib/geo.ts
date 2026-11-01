/** Map positions. Pure helpers, unit tested. Coordinates are WGS 84 (SRID 4326). */

export type LatLng = { lat: number; lng: number };

export function isValidLatLng(lat: number, lng: number): boolean {
  return Number.isFinite(lat) && Number.isFinite(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

/**
 * Reads a position as the API returns it. PostgREST sends a geography column as hex-encoded
 * binary (EWKB); WKT text and GeoJSON are accepted too. Returns null when it cannot be read.
 */
export function parsePoint(raw: unknown): LatLng | null {
  if (typeof raw === "string") {
    const text = raw.trim();
    return parseEwkbHex(text) ?? parseWkt(text);
  }
  if (raw && typeof raw === "object") {
    const { type, coordinates } = raw as { type?: unknown; coordinates?: unknown };
    if (type === "Point" && Array.isArray(coordinates) && coordinates.length >= 2) {
      const [lng, lat] = coordinates as unknown[];
      if (typeof lng === "number" && typeof lat === "number" && isValidLatLng(lat, lng)) return { lat, lng };
    }
  }
  return null;
}

function parseWkt(text: string): LatLng | null {
  const match = /^(?:SRID=\d+;)?POINT\s*\(\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\)$/i.exec(text);
  if (!match) return null;
  const lng = Number(match[1]);
  const lat = Number(match[2]);
  return isValidLatLng(lat, lng) ? { lat, lng } : null;
}

const SRID_FLAG = 0x20000000;
const Z_FLAG = 0x80000000;
const M_FLAG = 0x40000000;

function parseEwkbHex(text: string): LatLng | null {
  if (text.length < 42 || text.length % 2 !== 0 || !/^[0-9a-fA-F]+$/.test(text)) return null;

  const bytes = new Uint8Array(text.length / 2);
  for (let i = 0; i < bytes.length; i++) bytes[i] = Number.parseInt(text.slice(i * 2, i * 2 + 2), 16);
  const view = new DataView(bytes.buffer);

  const byteOrder = view.getUint8(0);
  if (byteOrder > 1) return null;
  const little = byteOrder === 1;

  const type = view.getUint32(1, little);
  if ((type & 0xff) !== 1) return null; // not a point

  let offset = 5;
  if ((type & SRID_FLAG) !== 0) {
    if (bytes.length < offset + 4) return null;
    if (view.getUint32(offset, little) !== 4326) return null; // only WGS 84
    offset += 4;
  }

  const ordinates = 2 + ((type & Z_FLAG) !== 0 ? 1 : 0) + ((type & M_FLAG) !== 0 ? 1 : 0);
  if (bytes.length < offset + ordinates * 8) return null;

  const lng = view.getFloat64(offset, little);
  const lat = view.getFloat64(offset + 8, little);
  return isValidLatLng(lat, lng) ? { lat, lng } : null;
}

/**
 * The text PostGIS accepts when writing a geography point. Longitude comes first.
 * The API rejects GeoJSON objects for this column but accepts this form.
 */
export function toEwkt({ lat, lng }: LatLng): string {
  return `SRID=4326;POINT(${lng.toFixed(7)} ${lat.toFixed(7)})`;
}

/** Average position, or null for an empty list. Fine for stops within one city. */
export function centroid(points: readonly LatLng[]): LatLng | null {
  if (points.length === 0) return null;
  const sum = points.reduce((acc, p) => ({ lat: acc.lat + p.lat, lng: acc.lng + p.lng }), { lat: 0, lng: 0 });
  return { lat: sum.lat / points.length, lng: sum.lng / points.length };
}

/** A short label such as `3.84800, 11.50210`. */
export function formatLatLng({ lat, lng }: LatLng): string {
  return `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
}
