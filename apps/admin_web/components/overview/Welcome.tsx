import Image from "next/image";
import { ArrowRight01Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import { Contour } from "@/components/ui/Contour";

type Props = {
  greeting: string;
  /** Today's date, already formatted for the reader. */
  date: string;
  summary: string;
  action: { href: string; label: string };
};

/**
 * A greeting that also says the one thing most worth doing. Always the deep brand teal, so it reads as the
 * anchor of the page in both themes. The illustration is decoration and is left out on small screens.
 */
export function Welcome({ greeting, date, summary, action }: Props) {
  return (
    <section
      data-testid="welcome"
      className="relative flex items-center justify-between gap-6 overflow-hidden rounded-lg bg-seed p-7 text-white shadow-soft sm:col-span-2 sm:p-9 xl:col-span-4 [--thread-color:color-mix(in_srgb,white_26%,transparent)]"
    >
      <Contour radius={28} inset={14} />
      <div className="relative flex max-w-xl flex-col gap-4">
        <p className="m-0 text-sm font-semibold text-white/70">{date}</p>
        <h2 className="m-0 text-3xl font-extrabold tracking-tight sm:text-4xl">{greeting}</h2>
        <p className="m-0 text-base text-white/85">{summary}</p>
        <div>
          <ButtonLink href={action.href} icon={ArrowRight01Icon}>
            {action.label}
          </ButtonLink>
        </div>
      </div>
      <Image src="/illustrations/bus.webp" alt="" width={200} height={200} className="relative hidden h-44 w-44 shrink-0 sm:block lg:h-52 lg:w-52" />
    </section>
  );
}
