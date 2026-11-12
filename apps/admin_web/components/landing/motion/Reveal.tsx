"use client";

import { useRef, type ElementType, type ReactNode } from "react";

import { useScrollScene } from "./useScrollScene";

type Props = {
  children: ReactNode;
  /** How far it rises from, in pixels. */
  rise?: number;
  /** Seconds to wait once it enters, for staggering neighbours by hand. */
  delay?: number;
  as?: ElementType;
  className?: string;
};

/**
 * Fades and lifts its content in once, as it enters the screen. Without scripts, or with reduced motion, the content is
 * simply there: the hidden starting state is set by the script, never by the stylesheet.
 */
export function Reveal({ children, rise = 28, delay = 0, as: Tag = "div", className }: Props) {
  const ref = useRef<HTMLElement>(null);
  useScrollScene(ref, ({ gsap, reduced, root }) => {
    if (reduced) return;
    gsap.from(root, {
      y: rise,
      opacity: 0,
      duration: 0.9,
      delay,
      ease: "power3.out",
      clearProps: "transform,opacity",
      scrollTrigger: { trigger: root, start: "top 88%", once: true },
    });
  });
  return (
    <Tag ref={ref} className={className}>
      {children}
    </Tag>
  );
}
