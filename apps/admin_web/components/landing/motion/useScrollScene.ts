"use client";

import { useEffect, type RefObject } from "react";

import { registerGsap } from "./gsap";

export type SceneContext = {
  gsap: ReturnType<typeof registerGsap>["gsap"];
  ScrollTrigger: ReturnType<typeof registerGsap>["ScrollTrigger"];
  /** The visitor asked for less motion: set the finished state and animate nothing. */
  reduced: boolean;
  /** A screen wide enough for side-by-side and pinned scenes. */
  wide: boolean;
  /** The element the scene belongs to. */
  root: HTMLElement;
};

/**
 * Runs a GSAP scene inside [scope]: created when the page is ready, undone completely when it leaves or the screen
 * changes (matchMedia reverts every tween and ScrollTrigger the setup made). The setup may return a cleanup function.
 */
export function useScrollScene(scope: RefObject<HTMLElement | null>, setup: (scene: SceneContext) => void | (() => void)) {
  useEffect(() => {
    const root = scope.current;
    if (!root) return;
    const { gsap, ScrollTrigger } = registerGsap();
    const mm = gsap.matchMedia(root);
    // GSAP runs the setup only while one of these matches, so `any` (always true) makes it run on every screen; each scene
    // then decides from `reduced` and `wide` what to do there.
    mm.add({ any: "all", reduced: "(prefers-reduced-motion: reduce)", wide: "(min-width: 900px)" }, (context) => {
      const { reduced, wide } = context.conditions as { reduced: boolean; wide: boolean };
      return setup({ gsap, ScrollTrigger, reduced, wide, root });
    });
    return () => mm.revert();
    // The setup closes over refs and constants only; it runs once per mount.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
}
