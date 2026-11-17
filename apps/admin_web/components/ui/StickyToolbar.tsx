"use client";

import type { ReactNode } from "react";

import { useStickyMorph } from "./useStickyMorph";

type Props = {
  /** The controls of a list: for example a search form and the tabs. Each direct child is animated on its own. */
  children: ReactNode;
};

/**
 * The search and filters of a list page. They stay in view while the list scrolls behind them, and when
 * they stick they realign into one compact row; at the top of the page they go back to their roomy layout.
 * The change animates in both directions (each control glides from where it was to where it goes), and is
 * instant when the device asks for reduced motion. The height the roomy layout needs is held as a margin, so
 * the list below never jumps when the toolbar shrinks. It must sit directly in the page column, because a
 * sticky element only sticks inside its parent.
 *
 * The compact layout is plain CSS on [data-stuck="true"] (see .sticky-toolbar in app/theme.css).
 */
export function StickyToolbar({ children }: Props) {
  const { ref: bar, stuck } = useStickyMorph<HTMLDivElement>();

  return (
    <div ref={bar} data-stuck={stuck} className="sticky-toolbar sticky top-4 z-20 flex flex-wrap items-end gap-x-3 gap-y-4">
      {children}
    </div>
  );
}
