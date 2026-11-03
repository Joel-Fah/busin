"use client";

import { useEffect } from "react";

// Sheets and modals can be open together, so the lock is released only when the last one closes.
let locks = 0;

/**
 * Stops the page behind from scrolling while `active` is true (an open sheet or modal). The width of the
 * scrollbar that disappears is added back as padding, so the page does not jump sideways when it locks.
 */
export function useScrollLock(active: boolean) {
  useEffect(() => {
    if (!active) return;
    const root = document.documentElement;
    if (locks === 0) root.style.setProperty("--lock-pad", `${window.innerWidth - root.clientWidth}px`);
    locks += 1;
    root.classList.add("scroll-locked");
    return () => {
      locks -= 1;
      if (locks === 0) {
        root.classList.remove("scroll-locked");
        root.style.removeProperty("--lock-pad");
      }
    };
  }, [active]);
}
