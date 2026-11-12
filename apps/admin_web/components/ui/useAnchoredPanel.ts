"use client";

import { useLayoutEffect, useRef } from "react";

import { placePanel, type Side } from "@/lib/ui/placement";

/**
 * Puts a floating panel next to its trigger, on whichever side has room (see lib/ui/placement.ts),
 * and keeps it there while the page scrolls or resizes. The panel must carry `popover="manual"`:
 * that puts it in the browser's top layer, so it appears above sheets and modals and is never
 * clipped by a scrolling container. The side it landed on is written to `data-side`.
 *
 * Attach `anchorRef` to the trigger and `panelRef` to the panel, and render the panel only while open.
 */
export function useAnchoredPanel<A extends HTMLElement = HTMLElement, P extends HTMLElement = HTMLDivElement>(
  open: boolean,
  preferred: Side | "auto" = "auto",
  matchWidth = false,
) {
  const anchorRef = useRef<A>(null);
  const panelRef = useRef<P>(null);

  useLayoutEffect(() => {
    const anchor = anchorRef.current;
    const panel = panelRef.current;
    if (!open || !anchor || !panel) return;

    try {
      panel.showPopover();
    } catch {
      // Already shown, or the browser has no popover support; the panel is still positioned below.
    }

    const place = () => {
      const a = anchor.getBoundingClientRect();
      if (matchWidth) panel.style.minWidth = `${a.width}px`;
      const p = panel.getBoundingClientRect();
      const result = placePanel({
        anchor: a,
        panel: { width: p.width, height: p.height },
        viewport: { width: window.innerWidth, height: window.innerHeight },
        preferred,
      });
      panel.style.left = `${result.left}px`;
      panel.style.top = `${result.top}px`;
      panel.dataset.side = result.side;
    };

    place();
    window.addEventListener("resize", place);
    window.addEventListener("scroll", place, true);
    return () => {
      window.removeEventListener("resize", place);
      window.removeEventListener("scroll", place, true);
      try {
        panel.hidePopover();
      } catch {
        // The panel is already gone.
      }
    };
  }, [open, preferred, matchWidth]);

  return { anchorRef, panelRef };
}
