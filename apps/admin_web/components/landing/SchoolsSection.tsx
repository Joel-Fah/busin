import { Add01Icon, School01Icon, Tick02Icon } from "@hugeicons/core-free-icons";

import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";
import type { WallSchool } from "@/lib/landing/schools";

import { InterestButton } from "./interest/Interest";
import { Reveal } from "./motion/Reveal";


/**
 * Schools that chose better: the schools that ride with BusIn, open places beside them that invite the next ones, a
 * slow band of "your school here" and the button that opens the interest form for a school.
 */
export function SchoolsSection({ copy, schools }: { copy: LandingCopy["schools"]; schools: WallSchool[] }) {
  const band = [...schools.map((s) => s.name), copy.slot, copy.slot, copy.slot];
  // Open places fill the wall so it never looks empty, and always invite the next school.
  const open = Math.max(2, (schools.length > 0 ? 5 : 6) - Math.max(0, schools.length - 1));
  return (
    <>
      <div className="mt-14 grid gap-8 lg:grid-cols-[0.9fr_1.1fr] lg:items-center">
        <Reveal className="flex flex-col gap-6">
          <p className="m-0 max-w-[30rem] text-pretty text-lg leading-relaxed text-muted">{copy.lead}</p>
          <ul className="m-0 flex list-none flex-col gap-2.5 p-0">
            {copy.points.map((point) => (
              <li key={point} className="flex items-center gap-2.5 font-semibold">
                <span className="grid size-6 shrink-0 place-items-center rounded-xs bg-ok-bg text-ok">
                  <Icon icon={Tick02Icon} size={14} />
                </span>
                {point}
              </li>
            ))}
          </ul>
          <InterestButton kind="school" className="w-fit">
            {copy.invite}
          </InterestButton>
        </Reveal>

        <ul className="m-0 grid list-none grid-cols-2 gap-4 p-0 sm:grid-cols-3">
          {schools.map((school, i) => (
            <Reveal
              as="li"
              key={school.id}
              className={`relative flex flex-col justify-between gap-6 rounded-xl bg-seed p-6 text-white [--thread-color:rgb(255_255_255/0.22)] dark:bg-teal-900 ${i === 0 ? "col-span-2 sm:row-span-2" : ""}`}
            >
              <Contour radius={36} inset={10} />
              <span className="relative grid size-16 place-items-center rounded-md bg-white text-lg font-black tracking-tight text-seed">
                {school.logo ? (
                  // eslint-disable-next-line @next/next/no-img-element -- the school's public logo file, already 512 px WebP
                  <img src={school.logo} alt="" width={64} height={64} className="size-12 object-contain" />
                ) : (
                  school.initials
                )}
              </span>
              <span className="relative flex flex-col gap-2">
                <span className={`font-extrabold tracking-tight ${i === 0 ? "text-2xl" : "text-lg"}`}>{school.name}</span>
                {school.city ? <span className="-mt-1 text-sm text-white/70">{school.city}</span> : null}
                <span className="flex w-fit items-center gap-1.5 rounded-xs bg-white/12 px-2.5 py-1 text-xs font-bold">
                  <span aria-hidden className="size-2 rounded-full bg-accent" />
                  {copy.trusted}
                </span>
              </span>
            </Reveal>
          ))}
          {Array.from({ length: open }, (_, i) => (
            <Reveal as="li" key={i} delay={0.08 * i} className={i >= 3 ? "hidden sm:block" : ""}>
              <div className="flex h-full min-h-32 flex-col items-center justify-center gap-2 rounded-lg border-2 border-dashed border-line p-4 text-center text-sm font-semibold text-muted">
                <span className="grid size-9 place-items-center rounded-xs bg-surface-2">
                  <Icon icon={Add01Icon} size={18} />
                </span>
                {copy.slot}
              </div>
            </Reveal>
          ))}
        </ul>
      </div>

      <div aria-hidden className="landing-band relative mt-12 overflow-hidden py-8 [mask-image:linear-gradient(to_right,transparent,#000_12%,#000_88%,transparent)]">
        <div className="landing-marquee flex w-max">
          {[0, 1].map((copyIndex) => (
            <div key={copyIndex} className="flex gap-4 pr-4">
              {Array.from({ length: 4 }, () => band)
                .flat()
                .map((label, i) => (
                  <span
                    key={i}
                    className={`flex items-center gap-3 whitespace-nowrap rounded-sm py-3 pl-3 pr-5 text-sm font-bold ${label === copy.slot ? "bg-surface text-muted shadow-soft" : "bg-accent text-on-accent shadow-soft"}`}
                  >
                    <span className={`grid size-9 place-items-center rounded-xs ${label === copy.slot ? "bg-surface-2" : "bg-white/20"}`}>
                      <Icon icon={School01Icon} size={17} />
                    </span>
                    {label}
                  </span>
                ))}
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
