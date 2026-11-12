import Image from "next/image";

import { Accordion } from "@/components/ui/Accordion";
import { Contour } from "@/components/ui/Contour";
import type { LandingCopy } from "@/lib/i18n/landing";

import { InterestButton } from "./interest/Interest";
import { Reveal } from "./motion/Reveal";

/**
 * Good to know: short answers in rows that open one at a time (the browser's own details element with a shared name,
 * so no script is needed), and beside them on a wide screen a card for the visitor whose school is not on BusIn yet.
 */
export function FaqSection({ copy }: { copy: LandingCopy["faq"] }) {
  return (
    <div className="mt-12 grid gap-8 lg:grid-cols-[minmax(0,1fr)_22rem] lg:items-start xl:gap-12">
      <div className="flex flex-col gap-3">
        {copy.items.map((item, i) => (
          <Reveal key={item.q} delay={0.05 * i}>
            <Accordion name="faq" defaultOpen={i === 0} summary={<h3 className="m-0 text-lg font-bold">{item.q}</h3>}>
              <p className="m-0 max-w-[44rem] text-pretty leading-relaxed text-muted">{item.a}</p>
            </Accordion>
          </Reveal>
        ))}
      </div>
      <Reveal as="aside" className="relative flex flex-col gap-4 overflow-hidden rounded-xl bg-surface p-8 shadow-soft [--thread-color:var(--color-line)] lg:sticky lg:top-28">
        <Contour radius={36} inset={10} />
        <Image src="/illustrations/bus-stop.webp" alt="" width={160} height={160} className="relative h-28 w-auto self-start drop-shadow-[0_10px_12px_rgb(0_20_26/0.2)]" />
        <h3 className="relative m-0 text-2xl font-extrabold tracking-tight">{copy.aside.title}</h3>
        <p className="relative m-0 leading-relaxed text-muted">{copy.aside.text}</p>
        <div className="relative mt-2 flex flex-wrap gap-3">
          <InterestButton kind="school">{copy.aside.school}</InterestButton>
          <InterestButton kind="notify" variant="secondary">
            {copy.aside.notify}
          </InterestButton>
        </div>
      </Reveal>
    </div>
  );
}
