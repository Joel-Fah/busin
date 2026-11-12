"use client";

import Link from "next/link";

import { Chip, type ChipTone } from "./Chip";
import { useSlidingIndicator } from "./useSlidingIndicator";

export type TabItem = {
  id: string;
  label: string;
  href: string;
  /** How many things are behind the tab. Shown as a counter, in the tab's own tone. */
  count?: number;
  tone?: ChipTone;
};

type Props = {
  /** Accessible name of the group, for example "Filter by status". */
  label: string;
  items: TabItem[];
  /** The id of the current tab. */
  active: string;
  /** When given, a click is handled here instead of following the link. For in-page tabs. */
  onSelect?: (id: string) => void;
};

/**
 * Tabs that are links, so each one is a real page address (a filter in the URL) and works without
 * scripts. The current tab sits on a raised highlight that slides to the next with an elastic stretch.
 * Unselected tabs have no background of their own. Counters take a tone: warn for work waiting,
 * ok for done, neutral otherwise.
 */
export function Tabs({ label, items, active, onSelect }: Props) {
  const { rowRef, indicatorRef } = useSlidingIndicator<HTMLElement>('[data-tab][aria-current="page"]', active);

  return (
    <nav ref={rowRef} aria-label={label} className="relative inline-flex max-w-full flex-wrap gap-1 self-start rounded-md bg-surface-2 p-1">
      <span
        ref={indicatorRef}
        aria-hidden
        className="pointer-events-none absolute top-0 left-0 rounded-sm bg-surface opacity-0 shadow-soft"
      />
      {items.map((item) => {
        const current = item.id === active;
        return (
          <Link
            key={item.id}
            href={item.href}
            data-tab=""
            aria-current={current ? "page" : undefined}
            onClick={
              onSelect
                ? (event) => {
                    event.preventDefault();
                    onSelect(item.id);
                  }
                : undefined
            }
            className={
              "relative inline-flex h-10 items-center gap-2 rounded-sm px-4 text-sm font-semibold no-underline " +
              "transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus " +
              (current ? "text-fg" : "text-muted hover:text-fg")
            }
          >
            {item.label}
            {item.count !== undefined ? <Chip tone={item.tone ?? "neutral"}>{item.count}</Chip> : null}
          </Link>
        );
      })}
    </nav>
  );
}
