import { LocationOffline01Icon, School01Icon, WifiOff01Icon } from "@hugeicons/core-free-icons";
import Image from "next/image";

import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

import { SectionHead } from "./SectionHead";

const ICONS = [School01Icon, LocationOffline01Icon, WifiOff01Icon];

/**
 * Calm by design: three calm facts over the photo of a bus stop seen from above. On its own (phones, reduced motion) it
 * is a rounded photo panel; in the wide scene it lies over the whole screen, on the photo card that grew to fill it
 * (see PeopleStage), so its own photo and frame are hidden there.
 */
export function CalmPanel({ head, copy }: { head: LandingCopy["sections"]["private"]; copy: LandingCopy["private"] }) {
  return (
    <section data-calm aria-labelledby="private" className="calm-panel relative mt-28 overflow-hidden rounded-xl text-white [--thread-color:rgb(255_255_255/0.3)] sm:mt-36">
      <Image src="/landing/calm.webp" alt="" fill sizes="100vw" className="calm-photo object-cover" />
      <span aria-hidden className="absolute inset-0 bg-linear-to-t from-[#00141b]/92 via-[#00141b]/72 to-[#00141b]/50" />
      <span aria-hidden className="calm-frame">
        <Contour radius={36} inset={14} />
      </span>
      <div className="calm-inner relative mx-auto max-w-[88rem] px-6 py-14 sm:px-12 sm:py-20">
        <div data-calm-rise>
          <SectionHead id="private" dark {...head} />
        </div>
        <div className="mt-12 grid gap-5 md:grid-cols-3">
          {copy.facts.map((fact, i) => (
            <div key={fact.title} data-calm-rise className="calm-fact flex flex-col gap-4 rounded-lg bg-white/10 p-6 backdrop-blur-md">
              <span className="grid size-12 place-items-center rounded-md bg-accent text-on-accent">
                <Icon icon={ICONS[i]} size={24} />
              </span>
              <h3 className="m-0 text-xl font-extrabold tracking-tight text-white">{fact.title}</h3>
              <p className="m-0 leading-relaxed text-white/80">{fact.text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
