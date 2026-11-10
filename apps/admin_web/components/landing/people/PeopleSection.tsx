import { Tick02Icon } from "@hugeicons/core-free-icons";
import Image from "next/image";

import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

import { PeopleTrack } from "./PeopleTrack";

/** One sticker per role, from the illustrations the portal already uses, and the tint behind it. */
const ART = [
  { src: "/illustrations/ticket1.webp", tint: "bg-accent/15", tilt: "-rotate-6" },
  { src: "/illustrations/bus.webp", tint: "bg-ok-bg", tilt: "rotate-3" },
  { src: "/illustrations/verified.webp", tint: "bg-info-bg", tilt: "-rotate-3" },
  { src: "/illustrations/papers.webp", tint: "bg-warn-bg", tilt: "rotate-6" },
] as const;

/** Who it helps: the student, the driver, the staff at the door and the school office, a card each. */
export function PeopleSection({ copy }: { copy: LandingCopy["people"] }) {
  return (
    <PeopleTrack>
      {copy.cards.map((card, i) => (
        <article key={card.role} className="people-card relative flex flex-col gap-5 rounded-xl bg-surface p-8 shadow-soft [--thread-color:var(--color-line)]">
          <Contour radius={36} inset={10} />
          <div className={`relative grid h-40 place-items-center rounded-lg ${ART[i].tint}`}>
            <Image src={ART[i].src} alt="" width={160} height={160} className={`h-32 w-auto drop-shadow-[0_10px_12px_rgb(0_20_26/0.18)] ${ART[i].tilt}`} />
          </div>
          <div className="relative flex flex-col gap-2">
            <h3 className="m-0 text-2xl font-extrabold tracking-tight">{card.role}</h3>
            <p className="m-0 text-pretty leading-relaxed text-muted">{card.line}</p>
          </div>
          <ul className="relative m-0 mt-auto flex list-none flex-col gap-2 p-0">
            {card.points.map((point) => (
              <li key={point} className="flex items-center gap-2.5 text-sm font-semibold">
                <span className="grid size-5 shrink-0 place-items-center rounded-xs bg-ok-bg text-ok">
                  <Icon icon={Tick02Icon} size={12} />
                </span>
                {point}
              </li>
            ))}
          </ul>
        </article>
      ))}
    </PeopleTrack>
  );
}
