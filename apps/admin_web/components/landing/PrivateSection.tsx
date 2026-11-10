import { School01Icon, LocationOffline01Icon, WifiOff01Icon } from "@hugeicons/core-free-icons";

import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

import { Reveal } from "./motion/Reveal";
import { SectionHead } from "./SectionHead";

const ICONS = [School01Icon, LocationOffline01Icon, WifiOff01Icon];

/** Yours, and private: a dark panel with three calm facts. */
export function PrivateSection({ head, copy }: { head: LandingCopy["sections"]["private"]; copy: LandingCopy["private"] }) {
  return (
    <div className="texture-grain relative overflow-hidden rounded-xl bg-seed px-6 py-14 text-white dark:bg-teal-900 [--thread-color:rgb(255_255_255/0.22)] sm:px-12 sm:py-20">
      <Contour radius={36} inset={14} />
      <div className="relative">
        <SectionHead id="private" dark {...head} />
        <div className="mt-12 grid gap-5 md:grid-cols-3">
          {copy.facts.map((fact, i) => (
            <Reveal key={fact.title} delay={i * 0.12} className="flex flex-col gap-4 rounded-lg bg-white/8 p-6">
              <span className="grid size-12 place-items-center rounded-md bg-accent text-on-accent">
                <Icon icon={ICONS[i]} size={24} />
              </span>
              <h3 className="m-0 text-xl font-extrabold tracking-tight text-white">{fact.title}</h3>
              <p className="m-0 leading-relaxed text-white/75">{fact.text}</p>
            </Reveal>
          ))}
        </div>
      </div>
    </div>
  );
}
