/**
 * Where to go back to after a quick detour (adding a bus from the trip form, for example). Only pages of the portal named
 * here are accepted, so a link can never send an administrator somewhere else after a save.
 */
const RETURNS = ["/trips/new", "/"] as const;
export type ReturnPath = (typeof RETURNS)[number];

export function safeNext(value: unknown): ReturnPath | null {
  return typeof value === "string" && (RETURNS as readonly string[]).includes(value) ? (value as ReturnPath) : null;
}
