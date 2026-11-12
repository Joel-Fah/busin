"use client";

import { useEffect, useRef } from "react";
import { gsap } from "gsap";

import { INTRO_DONE_EVENT, INTRO_STORAGE_KEY } from "@/lib/intro";

import { BrandMark } from "./BrandMark";

/**
 * Opening animation: the logo outline draws itself, then fills in, then the cover fades away and the
 * navigation bar slides in. Once per session, and skipped when the device asks for reduced motion.
 * Click or press a key to skip. The cover is shown by the pre-paint script (see lib/intro.ts).
 */
export function BrandIntro() {
  const cover = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const root = document.documentElement;
    const element = cover.current;
    if (!element || root.dataset.intro === undefined) return;

    const paths = Array.from(element.querySelectorAll("path"));
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
      delete root.dataset.intro;
      window.dispatchEvent(new Event(INTRO_DONE_EVENT));
    };

    const timeline = gsap
      .timeline({ onComplete: finish })
      .to(paths, { strokeDashoffset: 0, duration: 1.5, ease: "power2.inOut", stagger: 0.12 })
      .to(paths, { fillOpacity: 1, duration: 0.7, ease: "power1.out" }, "-=0.25")
      .to(paths, { strokeOpacity: 0, duration: 0.4 }, "<")
      .to(element, { opacity: 0, duration: 0.5, delay: 0.35, ease: "power1.inOut" });

    const skip = () => timeline.timeScale(8);
    window.addEventListener("pointerdown", skip, { once: true });
    window.addEventListener("keydown", skip, { once: true });

    return () => {
      window.removeEventListener("pointerdown", skip);
      window.removeEventListener("keydown", skip);
      timeline.kill();
    };
  }, []);

  return (
    <div ref={cover} aria-hidden className="brand-intro">
      <BrandMark className="h-auto w-56 text-brand sm:w-72" />
    </div>
  );
}
