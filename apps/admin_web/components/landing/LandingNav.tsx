"use client";

import Link from "next/link";
import { useEffect, useRef, useState, useSyncExternalStore } from "react";
import { Cancel01Icon, ComputerIcon, Menu03Icon, Moon02Icon, SmartPhone01Icon, Sun03Icon } from "@hugeicons/core-free-icons";

import { BrandMark } from "@/components/brand/BrandMark";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import { applyTheme, readTheme, subscribeTheme } from "@/components/ui/ThemeToggle";
import { setLocale } from "@/lib/i18n/actions";
import type { LandingCopy } from "@/lib/i18n/landing";
import type { Locale } from "@/lib/i18n/messages";
import { THEMES } from "@/lib/theme";

const LINKS = ["day", "people", "schools", "faq"] as const;
const THEME_ICONS = { system: ComputerIcon, light: Sun03Icon, dark: Moon02Icon } as const;

type Labels = {
  theme: { group: string; system: string; light: string; dark: string };
  language: { label: string; en: string; fr: string };
};

type Props = { copy: LandingCopy["nav"]; locale: Locale; labels: Labels };

/** One round button for the theme: it shows the current choice and a press moves to the next one. */
function ThemeButton({ labels }: { labels: Labels["theme"] }) {
  const current = useSyncExternalStore(subscribeTheme, readTheme, () => "system" as const);
  const next = THEMES[(THEMES.indexOf(current) + 1) % THEMES.length];
  return (
    <button
      type="button"
      onClick={() => applyTheme(next)}
      aria-label={`${labels.group}: ${labels[current]}`}
      title={`${labels.group}: ${labels[current]}`}
      className="grid size-10 cursor-pointer place-items-center rounded-sm border-0 bg-transparent text-fg transition-colors duration-(--dur-fast) hover:bg-fg/8 focus-visible:outline-3 focus-visible:outline-focus"
    >
      <Icon icon={THEME_ICONS[current]} size={19} />
    </button>
  );
}

/** One button for the language: it shows the current code and a press switches to the other language. */
function LocaleButton({ locale, labels }: { locale: Locale; labels: Labels["language"] }) {
  const other: Locale = locale === "en" ? "fr" : "en";
  return (
    <form action={setLocale}>
      <input type="hidden" name="locale" value={other} />
      <button
        type="submit"
        aria-label={`${labels.label}: ${labels[other]}`}
        title={labels[other]}
        className="grid h-10 min-w-10 cursor-pointer place-items-center rounded-sm border-0 bg-transparent px-2 font-sans text-sm font-bold text-fg transition-colors duration-(--dur-fast) hover:bg-fg/8 focus-visible:outline-3 focus-visible:outline-focus"
      >
        {locale.toUpperCase()}
      </button>
    </form>
  );
}

/**
 * The navigation sits right under the big headline as plain tabs and the main button. When it reaches the top of the screen
 * it becomes the floating threaded bar, and the wordmark and the theme and language buttons slide in. On a small screen the
 * tabs fold into a menu that needs no script.
 */
export function LandingNav({ copy, locale, labels }: Props) {
  const sentinel = useRef<HTMLDivElement>(null);
  const [stuck, setStuck] = useState(false);

  useEffect(() => {
    const el = sentinel.current;
    if (!el) return;
    // The sentinel scrolls off the top exactly when the bar reaches it.
    const observer = new IntersectionObserver(([entry]) => setStuck(!entry.isIntersecting && entry.boundingClientRect.top < 0), { threshold: 0 });
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  const tab =
    "rounded-sm px-4 py-2.5 text-sm font-semibold text-fg no-underline transition-colors duration-(--dur) hover:bg-fg/8 focus-visible:outline-3 focus-visible:outline-focus";
  // Parts that only exist once the bar is floating: they open from nothing, and cannot be tabbed to before.
  const reveal =
    "overflow-hidden transition-[max-width,opacity] duration-(--dur-slow) ease-soft max-w-0 opacity-0 group-data-[stuck=true]:opacity-100";

  return (
    <>
      <div ref={sentinel} aria-hidden className="h-px" />
      <div className="pointer-events-none sticky top-3 z-40 flex justify-center px-3">
        <nav
          aria-label={copy.label}
          data-stuck={stuck}
          className="group pointer-events-auto relative flex items-center gap-1 rounded-[28px] px-2 py-2 transition-[background-color,box-shadow,backdrop-filter] duration-(--dur-slow) ease-soft [--thread-color:color-mix(in_srgb,var(--fg)_16%,transparent)] data-[stuck=true]:bg-glass data-[stuck=true]:shadow-float data-[stuck=true]:backdrop-blur-(--glass-blur)"
        >
          <span aria-hidden className="pointer-events-none absolute inset-0 opacity-0 transition-opacity duration-(--dur-slow) group-data-[stuck=true]:opacity-100">
            <Contour radius={28} inset={5} dash={[6, 6]} />
          </span>

          <div inert={!stuck} className={`${reveal} group-data-[stuck=true]:max-w-16`}>
            <Link href="/" aria-label="BusIn" className="block rounded-sm px-2 py-1 text-fg focus-visible:outline-3 focus-visible:outline-focus">
              <BrandMark className="h-8 w-auto" />
            </Link>
          </div>

          <div className="relative hidden items-center gap-1 md:flex">
            {LINKS.map((key) => (
              <a key={key} href={`#${key}`} className={tab}>
                {copy[key]}
              </a>
            ))}
          </div>

          <details className="group/menu relative md:hidden">
            <summary
              aria-label={copy.menu}
              className="grid size-11 cursor-pointer list-none place-items-center rounded-sm text-fg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden"
            >
              <Icon icon={Menu03Icon} size={22} className="group-open/menu:hidden" />
              <Icon icon={Cancel01Icon} size={22} className="hidden group-open/menu:block" />
            </summary>
            <div className="absolute left-0 top-[calc(100%+0.75rem)] flex w-60 flex-col gap-1 rounded-lg bg-surface p-2 shadow-float">
              {LINKS.map((key) => (
                <a key={key} href={`#${key}`} className={tab}>
                  {copy[key]}
                </a>
              ))}
              <div className="mt-1 flex items-center gap-1 border-t border-dashed border-line px-1 pt-2">
                <ThemeButton labels={labels.theme} />
                <LocaleButton locale={locale} labels={labels.language} />
              </div>
            </div>
          </details>

          <div inert={!stuck} className={`${reveal} hidden group-data-[stuck=true]:max-w-32 md:block`}>
            <div className="flex items-center gap-1 pl-1">
              <ThemeButton labels={labels.theme} />
              <LocaleButton locale={locale} labels={labels.language} />
            </div>
          </div>

          <a
            href="#download"
            aria-label={copy.cta}
            className="relative inline-flex h-11 items-center justify-center gap-2 rounded-sm bg-accent px-3.5 text-sm font-semibold text-on-accent no-underline transition-[filter,transform] duration-(--dur-fast) hover:brightness-105 active:scale-[0.98] focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus sm:px-5"
          >
            <Icon icon={SmartPhone01Icon} size={18} />
            <span className="hidden sm:inline">{copy.cta}</span>
          </a>
        </nav>
      </div>
    </>
  );
}
