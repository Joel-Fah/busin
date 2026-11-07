import Image from "next/image";

import type { LandingCopy } from "@/lib/i18n/landing";

/** Where each sticker sits around the headline, how it leans and how big it is. Alternating tilts, none too big. */
const STICKERS = [
  { src: "alarm-clock", pos: "left-[3%] top-0 sm:left-[4%] sm:top-[10%]", tilt: "-13deg", size: "w-[clamp(3.4rem,8.5vw,8rem)]", delay: "0.5s" },
  { src: "flip-phone", pos: "right-[4%] top-0 sm:right-[6%] sm:top-[8%]", tilt: "11deg", size: "w-[clamp(3rem,7.5vw,7rem)]", delay: "0.8s" },
  { src: "bus", pos: "left-[3%] bottom-0 sm:left-[9%] sm:bottom-[4%]", tilt: "-6deg", size: "w-[clamp(3.8rem,9.5vw,9rem)]", delay: "1.1s" },
  { src: "ticket", pos: "right-[4%] bottom-0 sm:right-[8%] sm:bottom-[6%]", tilt: "9deg", size: "w-[clamp(3rem,7vw,6.5rem)]", delay: "1.4s" },
] as const;

/** The first thing seen: one huge, heavy headline on two lines, centred on the sky, with stickers leaning around it. */
export function HeroHead({ copy }: { copy: LandingCopy["hero"] }) {
  return (
    <header className="relative z-10 px-4 pb-8 pt-16 text-center sm:pb-10 sm:pt-20">
      <p className="landing-rise m-0 mb-5 inline-flex items-center gap-2 rounded-xs bg-fg/8 px-3 py-1.5 text-sm font-semibold text-fg/80 sm:mb-6">
        <span aria-hidden className="size-2 rounded-full bg-accent" />
        {copy.eyebrow}
      </p>

      <div className="relative mx-auto max-w-[96rem] py-16 sm:py-12">
        {STICKERS.map((sticker) => (
          <Image
            key={sticker.src}
            src={`/landing/stickers/${sticker.src}.webp`}
            alt=""
            width={512}
            height={512}
            sizes="(min-width: 640px) 9vw, 14vw"
            style={{ ["--tilt" as string]: sticker.tilt, animationDelay: sticker.delay }}
            className={`landing-sticker pointer-events-none absolute z-0 h-auto drop-shadow-[0_10px_12px_rgb(0_20_26/0.2)] ${sticker.pos} ${sticker.size}`}
          />
        ))}
        <h1 id="landing-title" className="landing-rise relative z-10 m-0 text-[clamp(2.1rem,9.4vw,8.6rem)] font-extrabold leading-[0.98] tracking-[-0.04em] text-fg">
          <span className="block">{copy.line1}</span>{" "}
          <span className="relative inline-block">
            <span aria-hidden className="texture-rough absolute inset-x-[-0.05em] bottom-[0.02em] h-[0.2em] rounded-xs bg-accent/75" />
            <span className="relative">{copy.marked}</span>
          </span>
        </h1>
      </div>
    </header>
  );
}

/** Under the navigation: one calm paragraph. */
export function HeroLead({ copy }: { copy: LandingCopy["hero"] }) {
  return (
    <div className="relative z-10 mx-auto flex max-w-[44rem] flex-col items-center gap-3 px-5 pt-8 text-center sm:pt-10">
      <p className="landing-rise m-0 text-pretty text-lg leading-relaxed text-fg/80 sm:text-xl">{copy.sub}</p>
      <p className="landing-rise m-0 text-sm text-muted">{copy.note}</p>
    </div>
  );
}
