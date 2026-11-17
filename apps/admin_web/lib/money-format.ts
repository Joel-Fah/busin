import { formatAmount } from "@/lib/billing";

/** From this size an amount is written short on the dashboards: 120K XAF, 1.2M XAF (the exact one on hover). */
export const COMPACT_FROM = 100_000;

/**
 * An amount written short, as the reader's language does it ("120K XAF", "1.2M XAF"; "120 k XAF", "1,2 M XAF"), or null
 * when it is small enough to read whole. One decimal at most, so 1,250,000 is 1.3M: the exact amount is always on hover.
 */
export function compactAmount(amount: number, locale: string, currency = "XAF"): string | null {
  if (!Number.isFinite(amount) || Math.abs(amount) < COMPACT_FROM) return null;
  return `${new Intl.NumberFormat(locale, { notation: "compact", maximumFractionDigits: 1 }).format(amount)} ${currency}`;
}

/** What a dashboard shows for an amount: the short form when it is long, with the exact one to show on hover. */
export function shownAmount(amount: number, locale: string, currency = "XAF"): { text: string; full: string; short: boolean } {
  const full = formatAmount(amount, locale, currency);
  const compact = compactAmount(amount, locale, currency);
  return compact ? { text: compact, full, short: true } : { text: full, full, short: false };
}
