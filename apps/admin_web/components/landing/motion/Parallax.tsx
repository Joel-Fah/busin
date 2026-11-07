"use client";

import { useRef, type ReactNode } from "react";

import { useScrollScene } from "./useScrollScene";

type Props = {
  children: ReactNode;
  /** Pixels it drifts over the time its section crosses the screen. Negative drifts up. */
  shift?: number;
  className?: string;
};

/** A decorative layer that drifts a little against the scroll. Still under reduced motion. */
export function Parallax({ children, shift = -60, className }: Props) {
  const ref = useRef<HTMLDivElement>(null);
  useScrollScene(ref, ({ gsap, reduced, root }) => {
    if (reduced) return;
    gsap.to(root, { y: shift, ease: "none", scrollTrigger: { trigger: root, start: "top bottom", end: "bottom top", scrub: 0.6 } });
  });
  return (
    <div ref={ref} className={className}>
      {children}
    </div>
  );
}
