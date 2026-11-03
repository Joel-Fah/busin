"use client";

import { useSyncExternalStore, type ReactNode } from "react";
import { createPortal } from "react-dom";

export const NAV_DOCK_ID = "nav-dock";

const subscribe = () => () => {};
const getDock = () => document.getElementById(NAV_DOCK_ID);

/**
 * Puts content in the space above the tabs of the floating navigation bar. The bar grows upward to
 * hold it while the tabs stay where they are, so a page can show a list or controls right at the
 * thumb. The content is removed with the page that rendered it.
 */
export function NavDock({ children }: { children: ReactNode }) {
  const dock = useSyncExternalStore(subscribe, getDock, () => null);
  return dock ? createPortal(children, dock) : null;
}
