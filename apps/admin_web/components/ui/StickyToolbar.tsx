"use client";

import { useEffect, useLayoutEffect, useRef, useState, type ReactNode } from "react";
import { gsap } from "gsap";
import { Flip } from "gsap/Flip";

gsap.registerPlugin(Flip);

/** How far from the top of the screen the toolbar rests when it sticks (1rem). */
const TOP_OFFSET_PX = 16;

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
  const bar = useRef<HTMLDivElement>(null);
  const [stuck, setStuck] = useState(false);
  // How tall the roomy layout is, so the list below can be kept exactly where it is when the toolbar shrinks.
  const roomyHeight = useRef(0);
  // Where the controls were just before the layout changed, so they can be animated from there.
  const before = useRef<ReturnType<typeof Flip.getState> | null>(null);
  const seen = useRef(false);

  // Keep the page still: the roomy toolbar's height is held as a margin while the compact one is showing.
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

  // Stuck once the bar rests against the top: the observer's top edge is one pixel below the resting
  // offset, so a bar that is stuck is always a little clipped by it, and a bar that is not never is.
  useEffect(() => {
    const el = bar.current;
    if (!el) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        const next = entry.intersectionRatio < 1 && entry.boundingClientRect.top < TOP_OFFSET_PX + 1;
        setStuck((current) => {
          if (current === next) return current;
          // Remember where everything is now; the layout effect below animates from there. The first report,
          // when the page loads already scrolled, just sets the state without an animation.
          if (seen.current) before.current = Flip.getState(Array.from(el.children));
          return next;
        });
        seen.current = true;
      },
      { rootMargin: `-${TOP_OFFSET_PX + 1}px 0px 0px 0px`, threshold: [0, 1] },
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  useLayoutEffect(() => {
    const state = before.current;
    if (!state) return;
    before.current = null;
    const calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    Flip.from(state, { duration: calm ? 0 : 0.55, ease: "power3.out", scale: false, simple: true });
  }, [stuck]);

  return (
    <div ref={bar} data-stuck={stuck} className="sticky-toolbar sticky top-4 z-20 flex flex-wrap items-end gap-x-3 gap-y-4">
      {children}
    </div>
  );
}
