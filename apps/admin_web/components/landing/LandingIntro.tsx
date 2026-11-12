"use client";

import { useEffect, useRef } from "react";

import { BrandMark } from "@/components/brand/BrandMark";
import { INTRO_DONE_EVENT, INTRO_STORAGE_KEY } from "@/lib/intro";

import { registerGsap } from "./motion/gsap";

/**
 * The landing page's opening: the logo draws itself on a cover, fills in, then flies up and shrinks onto the logo at the
 * top of the hero while the cover fades, so the page seems to grow out of it. Once per browser session (shared with the
 * portal's intro), skipped for reduced motion; a tap or a key speeds it up. The cover is shown before the first paint by
 * the script in lib/intro.ts, and the hero's own entrance waits for it (see landing.css).
 */
export function LandingIntro() {
  const cover = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const root = document.documentElement;
    const element = cover.current;
    if (!element || root.dataset.intro === undefined) return;
    root.dataset.introPlayed = "";
    const { gsap } = registerGsap();
    const mark = element.querySelector<SVGSVGElement>("svg");
    const backdrop = element.querySelector<HTMLElement>("[data-intro-backdrop]");
    const target = document.querySelector<HTMLElement>("[data-hero-mark]");
    if (!mark || !backdrop) return;

    const paths = Array.from(mark.querySelectorAll("path"));
    for (const path of paths) {
      const length = path.getTotalLength();
      gsap.set(path, { strokeDasharray: length, strokeDashoffset: length, fillOpacity: 0, stroke: "currentColor", strokeWidth: 1.4 });
    }

    const finish = () => {
      try {
        sessionStorage.setItem(INTRO_STORAGE_KEY, "1");
      } catch {
        // Storage can be blocked; the intro then plays again next time.
      }
      root.dataset.introPlayed = "";
      delete root.dataset.intro;
      window.dispatchEvent(new Event(INTRO_DONE_EVENT));
    };

    // Where the drawn logo must land: the hero's logo, measured now (it is laid out, only hidden).
    const landing = () => {
      if (!target) return { x: 0, y: -40, scale: 0.4 };
      const from = mark.getBoundingClientRect();
      const to = target.getBoundingClientRect();
      return { x: to.left - from.left, y: to.top - from.top, scale: to.width / from.width };
    };

    const timeline = gsap
      .timeline({ onComplete: finish })
      .to(paths, { strokeDashoffset: 0, duration: 1.1, ease: "power2.inOut", stagger: { amount: 0.4 } })
      .to(paths, { fillOpacity: 1, duration: 0.5, ease: "power1.out" }, "-=0.25")
      .to(paths, { strokeOpacity: 0, duration: 0.4 }, "<")
      .addLabel("fly", "+=0.15")
      .to(mark, { x: () => landing().x, y: () => landing().y, scale: () => landing().scale, transformOrigin: "0 0", duration: 0.9, ease: "power3.inOut" }, "fly")
      .to(backdrop, { opacity: 0, duration: 0.7, ease: "power1.inOut" }, "fly+=0.2");

    const skip = () => timeline.timeScale(6);
    window.addEventListener("pointerdown", skip, { once: true });
    window.addEventListener("keydown", skip, { once: true });

    return () => {
      window.removeEventListener("pointerdown", skip);
      window.removeEventListener("keydown", skip);
      timeline.kill();
    };
  }, []);

  return (
    <div ref={cover} aria-hidden className="brand-intro landing-intro">
      <div data-intro-backdrop className="absolute inset-0 bg-bg" />
      <BrandMark className="relative h-auto w-56 text-fg sm:w-72" />
    </div>
  );
}
