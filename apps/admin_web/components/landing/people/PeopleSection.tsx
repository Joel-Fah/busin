import { Tick02Icon } from "@hugeicons/core-free-icons";
import Image from "next/image";

import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";
import { innerRadius } from "@/lib/ui/radius";

import { CalmPanel } from "../PrivateSection";
import { PeopleStage } from "./PeopleStage";

/** One photo per role (Pexels, chosen by the owner, cropped to 4:5, shown a little shorter: square on phones, 6:7 above) and a sticker from the portal's illustrations on its corner. */
const ART = [
  { photo: "/landing/people/students.webp", sticker: "/illustrations/ticket1.webp", tilt: "-rotate-6" },
  { photo: "/landing/people/driver.webp", sticker: "/illustrations/bus.webp", tilt: "rotate-3" },
  { photo: "/landing/people/staff.webp", sticker: "/illustrations/verified.webp", tilt: "-rotate-3" },
  { photo: "/landing/people/office.webp", sticker: "/illustrations/papers.webp", tilt: "rotate-6" },
] as const;

type Props = { copy: LandingCopy["people"]; calmHead: LandingCopy["sections"]["private"]; calm: LandingCopy["private"] };

/**
 * Who it helps: the student, the driver, the staff at the door and the school office, a card each; then a photo card
 * that invites the reader on and opens into Calm by design (see PeopleStage).
 */
export function PeopleSection({ copy, calmHead, calm }: Props) {
  const cards = (
    <>
      {copy.cards.map((card, i) => (
        <article key={card.role} className="people-card relative flex flex-col gap-5 rounded-xl bg-surface p-6 shadow-soft [--thread-color:var(--color-line)]">
          <Contour radius={36} inset={10} />
          {/* The card is 36 round and the photo sits 24 in, so its corners are 12 (concentric with the card and its thread). */}
          <div className="relative">
            <Image
              src={ART[i].photo}
              alt={card.photo}
              width={720}
              height={900}
              sizes="(min-width: 1280px) 22rem, (min-width: 640px) 45vw, 90vw"
              className="aspect-square h-auto w-full bg-surface-2 object-cover object-[50%_35%] sm:aspect-[6/7]"
              style={{ borderRadius: innerRadius(36, 24) }}
            />
            <Image
              src={ART[i].sticker}
              alt=""
              width={96}
              height={96}
              className={`absolute -bottom-5 right-4 h-16 w-auto drop-shadow-[0_10px_12px_rgb(0_20_26/0.25)] ${ART[i].tilt}`}
            />
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
    </>
  );

  const final = (
    <article data-people-final className="people-final relative shrink-0 overflow-hidden rounded-xl bg-seed text-white shadow-float [--thread-color:rgb(255_255_255/0.45)]">
      <Image src="/landing/calm.webp" alt={copy.invite.photo} fill sizes="100vw" className="object-cover" />
      <span data-final-fade aria-hidden className="absolute inset-0 bg-linear-to-t from-[#00141b]/85 via-[#00141b]/25 to-transparent" />
      <span data-final-fade aria-hidden className="absolute inset-0">
        <Contour radius={36} inset={12} />
      </span>
      <div data-final-fade className="absolute inset-x-0 bottom-0 flex flex-col gap-2 p-8 sm:p-10">
        <h3 className="m-0 text-3xl font-extrabold tracking-tight">{copy.invite.title}</h3>
        <p className="m-0 max-w-[28rem] text-lg leading-relaxed text-white/80">{copy.invite.text}</p>
      </div>
    </article>
  );

  return <PeopleStage cards={cards} final={final} calm={<CalmPanel head={calmHead} copy={calm} />} />;
}
