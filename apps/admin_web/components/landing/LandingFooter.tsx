import Link from "next/link";

import { BrandMark } from "@/components/brand/BrandMark";
import { LanguageSwitch } from "@/components/LanguageSwitch";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { FOOTER_YEAR } from "@/lib/landing/site";
import type { LandingCopy } from "@/lib/i18n/landing";
import type { Locale, Messages } from "@/lib/i18n/messages";

/** The end of the page: who we are in one line, the way in for staff, and the language and theme choices. */
export function LandingFooter({ copy, locale, t }: { copy: LandingCopy["footer"]; locale: Locale; t: Messages }) {
  return (
    <footer className="mx-auto mt-24 max-w-[88rem] px-5 pb-12 sm:px-8">
      <div className="flex flex-col gap-8 border-t border-dashed border-line pt-10 md:flex-row md:items-end md:justify-between">
        <div className="flex flex-col gap-3">
          <BrandMark className="h-10 w-auto" label="BusIn" />
          <p className="m-0 text-muted">{copy.tagline}</p>
          <Link href="/login" className="w-fit text-sm font-semibold">
            {copy.staff}
          </Link>
        </div>
        <div className="flex flex-wrap items-center gap-4">
          <LanguageSwitch locale={locale} t={t} />
          <ThemeToggle labels={t.profile.theme} />
        </div>
      </div>
      <p className="m-0 mt-8 text-sm text-muted">
        {copy.rights} {FOOTER_YEAR}
      </p>
    </footer>
  );
}
