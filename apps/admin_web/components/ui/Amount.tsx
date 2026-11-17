import { shownAmount } from "@/lib/money-format";

/**
 * An amount on a dashboard: written short when it is long (120K XAF, 1.2M XAF), the exact amount in the tooltip on
 * hover and on keyboard focus, and read whole by screen readers (its hidden text kept inside it, so it never widens a
 * scrolling table). Small amounts are written whole and need nothing more.
 */
export function Amount({ value, locale, currency = "XAF", className = "" }: { value: number; locale: string; currency?: string; className?: string }) {
  const shown = shownAmount(value, locale, currency);
  if (!shown.short) return <span className={className}>{shown.text}</span>;
  return (
    <span className={`relative cursor-help ${className}`} data-tip={shown.full} tabIndex={0}>
      <span aria-hidden>{shown.text}</span>
      <span className="sr-only">{shown.full}</span>
    </span>
  );
}
