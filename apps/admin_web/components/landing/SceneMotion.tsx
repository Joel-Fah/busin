"use client";

import { useRef, type ReactNode } from "react";

import { useScrollScene } from "./motion/useScrollScene";

/**
 * Lets a scene arrive gently, once: the far buildings settle in, the bus glides to its stop, the small message follows.
 * Slow, no looping, and nothing moves for a visitor who asked for less motion.
 */
export function SceneMotion({ children, className }: { children: ReactNode; className?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  useScrollScene(ref, ({ gsap, reduced, root }) => {
    if (reduced) return;
    const q = gsap.utils.selector(root);
    const tl = gsap.timeline({ defaults: { ease: "power2.out" }, scrollTrigger: { trigger: root, start: "top 85%", once: true } });
    tl.from(q("[data-scene-far]"), { opacity: 0, y: 14, duration: 1.8, stagger: 0.25 })
      .from(q("[data-scene-still]"), { opacity: 0, y: 12, duration: 1.4, stagger: 0.2 }, "-=1.4")
      .from(q("[data-scene-bus]"), { xPercent: 22, opacity: 0, duration: 2.6, ease: "power3.out" }, "-=0.8")
      .from(q("[data-scene-chip]"), { opacity: 0, y: 8, duration: 1.2 }, "-=0.6");
  });
  return (
    <div ref={ref} className={className}>
      {children}
    </div>
  );
}
