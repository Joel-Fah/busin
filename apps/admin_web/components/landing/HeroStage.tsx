"use client";

import Image from "next/image";
import { useRef } from "react";
import { Notification03Icon, Navigation03Icon } from "@hugeicons/core-free-icons";

import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

import { PassCard } from "./PassCard";
import { Parallax } from "./motion/Parallax";
import { useScrollScene } from "./motion/useScrollScene";

/**
 * The hero's picture: a phone showing the boarding pass, the bus sticker rolling in, and two small messages that arrive.
 * Everything settles in on load and then floats gently; under reduced motion it is simply there.
 */
export function HeroStage({ mock }: { mock: LandingCopy["hero"]["mock"] }) {
  const ref = useRef<HTMLDivElement>(null);

  useScrollScene(ref, ({ gsap, reduced, root }) => {
    if (reduced) return;
    const q = gsap.utils.selector(root);
    const tl = gsap.timeline({ defaults: { ease: "power3.out" }, delay: 0.15 });
    tl.from(q("[data-phone]"), { y: 90, opacity: 0, rotate: 5, duration: 1.1 })
      .from(q("[data-bus]"), { x: -260, opacity: 0, rotate: -4, duration: 1.2, ease: "power4.out" }, "-=0.7")
      .from(q("[data-note]"), { y: 24, opacity: 0, scale: 0.92, duration: 0.7, stagger: 0.22 }, "-=0.5");
  });

  return (
    <div ref={ref} className="relative mx-auto flex w-full max-w-[34rem] items-center justify-center pb-24 pt-10 sm:pb-28 lg:pb-16 lg:pt-6">
      <Parallax shift={-40} className="relative">
        <div data-phone className="landing-float relative w-[17rem] rotate-[-3deg] rounded-[2.4rem] border-[10px] border-[#06161a] bg-[#06161a] shadow-float ring-2 ring-white/20 sm:w-[19.5rem] lg:w-[21rem]">
          <div className="overflow-hidden rounded-[1.7rem] bg-bg p-3">
            <PassCard mock={mock} />
          </div>
        </div>

        <div data-note className="absolute -right-3 -top-7 z-10 flex max-w-[15rem] items-start gap-3 rounded-md bg-surface p-3 text-fg shadow-float sm:-right-14">
          <span className="grid size-9 shrink-0 place-items-center rounded-sm bg-ok-bg text-ok">
            <Icon icon={Notification03Icon} size={18} />
          </span>
          <p className="m-0 text-sm font-semibold leading-snug">{mock.approved}</p>
        </div>

        <div data-note className="absolute -bottom-5 -right-3 z-10 flex items-center gap-3 rounded-md bg-surface p-3 text-fg shadow-float sm:-right-16">
          <span className="grid size-9 shrink-0 place-items-center rounded-sm bg-info-bg text-info">
            <Icon icon={Navigation03Icon} size={18} />
          </span>
          <p className="m-0 text-sm font-semibold">{mock.eta}</p>
        </div>

        <Image
          data-bus
          src="/illustrations/bus-large.webp"
          alt=""
          width={960}
          height={830}
          priority
          sizes="(min-width: 640px) 256px, 184px"
          className="pointer-events-none absolute -bottom-16 -left-14 z-20 h-auto w-[11.5rem] drop-shadow-[0_18px_24px_rgb(0_20_26/0.35)] sm:-bottom-20 sm:-left-28 sm:w-[16rem]"
        />
      </Parallax>
    </div>
  );
}
