"use client";

import { useRef, type ReactNode } from "react";

import { useScrollScene } from "../motion/useScrollScene";

/**
 * A row of cards. On a wide screen with motion allowed, the section holds still while the row slides across as you
 * scroll; otherwise (phones, reduced motion, no scripts) the cards simply sit in a grid.
 */
export function PeopleTrack({ children }: { children: ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);

  useScrollScene(ref, ({ gsap, wide, reduced, root }) => {
    if (!wide || reduced) return;
    const track = root.querySelector<HTMLElement>("[data-people-track]");
    if (!track) return;
    root.classList.add("is-pinned");
    const distance = () => Math.max(0, track.scrollWidth - root.clientWidth);
    gsap.to(track, {
      x: () => -distance(),
      ease: "none",
      scrollTrigger: { trigger: root, start: "center center", end: () => `+=${distance()}`, pin: true, scrub: 0.8, invalidateOnRefresh: true },
    });
    gsap.from(track.children, { y: 40, opacity: 0, stagger: 0.12, duration: 0.9, ease: "power3.out", scrollTrigger: { trigger: root, start: "top 80%", once: true } });
    return () => root.classList.remove("is-pinned");
  });

  return (
    <div ref={ref} className="people-track mt-14 lg:mt-16">
      <div data-people-track className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
        {children}
      </div>
    </div>
  );
}
