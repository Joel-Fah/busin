import { Accordion } from "@/components/ui/Accordion";
import type { LandingCopy } from "@/lib/i18n/landing";

import { Reveal } from "./motion/Reveal";

/** Good to know: short answers, each in a row that opens (the browser's own details element, so no script is needed). */
export function FaqSection({ copy }: { copy: LandingCopy["faq"] }) {
  return (
    <div className="mt-12 flex max-w-[52rem] flex-col gap-3">
      {copy.items.map((item, i) => (
        <Reveal key={item.q} delay={0.05 * i}>
          <Accordion defaultOpen={i === 0} summary={<h3 className="m-0 text-lg font-bold">{item.q}</h3>}>
            <p className="m-0 max-w-[44rem] text-pretty leading-relaxed text-muted">{item.a}</p>
          </Accordion>
        </Reveal>
      ))}
    </div>
  );
}
