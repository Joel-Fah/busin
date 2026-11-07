import Link from "next/link";
import { Cancel01Icon, Menu03Icon } from "@hugeicons/core-free-icons";

import { BrandMark } from "@/components/brand/BrandMark";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

const LINKS = ["day", "people", "schools", "faq"] as const;

/**
 * The floating glass bar: the wordmark, the sections, one button. On a small screen the sections fold into a menu that
 * needs no script (a details element), so it works before and without JavaScript.
 */
export function LandingNav({ copy }: { copy: LandingCopy["nav"] }) {
  const link = "rounded-sm px-4 py-2.5 text-sm font-semibold text-fg no-underline transition-colors duration-(--dur-fast) hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus";
  return (
    <header className="pointer-events-none fixed inset-x-0 top-3 z-40 flex justify-center px-3 sm:top-5">
      <nav aria-label={copy.label} className="pointer-events-auto relative w-full max-w-[56rem] rounded-lg bg-glass shadow-float backdrop-blur-(--glass-blur) [--thread-color:color-mix(in_srgb,var(--fg)_16%,transparent)]">
        <Contour radius={24} inset={5} dash={[6, 6]} />
        <div className="flex items-center justify-between gap-3 px-4 py-3">
          <Link href="/" aria-label="BusIn" className="rounded-sm p-1 text-fg focus-visible:outline-3 focus-visible:outline-focus">
            <BrandMark className="h-8 w-auto" />
          </Link>

          <div className="hidden items-center gap-1 md:flex">
            {LINKS.map((key) => (
              <a key={key} href={`#${key}`} className={link}>
                {copy[key]}
              </a>
            ))}
          </div>

          <div className="flex items-center gap-2">
            <a
              href="#download"
              className="relative inline-flex h-10 items-center justify-center rounded-sm bg-accent px-5 text-sm font-semibold text-on-accent no-underline transition-[filter,transform] duration-(--dur-fast) hover:brightness-105 active:scale-[0.98] focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus"
            >
              {copy.cta}
            </a>
            <details className="group relative md:hidden">
              <summary
                aria-label={copy.menu}
                className="grid size-10 cursor-pointer list-none place-items-center rounded-sm bg-surface-2 text-fg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden"
              >
                <Icon icon={Menu03Icon} size={20} className="group-open:hidden" />
                <Icon icon={Cancel01Icon} size={20} className="hidden group-open:block" />
              </summary>
              <div className="absolute right-0 top-[calc(100%+0.75rem)] flex w-56 flex-col gap-1 rounded-lg bg-surface p-2 shadow-float">
                {LINKS.map((key) => (
                  <a key={key} href={`#${key}`} className={link}>
                    {copy[key]}
                  </a>
                ))}
              </div>
            </details>
          </div>
        </div>
      </nav>
    </header>
  );
}
