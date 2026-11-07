import type { LandingCopy } from "@/lib/i18n/landing";

/** The first thing seen: one huge, heavy headline, centred on the sky. */
export function HeroHead({ copy }: { copy: LandingCopy["hero"] }) {
  return (
    <header className="relative z-10 px-4 pb-6 pt-16 text-center sm:pb-8 sm:pt-20">
      <p className="landing-rise m-0 mb-5 inline-flex items-center gap-2 rounded-xs bg-fg/8 px-3 py-1.5 text-sm font-semibold text-fg/80 sm:mb-6">
        <span aria-hidden className="size-2 rounded-full bg-accent" />
        {copy.eyebrow}
      </p>
      <h1 id="landing-title" className="landing-rise m-0 text-[clamp(2.6rem,11.6vw,8.8rem)] font-extrabold leading-[0.9] tracking-[-0.045em] text-fg">
        <span className="block">{copy.line1}</span>{" "}
        <span className="block">{copy.line2}</span>{" "}
        <span className="relative inline-block">
          <span aria-hidden className="texture-rough absolute inset-x-[-0.06em] bottom-[0.02em] h-[0.2em] rounded-xs bg-accent/75" />
          <span className="relative">{copy.marked}</span>
        </span>
      </h1>
    </header>
  );
}

/** Under the navigation: one calm paragraph and a way down to the story. */
export function HeroLead({ copy }: { copy: LandingCopy["hero"] }) {
  return (
    <div className="relative z-10 mx-auto flex max-w-[44rem] flex-col items-center gap-4 px-5 pt-8 text-center sm:pt-10">
      <p className="landing-rise m-0 text-pretty text-lg leading-relaxed text-fg/80 sm:text-xl">{copy.sub}</p>
      <a href="#day" className="landing-rise text-base font-semibold text-fg underline-offset-4 hover:underline">
        {copy.secondary}
      </a>
      <p className="landing-rise m-0 text-sm text-muted">{copy.note}</p>
    </div>
  );
}
