"use client";

import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { gsap } from "gsap";
import { Flip } from "gsap/Flip";

gsap.registerPlugin(Flip);

/** How far from the top of the screen a sticky bar rests when it sticks (1rem, the top-4 class). */
export const STICKY_TOP_OFFSET_PX = 16;

type Options = {
  /**
   * The elements that glide from their roomy place to their compact one: the bar's children by default. Pass a function
   * defined outside the component, so it stays the same between renders.
   */
  targets?: (bar: HTMLElement) => Element[];
  /** The CSS properties animated besides position, for example "width" or "width,height,fontSize". */
  props?: string;
};

/**
 * Shared by the sticky bars (StickyToolbar, StickyHeader): tells when the bar rests against the top of the screen, and
 * animates its parts from their roomy layout to the compact one and back (GSAP Flip), instantly for reduced motion.
 * While compact, the roomy height is held as a bottom margin, so the content below never jumps.
 */
export function useStickyMorph<T extends HTMLElement>({ targets, props = "width" }: Options = {}) {
  const bar = useRef<T>(null);
  const [stuck, setStuck] = useState(false);
  const roomyHeight = useRef(0);
  const before = useRef<ReturnType<typeof Flip.getState> | null>(null);
  const seen = useRef(false);

  // Keep the page still: the roomy height is held as a margin while the compact bar is showing.
  useLayoutEffect(() => {
    const el = bar.current;
    if (!el) return;
    const hold = () => {
      if (!stuck) {
        roomyHeight.current = el.offsetHeight;
        el.style.marginBottom = "";
      } else {
        el.style.marginBottom = `${Math.max(0, roomyHeight.current - el.offsetHeight)}px`;
      }
    };
    hold();
    const observer = new ResizeObserver(hold);
    observer.observe(el);
    return () => observer.disconnect();
  }, [stuck]);

  // Stuck once the bar rests against the top: the observer's top edge is one pixel below the resting offset, so a bar
  // that is stuck is always a little clipped by it, and a bar that is not never is.
  useEffect(() => {
    const el = bar.current;
    if (!el) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        const next = entry.intersectionRatio < 1 && entry.boundingClientRect.top < STICKY_TOP_OFFSET_PX + 1;
        setStuck((current) => {
          if (current === next) return current;
          // Remember where everything is now; the layout effect below animates from there. The first report, when the
          // page loads already scrolled, just sets the state without an animation.
          if (seen.current) before.current = Flip.getState(targets ? targets(el) : Array.from(el.children), { props });
          return next;
        });
        seen.current = true;
      },
      { rootMargin: `-${STICKY_TOP_OFFSET_PX + 1}px 0px 0px 0px`, threshold: [0, 1] },
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [targets, props]);

  useLayoutEffect(() => {
    const state = before.current;
    if (!state) return;
    before.current = null;
    const calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    Flip.from(state, { duration: calm ? 0 : 0.55, ease: "power3.out", scale: false, simple: true, props });
  }, [stuck, props]);

  return { ref: bar, stuck };
}
