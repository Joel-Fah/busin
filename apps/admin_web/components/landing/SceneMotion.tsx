"use client";

import { useRef, type ReactNode } from "react";

import { useScrollScene } from "./motion/useScrollScene";

/**
 * Lets a scene arrive gently, once: the layers settle in from far to near, then the small messages appear one after another.
 * Slow, no looping, and nothing moves for a visitor who asked for less motion.
 */
export function SceneMotion({ children, className }: { children: ReactNode; className?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  useScrollScene(ref, ({ gsap, reduced, root }) => {
    if (reduced) return;
    const q = gsap.utils.selector(root);
    const tl = gsap.timeline({ defaults: { ease: "power2.out" }, scrollTrigger: { trigger: root, start: "top 85%", once: true } });
    tl.from(q("[data-scene-layer]"), { opacity: 0, y: 14, duration: 1.8, stagger: 0.28 })
      .from(q("[data-scene-chip]"), { opacity: 0, y: 8, duration: 1.3, stagger: 0.6 }, "-=0.6");
  });
  return (
    <div ref={ref} className={className}>
      {children}
    </div>
  );
}
