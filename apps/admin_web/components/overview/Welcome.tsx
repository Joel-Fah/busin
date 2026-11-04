import Image from "next/image";
import Link from "next/link";
import type { CSSProperties } from "react";
import type { IconSvgElement } from "@hugeicons/react";

import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";

export type Insight = {
  key: string;
  href: string;
  icon: IconSvgElement;
  /** The figure the card is about, already formatted. */
  value: string;
  label: string;
  /** The one card that asks for action is set apart in the accent colour. */
  attention?: boolean;
};

type Props = {
  greeting: string;
  /** Today's date, already formatted for the reader. */
  date: string;
  summary: string;
  /** Two to four cards, fanned in an arc. More are ignored. */
  insights: readonly Insight[];
};

const STEP_DEG = 7;
const SAG_PX = 4;

/** Rotation and drop for card `index` of `count`: the middle sits highest, the ends tilt out and drop, so the row reads as an arc. */
export function fanPosition(index: number, count: number): { rotate: number; drop: number } {
  const centre = (count - 1) / 2;
  const offset = index - centre;
  return { rotate: offset * STEP_DEG, drop: offset * offset * SAG_PX };
}

/**
 * A greeting that also says what is worth a look. Always the deep brand teal, so it anchors the page in both
 * themes, with fine grain and the rough marker under the greeting (needs <RoughFilter /> on the page).
 * The insight cards are portrait links fanned like a hand; one lifts and straightens on hover or focus.
 * The bus is decoration: larger than its frame and cut off at the bottom only.
 */
export function Welcome({ greeting, date, summary, insights }: Props) {
  const cards = insights.slice(0, 4);
  return (
    <section
      data-testid="welcome"
      className="texture-grain relative overflow-hidden rounded-lg bg-seed p-7 text-white shadow-soft [--grain:1] [--thread-color:color-mix(in_srgb,white_26%,transparent)] sm:col-span-2 sm:p-9 xl:col-span-4"
    >
      <Contour radius={28} inset={14} />
      <Image
        src="/illustrations/bus.webp"
        alt=""
        width={480}
        height={480}
        priority
        className="pointer-events-none absolute -right-4 -bottom-16 hidden h-[26rem] w-[26rem] max-w-none sm:block lg:right-6 lg:-bottom-24 lg:h-[34rem] lg:w-[34rem]"
      />
      <div className="relative flex max-w-xl flex-col gap-4">
        <p className="m-0 text-sm font-semibold text-white/70">{date}</p>
        <h2 className="relative m-0 w-fit max-w-full text-3xl font-extrabold tracking-tight sm:text-4xl">
          <span aria-hidden className="texture-rough absolute inset-x-[-0.15em] bottom-[0.02em] h-[0.4em] rounded-xs bg-accent/70" />
          <span className="relative">{greeting}</span>
        </h2>
        <p className="m-0 text-base text-white/85">{summary}</p>
      </div>

      <ul className="relative m-0 mt-8 flex list-none items-end p-0 pb-2 pl-3 sm:pl-4">
        {cards.map((card, index) => {
          const { rotate, drop } = fanPosition(index, cards.length);
          const style = { "--r": `${rotate}deg`, "--y": `${drop}px`, zIndex: index + 1 } as CSSProperties;
          return (
            <li key={card.key} style={style} className={`${index === 0 ? "" : "-ml-7 sm:-ml-4"} origin-bottom transition-transform duration-(--dur) ease-soft`}>
              <Link
                href={card.href}
                className={
                  "relative flex h-40 w-24 origin-bottom flex-col justify-between rounded-md p-3 no-underline sm:p-4 shadow-float sm:h-48 sm:w-36 " +
                  "[transform:translateY(var(--y))_rotate(var(--r))] transition-transform duration-(--dur) ease-soft motion-reduce:transition-none " +
                  "hover:[transform:translateY(calc(var(--y)-18px))_rotate(0deg)] focus-visible:[transform:translateY(calc(var(--y)-18px))_rotate(0deg)] " +
                  "focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus " +
                  (card.attention
                    ? "bg-accent text-on-accent [--thread-color:color-mix(in_srgb,var(--on-accent)_38%,var(--accent))]"
                    : "bg-teal-50 text-seed [--thread-color:color-mix(in_srgb,var(--color-seed)_24%,transparent)]")
                }
              >
                <Contour radius={20} inset={8} dash={[5, 5]} />
                <Icon icon={card.icon} size={22} />
                <span className="relative flex flex-col gap-1">
                  <span className="text-2xl font-extrabold leading-none sm:text-3xl tracking-tight tabular-nums">{card.value}</span>
                  <span className="text-[11px] font-semibold leading-snug opacity-80 sm:text-xs">{card.label}</span>
                </span>
              </Link>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
