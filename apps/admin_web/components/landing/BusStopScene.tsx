import { Calendar03Icon, HourglassIcon, Invoice01Icon, Navigation03Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

import { SCENE_ART } from "./scene-art";
import "./scene-art.css";
import { SceneMotion } from "./SceneMotion";

/**
 * The small messages over the scene, all in the same quiet style. Three are what students mutter at a bus stop (each sits
 * by the person or thing it is about, its icon on a soft warning tint); one is BusIn answering (its icon on a soft green).
 * On a phone, where only the shelter and the sign fit, the answer and the timetable grumble show.
 */
const CHIPS: { key: keyof LandingCopy["hero"]["chips"]; icon: IconSvgElement; pos: string; answer?: boolean }[] = [
  { key: "receipt", icon: Invoice01Icon, pos: "hidden sm:flex left-[9%] bottom-[69%]" },
  { key: "timetable", icon: Calendar03Icon, pos: "flex right-[21%] bottom-[58%] sm:right-auto sm:left-[60%] sm:bottom-[82%]" },
  { key: "waiting", icon: HourglassIcon, pos: "hidden sm:flex left-[70%] bottom-[67%]" },
  { key: "busin", icon: Navigation03Icon, pos: "flex left-[28%] bottom-[86%] sm:left-[38%] sm:bottom-[85%]", answer: true },
];

/**
 * The bus stop at the start of the day, drawn to run the whole width of the page: a pale town behind, the campus and its
 * clock tower, planters along the back of the pavement, the shelter with a student on his phone and a bag left on the
 * bench, two friends arriving, one pacing by the sign, and the road melting into the page. The drawing is made by
 * `tools/landing-scene.mjs` and kept as markup in `scene-art.ts` (ours and fixed, never anything a visitor typed); its
 * colours follow the theme. Mostly still; the layers only settle in, once.
 */
export function BusStopScene({ chips }: { chips: LandingCopy["hero"]["chips"] }) {
  return (
    <SceneMotion className="relative -mt-2 h-[22rem] w-full sm:-mb-14 overflow-hidden [mask-image:linear-gradient(to_bottom,#000_80%,transparent_99%)] sm:h-auto sm:aspect-[16/5.3] sm:max-h-[38rem]">
      <div className="absolute left-1/2 top-0 h-full w-[max(100%,40rem)] -translate-x-1/2">
        <svg
          viewBox="0 110 1600 530"
          preserveAspectRatio="xMidYMax slice"
          aria-hidden
          data-scene-art
          className="absolute inset-0 size-full"
          dangerouslySetInnerHTML={{ __html: SCENE_ART }}
        />

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
