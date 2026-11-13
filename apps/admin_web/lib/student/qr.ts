import { todayInZone } from "@/lib/zoned";

/**
 * The rotating boarding code (ADR 0014), as `qr_code.dart`, with the browser's Web Crypto:
 * `busin2.<student uuid>.<window>.<mac>`, where window = floor(unix seconds / 30), the day key is
 * HMAC-SHA256(secret, "busin-day:YYYY-MM-DD") for the school-local date when the window starts, and mac is the first 20
 * hex characters of HMAC-SHA256(day key, "<uuid>:<window>"). The secret stays a non-extractable key (ADR 0021): it can
 * sign but its bytes cannot be read back.
 */
export const VERSION = "busin2";
export const WINDOW_SECONDS = 30;

const encoder = new TextEncoder();

function hex(buffer: ArrayBuffer): string {
  return Array.from(new Uint8Array(buffer), (b) => b.toString(16).padStart(2, "0")).join("");
}

export function windowFor(atMs: number): number {
  return Math.floor(atMs / 1000 / WINDOW_SECONDS);
}

export function secondsRemaining(atMs: number): number {
  return WINDOW_SECONDS - (Math.floor(atMs / 1000) % WINDOW_SECONDS);
}

/** The 32-byte secret from `get_my_qr_secret` (base64), as a key that can only sign. */
export async function importSecret(base64: string, subtle: SubtleCrypto = crypto.subtle): Promise<CryptoKey> {
  const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
  if (bytes.length !== 32) throw new Error(`The key must be 32 bytes, got ${bytes.length}`);
  return subtle.importKey("raw", bytes, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
}

/** The key of one school day, derived from the student's secret. */
export async function dayKey(secret: CryptoKey, date: string, subtle: SubtleCrypto = crypto.subtle): Promise<ArrayBuffer> {
  return subtle.sign("HMAC", secret, encoder.encode(`busin-day:${date}`));
}

export async function mac(dayKeyBytes: ArrayBuffer, studentId: string, window: number, subtle: SubtleCrypto = crypto.subtle): Promise<string> {
  const key = await subtle.importKey("raw", dayKeyBytes, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  return hex(await subtle.sign("HMAC", key, encoder.encode(`${studentId}:${window}`))).slice(0, 20);
}

/** The code to show at `atMs`, with the day taken at the school (its time zone), as the staff phone and the server do. */
export async function generateCode(secret: CryptoKey, studentId: string, atMs: number, timeZone: string): Promise<string> {
  const window = windowFor(atMs);
  const date = todayInZone(timeZone, new Date(window * WINDOW_SECONDS * 1000));
  const key = await dayKey(secret, date);
  return `${VERSION}.${studentId}.${window}.${await mac(key, studentId, window)}`;
}

export { hex as toHex };
