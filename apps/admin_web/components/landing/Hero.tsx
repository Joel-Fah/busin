import { ArrowDown01Icon, Download04Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import type { LandingCopy } from "@/lib/i18n/landing";

import { HeroStage } from "./HeroStage";

/** The first screen: the promise, two ways forward, and the pass on a phone with the bus arriving. */
export function Hero({ copy }: { copy: LandingCopy["hero"] }) {
  return (
    <section aria-labelledby="landing-title" className="px-3 pt-3 sm:px-5 sm:pt-5">
      <div className="texture-grain relative isolate mx-auto min-h-[40rem] max-w-[88rem] overflow-hidden rounded-xl bg-seed text-white [--grain:1] lg:min-h-[44rem]">
        {/* A route drawn across the panel, marching slowly: the ride is already underway. */}
        <svg aria-hidden viewBox="0 0 1400 800" preserveAspectRatio="xMidYMid slice" className="absolute inset-0 -z-10 size-full opacity-40">
          <path
            d="M-40 640 C 220 560, 300 760, 560 640 S 900 380, 1120 470 S 1360 280, 1460 300"
            fill="none"
            stroke="rgb(255 255 255 / 0.5)"
            strokeWidth="3"
            strokeLinecap="round"
            strokeDasharray="2 30"
            className="landing-route"
          />
          {[
            [560, 640],
            [1120, 470],
          ].map(([cx, cy]) => (
            <g key={cx}>
              <circle cx={cx} cy={cy} r="22" fill="none" stroke="rgb(255 255 255 / 0.35)" strokeWidth="2" />
              <circle cx={cx} cy={cy} r="7" fill="var(--color-orange-400)" />
            </g>
          ))}
        </svg>

        <div className="grid gap-4 px-7 pb-12 pt-32 sm:px-12 lg:grid-cols-[1.08fr_0.92fr] lg:items-center lg:px-16 lg:pb-16 lg:pt-36">
          <div>
            <p className="m-0 inline-flex items-center gap-2 rounded-xs bg-white/12 px-3 py-1.5 text-sm font-semibold">
              <span aria-hidden className="size-2 rounded-full bg-orange-400" />
              {copy.eyebrow}
            </p>
            <h1 id="landing-title" className="m-0 mt-6 text-balance text-5xl font-extrabold leading-[1.02] tracking-tight sm:text-6xl lg:text-[4.6rem]">
              {copy.titleLead}
              <br />
              <span className="relative inline-block">
                <span aria-hidden className="texture-rough absolute inset-x-[-0.12em] bottom-[0.04em] h-[0.4em] rounded-xs bg-orange-400/80" />
                <span className="relative">{copy.titleMarked}</span>
              </span>
            </h1>
            <p className="m-0 mt-7 max-w-[34rem] text-pretty text-lg leading-relaxed text-white/80">{copy.sub}</p>
            <div className="mt-9 flex flex-wrap items-center gap-3">
              <ButtonLink href="#download" icon={Download04Icon} className="h-12 px-7 text-base">
                {copy.primary}
              </ButtonLink>
              <ButtonLink
                href="#day"
                variant="ghost"
                icon={ArrowDown01Icon}
                className="h-12 px-6 text-base text-white [--thread-color:rgb(255_255_255/0.3)] hover:bg-white/10"
              >
                {copy.secondary}
              </ButtonLink>
            </div>
            <p className="m-0 mt-5 text-sm text-white/60">{copy.note}</p>
          </div>

          <HeroStage mock={copy.mock} />
        </div>
      </div>
    </section>
  );
}
