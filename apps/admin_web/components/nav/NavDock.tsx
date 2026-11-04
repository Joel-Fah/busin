"use client";

import { useEffect, useState, useSyncExternalStore, type ReactNode } from "react";
import { createPortal } from "react-dom";

export const NAV_DOCK_ID = "nav-dock";

const subscribe = () => () => {};
const getDock = () => document.getElementById(NAV_DOCK_ID);

// Wait this long before opening, so the page has finished arriving and the bar then opens calmly.
const DELAY_MS = 350;
// On the first load the bar is still sliding in (and the logo may be playing), so wait for that too.
const FIRST_LOAD_DELAY_MS = 1300;

/**
 * Puts content in the space above the tabs of the floating navigation bar. The bar grows upward to
 * hold it while the tabs stay where they are, so a page can show a list or controls right at the
 * thumb. The dock opens gently: a short pause after the page arrives, then a slow, soft growth. With
 * reduced motion it appears at once. The content is removed with the page that rendered it.
 */
export function NavDock({ children }: { children: ReactNode }) {
  const dock = useSyncExternalStore(subscribe, getDock, () => null);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const arriving = document.documentElement.dataset.reveal !== undefined;
    const timer = window.setTimeout(() => setOpen(true), calm ? 0 : arriving ? FIRST_LOAD_DELAY_MS : DELAY_MS);
    return () => window.clearTimeout(timer);
  }, []);

  if (!dock) return null;
  return createPortal(
    <div
      className={
        "grid transition-[grid-template-rows,opacity] duration-[750ms] ease-soft motion-reduce:transition-none " +
        (open ? "grid-rows-[1fr] opacity-100" : "grid-rows-[0fr] opacity-0")
      }
    >
      <div className="min-w-0 overflow-hidden">
        <div className="min-w-0 px-4 pt-4">{children}</div>
      </div>
    </div>,
    dock,
  );
}
