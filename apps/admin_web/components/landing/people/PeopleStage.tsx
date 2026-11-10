"use client";

import { useRef, type ReactNode } from "react";

import { useScrollScene } from "../motion/useScrollScene";

/**
 * Who it helps, then Calm by design, as one scene. With motion allowed (on any screen) the section holds still: the row
 * of cards slides across, the last card (a photo) grows from where it is until it fills the screen, and Calm by design
 * comes up over it, at the bottom. Otherwise (reduced motion, no scripts) the cards sit in a grid and Calm by design is a photo
 * panel under them; the last card is not shown, since the panel is the same photo.
 */
export function PeopleStage({ cards, final, calm }: { cards: ReactNode; final: ReactNode; calm: ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);

  useScrollScene(ref, ({ gsap, ScrollTrigger, wide, reduced, root }) => {
    if (reduced) return;
    const track = root.querySelector<HTMLElement>("[data-people-track]");
    const last = root.querySelector<HTMLElement>("[data-people-final]");
    const panel = root.querySelector<HTMLElement>("[data-calm]");
    if (!track || !last || !panel) return;
    root.classList.add("is-pinned");
    // The photo card is as tall as the other cards, and 16:9, so its width follows their height.
    const fit = () => {
      const card = others[0] as HTMLElement | undefined;
      // On a phone a 16:9 card that tall would be wider than the screen, so there it is the other cards' size.
      if (card) root.style.setProperty("--final-w", `${Math.round(wide ? card.offsetHeight * (16 / 9) : card.offsetWidth)}px`);
    };

    const distance = () => Math.max(0, track.scrollWidth - root.clientWidth);
    // Where the last card is once the row has slid, and how much it must grow to cover the screen.
    const centreX = () => track.offsetLeft + last.offsetLeft + last.offsetWidth / 2 - distance();
    const centreY = () => track.offsetTop + last.offsetTop + last.offsetHeight / 2;
    const cover = () => Math.max(root.clientWidth / last.offsetWidth, root.clientHeight / last.offsetHeight) * 1.02;
    const others = Array.from(track.children).filter((child) => child !== last);
    fit();
    ScrollTrigger.addEventListener("refreshInit", fit);
    // The card it shrinks back into: the page's width, with a margin above and below.
    const frameX = () => Math.max(20, (root.clientWidth - 88 * 16) / 2 + 32);
    const frameY = () => Math.round(root.clientHeight * 0.06);

    const scene = gsap.timeline({
      defaults: { ease: "none" },
      scrollTrigger: { trigger: root, start: "top top", end: () => `+=${distance() + root.clientHeight * 2}`, pin: true, scrub: 0.8, invalidateOnRefresh: true },
    });
    scene
      .to(track, { x: () => -distance(), duration: 1 })
      .addLabel("grow")
      .to(last.querySelectorAll("[data-final-fade]"), { autoAlpha: 0, duration: 0.2 }, "grow")
      .to(others, { autoAlpha: 0, duration: 0.4 }, "grow")
      .to(last, { x: () => root.clientWidth / 2 - centreX(), y: () => root.clientHeight / 2 - centreY(), scale: cover, borderRadius: 0, duration: 0.8, ease: "power2.inOut" }, "grow")
      // Calm by design comes up only once the photo fills the screen, so its white text never sits on the page.
      .fromTo(panel, { autoAlpha: 0 }, { autoAlpha: 1, duration: 0.3 }, "grow+=0.8")
      .from(panel.querySelectorAll("[data-calm-rise]"), { y: 36, autoAlpha: 0, stagger: 0.08, duration: 0.3, ease: "power2.out" }, "<0.05")
      .to({}, { duration: 0.35 })
      // Then the full screen shrinks back into a rounded card the width of the page, and the page scrolls on.
      .fromTo(
        root,
        { clipPath: "inset(0px 0px 0px 0px round 0px)" },
        { clipPath: () => `inset(${frameY()}px ${frameX()}px ${frameY()}px ${frameX()}px round 36px)`, duration: 0.5, ease: "power2.inOut" },
      );

    return () => {
      root.classList.remove("is-pinned");
      root.style.removeProperty("clip-path");
      root.style.removeProperty("--final-w");
      ScrollTrigger.removeEventListener("refreshInit", fit);
    };
  });

  return (
    <div ref={ref} className="people-stage relative mt-14 lg:mt-16">
      <div data-people-track className="relative grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
        {cards}
        {final}
      </div>
      {calm}
    </div>
  );
}
