import { Calendar03Icon, HourglassIcon, Invoice01Icon, Navigation03Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";
import Image from "next/image";

import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

import "./bus-stop-scene.css";
import { SceneMotion } from "./SceneMotion";

/**
 * The small messages over the scene, all in the same quiet style. Three are what students mutter at a bus stop (each sits
 * by the person it is about, its icon on a soft warning tint); one is BusIn answering (its icon on a soft green). On a
 * phone, where only the shelter and the sign fit, the answer and the timetable grumble show. Positions are in percent of
 * the picture, so they follow it at every width.
 */
const CHIPS: { key: keyof LandingCopy["hero"]["chips"]; icon: IconSvgElement; pos: string; answer?: boolean }[] = [
  { key: "receipt", icon: Invoice01Icon, pos: "hidden sm:flex left-[11%] bottom-[56%]" },
  { key: "timetable", icon: Calendar03Icon, pos: "flex right-[33%] bottom-[58%] sm:right-auto sm:left-[58%] sm:bottom-[70%]" },
  { key: "waiting", icon: HourglassIcon, pos: "hidden lg:flex left-[69%] bottom-[56%]" },
  { key: "busin", icon: Navigation03Icon, pos: "flex left-[36%] bottom-[72%] sm:left-[37%] sm:bottom-[80%]", answer: true },
];

/** The background is 3584 x 1184 (exported at 3200 wide); everything below is placed in percent of it. */
const ASPECT = "3584 / 1184";

/**
 * The people, as cut-outs over the background: where the bottom left of each picture goes and how tall it is (percent of
 * the background), and the picture's own proportions. Standing people are a third of the height with their feet on the
 * pavement; the girl on the bench sits with her hips on the seat and her feet on the pavement in front of it.
 */
const PEOPLE: { src: string; alt: string; left: number; bottom: number; height: number; aspect: number }[] = [
  { src: "girl-walking", alt: "", left: 17.2, bottom: 16.8, height: 33, aspect: 418 / 560 },
  { src: "boy-walking", alt: "", left: 23.8, bottom: 16.8, height: 33, aspect: 419 / 560 },
  { src: "girl-bench", alt: "", left: 43.5, bottom: 17.4, height: 25.3, aspect: 465 / 560 },
  { src: "boy-waiting", alt: "", left: 66.9, bottom: 16.8, height: 33, aspect: 291 / 560 },
];

/** Lamps whose glow the night picture lost where it reached into the sky (cut away so the page's own sky shows). */
const LAMPS = [
  { left: 33.1, top: 30.2 },
  { left: 72.9, top: 46.5 },
];

/**
 * The bus stop at the start of the day, across the whole page: a campus street with its shelter, the tree and the tower,
 * and four students (two arriving, one on the bench on her phone, one checking his watch by the sign). Drawn as
 * illustrations in the BusIn people style (the styleguide, Imagery) and laid as layers: the street (a day and a night
 * picture, following the theme, the sky cut away so the page's own sky shows), then each person. The layers settle in
 * once; on a phone the shelter and the sign stay in view.
 */
export function BusStopScene({ chips }: { chips: LandingCopy["hero"]["chips"] }) {
  return (
    <SceneMotion className="relative -mt-2 h-[22rem] w-full overflow-hidden [mask-image:linear-gradient(to_bottom,#000_80%,transparent_99%)] sm:-mb-14 sm:h-auto sm:aspect-[16/5.3]">
      {/* The picture keeps its own proportions; on a narrow screen it is cut on both sides, around the shelter. */}
      <div className="absolute bottom-0 left-1/2 h-full -translate-x-1/2" style={{ aspectRatio: ASPECT }}>
        <div data-scene-layer className="absolute inset-0">
          <Image src="/landing/scene/background-day.webp" alt="" fill sizes="(min-width: 640px) 100vw, 1100px" className="scene-day object-cover" />
          <Image src="/landing/scene/background-night.webp" alt="" fill sizes="(min-width: 640px) 100vw, 1100px" className="scene-night object-cover" />
          {LAMPS.map((lamp) => (
            <span key={lamp.left} aria-hidden className="scene-night scene-glow" style={{ left: `${lamp.left}%`, top: `${lamp.top}%` }} />
          ))}
        </div>

        {PEOPLE.map((person) => (
          <div
            key={person.src}
            data-scene-layer
            className="scene-person absolute"
            style={{ left: `${person.left}%`, bottom: `${person.bottom}%`, height: `${person.height}%`, aspectRatio: person.aspect }}
          >
            <Image src={`/landing/scene/${person.src}.webp`} alt={person.alt} fill sizes="(min-width: 640px) 12vw, 120px" className="object-contain object-bottom" />
          </div>
        ))}

        {CHIPS.map((chip) => (
          <p
            key={chip.key}
            data-scene-chip
            className={`absolute m-0 items-center gap-2 rounded-md bg-surface py-1.5 pl-1.5 pr-3 text-xs font-semibold text-fg shadow-soft sm:text-sm ${chip.pos}`}
          >
            <span className={`grid size-7 shrink-0 place-items-center rounded-xs ${chip.answer ? "bg-ok-bg text-ok" : "bg-bad-bg text-bad"}`}>
              <Icon icon={chip.icon} size={15} />
            </span>
            {chips[chip.key]}
          </p>
        ))}
      </div>
    </SceneMotion>
  );
}
