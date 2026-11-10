import Link from "next/link";

import { BrandMark } from "@/components/brand/BrandMark";
import { LanguageSwitch } from "@/components/LanguageSwitch";
import { Contour } from "@/components/ui/Contour";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { FOOTER_YEAR } from "@/lib/landing/site";
import type { LandingCopy } from "@/lib/i18n/landing";
import type { Locale, Messages } from "@/lib/i18n/messages";

import { InterestButton } from "./interest/Interest";

type Props = { copy: LandingCopy["footer"]; nav: LandingCopy["nav"]; invite: string; locale: Locale; t: Messages };

const SECTIONS = ["day", "people", "schools", "faq"] as const;

/** The end of the page: who we are in one line, the sections, the way in for schools and for staff, and the language and theme choices. */
export function LandingFooter({ copy, nav, invite, locale, t }: Props) {
  return (
    <footer className="mx-auto mt-28 max-w-[88rem] px-5 pb-12 sm:px-8">
      <div className="relative grid gap-10 rounded-xl bg-surface p-8 shadow-soft [--thread-color:var(--color-line)] sm:p-12 md:grid-cols-[1.4fr_1fr_1fr]">
        <Contour radius={36} inset={12} />
        <div className="relative flex flex-col gap-3">
          <BrandMark className="h-10 w-auto self-start" label="BusIn" />
          <p className="m-0 max-w-[22rem] text-muted">{copy.tagline}</p>
          <div className="mt-2 flex flex-wrap items-center gap-4">
            <LanguageSwitch locale={locale} t={t} compact />
            <ThemeToggle labels={t.profile.theme} iconOnly />
          </div>
        </div>
        <nav aria-label={copy.explore} className="relative flex flex-col gap-3">
          <p className="m-0 text-sm font-bold text-muted">{copy.explore}</p>
          {SECTIONS.map((key) => (
            <a key={key} href={`#${key}`} className="w-fit font-semibold text-fg no-underline hover:text-accent">
              {nav[key]}
            </a>
          ))}
        </nav>
        <div className="relative flex flex-col items-start gap-3">
          <p className="m-0 text-sm font-bold text-muted">{copy.forSchools}</p>
          <InterestButton kind="school" variant="secondary">
            {invite}
          </InterestButton>
          <Link href="/login" className="mt-1 w-fit text-sm font-semibold text-fg no-underline hover:text-accent">
            {copy.staff}
          </Link>
        </div>
      </div>
      <p className="m-0 mt-6 px-2 text-sm text-muted">
        {copy.rights} {FOOTER_YEAR}
      </p>
    </footer>
  );
}
