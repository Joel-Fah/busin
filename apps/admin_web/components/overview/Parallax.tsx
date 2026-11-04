"use client";

import { useEffect, useRef, type ReactNode } from "react";

type Props = {
  children: ReactNode;
  className?: string;
  testId?: string;
};

/**
 * A surface that tells its children where the pointer is. It sets --px and --py on itself, each from -1 (left, top)
 * to 1 (right, bottom), and back to 0 when the pointer leaves. Layers inside move by those numbers (see Welcome). Mouse and pen only; touch and reduced motion leave it still.
 */
export function Parallax({ children, className, testId }: Props) {
  const ref = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    let frame = 0;
    const set = (x: number, y: number) => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        el.style.setProperty("--px", x.toFixed(3));
        el.style.setProperty("--py", y.toFixed(3));
      });
    };
    const onMove = (event: PointerEvent) => {
      if (event.pointerType === "touch") return;
      const box = el.getBoundingClientRect();
      const clamp = (n: number) => Math.max(-1, Math.min(1, n));
      set(clamp(((event.clientX - box.left) / box.width) * 2 - 1), clamp(((event.clientY - box.top) / box.height) * 2 - 1));
    };
    const onLeave = () => set(0, 0);

    el.addEventListener("pointermove", onMove);
    el.addEventListener("pointerleave", onLeave);
    return () => {
      cancelAnimationFrame(frame);
      el.removeEventListener("pointermove", onMove);
      el.removeEventListener("pointerleave", onLeave);
    };
  }, []);

  return (
    <section ref={ref} data-testid={testId} className={className}>
      {children}
    </section>
  );
}
