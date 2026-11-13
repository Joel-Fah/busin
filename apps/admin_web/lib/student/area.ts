/** Rounded to 0.01 degree (about 1 km) in the browser, before anything is sent (ADR 0013); the server snaps it further. */
export function roundCoordinate(value: number): number {
  return Math.round(value * 100) / 100;
}
