"use client";

import { useEffect, useRef } from "react";
import { gsap } from "gsap";

/**
 * A highlight that sits behind the active item of a row and slides to the next one when it changes.
 * The edge facing the new item leads and overshoots a little; the other edge starts a beat later and
 * follows, so the highlight stretches across the gap and settles on the item's width, like elastic.
 *
 * Attach `rowRef` to the row that holds the items and `indicatorRef` to the highlight element, which
 * must be absolutely positioned inside it. `activeSelector` finds the active item inside the row, and
 * `key` changes whenever the active item does. First placement, resizes and reduced motion are
 * instant. A new slide starts from wherever the highlight is drawn, so it never snaps mid-slide.
 */
export function useSlidingIndicator<Row extends HTMLElement = HTMLDivElement>(activeSelector: string, key: unknown) {
  const rowRef = useRef<Row>(null);
  const indicatorRef = useRef<HTMLSpanElement>(null);
  // Where the highlight is drawn right now (it may be mid-slide), and the slide in progress.
  const shown = useRef<{ left: number; right: number } | null>(null);
  const slide = useRef<gsap.core.Timeline | null>(null);

  useEffect(() => {
    const rowEl = rowRef.current;
    const bar = indicatorRef.current;
    if (!rowEl || !bar) return;

    const measure = () => {
      const item = Array.from(rowEl.querySelectorAll<HTMLElement>(activeSelector)).find((el) => el.offsetWidth > 0);
      if (!item) return null;
      const rowBox = rowEl.getBoundingClientRect();
      const box = item.getBoundingClientRect();
      return { left: box.left - rowBox.left, right: box.right - rowBox.left, top: box.top - rowBox.top, height: box.height };
    };

    const draw = (left: number, right: number) => {
      bar.style.transform = `translateX(${left}px)`;
      bar.style.width = `${Math.max(right - left, 0)}px`;
      shown.current = { left, right };
    };

    const place = (animate: boolean) => {
      const target = measure();
      slide.current?.kill();
      if (!target) {
        gsap.set(bar, { opacity: 0 });
        shown.current = null;
        return;
      }
      bar.style.top = `${target.top}px`;
      bar.style.height = `${target.height}px`;
      const from = shown.current;
      const calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

      if (!animate || !from || calm) {
        draw(target.left, target.right);
        gsap.set(bar, { opacity: 1 });
        return;
      }

      const state = { left: from.left, right: from.right };
      const forward = target.left >= from.left;
      const lead = forward ? "right" : "left";
      const trail = forward ? "left" : "right";
      slide.current = gsap
        .timeline({ onUpdate: () => draw(state.left, state.right) })
        .to(state, { [lead]: target[lead], duration: 0.5, ease: "back.out(1.8)" }, 0)
        .to(state, { [trail]: target[trail], duration: 0.45, ease: "power3.out" }, 0.09);
    };

    place(shown.current !== null);

    // An observer reports once as soon as it starts, which must not cut a slide short. Only real size changes count.
    let width = rowEl.offsetWidth;
    const observer = new ResizeObserver(() => {
      if (rowEl.offsetWidth === width) return;
      width = rowEl.offsetWidth;
      place(false);
    });
    observer.observe(rowEl);
    return () => {
      observer.disconnect();
      slide.current?.kill();
    };
  }, [activeSelector, key]);

  return { rowRef, indicatorRef };
}
