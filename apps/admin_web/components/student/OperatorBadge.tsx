import type { Provider } from "@/lib/student/mobile-money";

/*
  The operators' own colours, the same in light and dark like any logo: MTN yellow and Orange orange, each with black
  text (contrast above 7:1). A text badge stands in for now; the owner supplies the official marks later, and this is the
  one place to swap them in.
*/
const LOOK: Record<Provider, { short: string; className: string }> = {
  MTN_MOMO_CMR: { short: "MTN", className: "bg-[#FFCC00] text-black" },
  ORANGE_CMR: { short: "Orange", className: "bg-[#FF7900] text-black" },
};

/** The operator's mark, then its name. The name is always written out, so the colour is never the only sign. */
export function OperatorBadge({ provider, name, compact = false }: { provider: Provider; name: string; compact?: boolean }) {
  const look = LOOK[provider];
  return (
    <span className="inline-flex min-w-0 items-center gap-2" data-testid="operator-badge" data-provider={provider}>
      <span aria-hidden className={`inline-flex h-6 shrink-0 items-center rounded-xs px-2 text-xs font-extrabold tracking-tight ${look.className}`}>
        {look.short}
      </span>
      {compact ? <span className="sr-only">{name}</span> : <span className="truncate text-sm font-semibold">{name}</span>}
    </span>
  );
}
