import Link from "next/link";

import { shares } from "@/lib/overview";

export type MixPart = { key: string; label: string; count: number; href: string; color: string };

/**
 * One bar split by share, with a legend that repeats every figure as text. Each legend row links to the
 * subscriptions of that status. Parts with nothing in them keep their legend row but take no width.
 */
export function StatusMix({ parts }: { parts: readonly MixPart[] }) {
  const percents = shares(parts.map((p) => p.count));
  return (
    <div className="flex flex-col gap-5">
      <div aria-hidden className="flex h-4 w-full gap-1 rounded-xs">
        {parts.map((part, index) =>
          part.count > 0 ? (
            <span key={part.key} data-tip={`${part.label}: ${part.count}`} className="block h-full min-w-1 rounded-[3px]" style={{ width: `${percents[index]}%`, background: part.color }} />
          ) : null,
        )}
      </div>
      <ul className="m-0 grid list-none gap-1 p-0">
        {parts.map((part, index) => (
          <li key={part.key}>
            <Link
              href={part.href}
              className="flex items-center gap-3 rounded-xs px-2 py-1.5 text-sm text-fg no-underline hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus"
            >
              <span aria-hidden className="size-3 shrink-0 rounded-[4px]" style={{ background: part.color }} />
              <span className="flex-1 font-medium">{part.label}</span>
              <span className="font-bold tabular-nums">{part.count}</span>
              <span className="w-10 text-right text-xs tabular-nums text-muted">{percents[index]}%</span>
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
