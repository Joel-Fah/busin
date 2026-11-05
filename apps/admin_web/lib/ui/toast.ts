/** What a toast is telling. Each state has its own colour and icon and its own time on screen. */
export type ToastTone = "ok" | "info" | "warn" | "bad";

/** How long a toast stays: good news leaves quickly, a problem stays long enough to be read (milliseconds). */
export const TOAST_DURATION: Record<ToastTone, number> = { ok: 2800, info: 4000, warn: 5500, bad: 7000 };

export function toastDuration(tone: ToastTone, override?: number): number {
  return override ?? TOAST_DURATION[tone];
}

export type ToastItem = { id: number; tone: ToastTone; message: string; title?: string; duration: number };

/** One toast at a time: a new one replaces the one showing. */
export function nextToast(_current: ToastItem | null, next: ToastItem): ToastItem {
  return next;
}
