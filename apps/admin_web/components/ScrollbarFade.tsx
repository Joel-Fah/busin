"use client";

import { useEffect } from "react";

const QUIET_MS = 900;

/**
 * Marks a scrolling container as in use while it scrolls, so its thin scrollbar can show and then fade
 * away (see the scrollbar rules in app/theme.css). One listener for the whole page; nothing renders.
 */
export function ScrollbarFade() {
  useEffect(() => {
    const timers = new WeakMap<Element, number>();
    const onScroll = (event: Event) => {
      const el = event.target;
      if (!(el instanceof HTMLElement)) return; // the page itself scrolls on the document
      el.classList.add("is-scrolling");
      window.clearTimeout(timers.get(el));
      timers.set(
        el,
        window.setTimeout(() => el.classList.remove("is-scrolling"), QUIET_MS),
      );
    };
    // Scroll does not bubble, so listen while it is captured on the way down.
    document.addEventListener("scroll", onScroll, true);
    return () => document.removeEventListener("scroll", onScroll, true);
  }, []);

  return null;
}
