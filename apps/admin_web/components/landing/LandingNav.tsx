"use client";

import Link from "next/link";
import { useEffect, useRef, useState, useSyncExternalStore, type ReactNode } from "react";
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

/** `menuControls`: the language and theme controls of the phone menu, the same ones as in the footer (rendered by the page). */
type Props = { copy: LandingCopy["nav"]; locale: Locale; labels: Labels; menuControls: ReactNode };

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
 * it becomes the floating threaded bar, and the wordmark and the theme and language buttons slide in.
 *
 * On a phone, before it floats, the tabs are a row you can swipe; once it floats, a menu button takes their place and the
 * tabs open inside the bar, the way the portal's bar does: the panel eases open and shut, and Escape, a tap outside or
 * picking a section closes it.
 */
export function LandingNav({ copy, locale, labels, menuControls }: Props) {
  const sentinel = useRef<HTMLDivElement>(null);
  const bar = useRef<HTMLElement>(null);
  const [stuck, setStuck] = useState(false);
  const [open, setOpen] = useState(false);
  const menuOpen = open && stuck;

  useEffect(() => {
    const el = sentinel.current;
    if (!el) return;
    // The sentinel scrolls off the top exactly when the bar reaches it.
    const observer = new IntersectionObserver(([entry]) => setStuck(!entry.isIntersecting && entry.boundingClientRect.top < 0), { threshold: 0 });
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  // Escape and a tap outside close the menu.
  useEffect(() => {
    if (!menuOpen) return;
    const onKey = (event: KeyboardEvent) => event.key === "Escape" && setOpen(false);
    const onPointer = (event: PointerEvent) => {
      if (bar.current && !bar.current.contains(event.target as Node)) setOpen(false);
    };
    window.addEventListener("keydown", onKey);
    window.addEventListener("pointerdown", onPointer);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("pointerdown", onPointer);
    };
  }, [menuOpen]);

  const tab =
    "shrink-0 whitespace-nowrap rounded-sm px-4 py-2.5 text-sm font-semibold text-fg no-underline transition-colors duration-(--dur) hover:bg-fg/8 focus-visible:outline-3 focus-visible:outline-focus";
  // Parts that only exist once the bar is floating: they open from nothing, and cannot be tabbed to before.
  const reveal =
    "overflow-hidden transition-[max-width,opacity] duration-(--dur-slow) ease-soft max-w-0 opacity-0 group-data-[stuck=true]:opacity-100";

  return (
    <>
      <div ref={sentinel} aria-hidden className="h-px" />
      {/* The slot keeps the height of the bar's row; the bar lies over it, so the phone menu opens above the page, not into it. */}
      <div className="pointer-events-none sticky top-3 z-40 h-[60px]">
        <nav
          ref={bar}
          aria-label={copy.label}
          data-stuck={stuck}
          className="group pointer-events-auto absolute left-1/2 top-0 flex w-max max-w-[calc(100vw-1.5rem)] -translate-x-1/2 flex-col rounded-[28px] transition-[background-color,box-shadow,backdrop-filter] duration-(--dur-slow) ease-soft [--thread-color:color-mix(in_srgb,var(--fg)_16%,transparent)] data-[stuck=true]:bg-glass data-[stuck=true]:shadow-float data-[stuck=true]:backdrop-blur-(--glass-blur) max-md:data-[stuck=true]:w-[calc(100vw-1.5rem)] max-md:data-[stuck=true]:max-w-md"
        >
          <span aria-hidden className="pointer-events-none absolute inset-0 opacity-0 transition-opacity duration-(--dur-slow) group-data-[stuck=true]:opacity-100">
            <Contour radius={28} inset={5} dash={[6, 6]} />
          </span>

          <div className="relative flex min-w-0 items-center gap-1 p-2">
            <div inert={!stuck} className={`${reveal} shrink-0 group-data-[stuck=true]:max-w-16`}>
              <Link href="/" aria-label="BusIn" className="block rounded-sm px-2 py-1 text-fg focus-visible:outline-3 focus-visible:outline-focus">
                <BrandMark className="h-8 w-auto" />
              </Link>
            </div>

            {/* Wide screens: the tabs, always. Phones: a row to swipe, only until the bar floats. */}
            <div
              data-nav-strip
              className="relative flex min-w-0 items-center gap-1 overflow-x-auto [scrollbar-width:none] max-md:[mask-image:linear-gradient(to_right,#000_85%,transparent)] max-md:group-data-[stuck=true]:hidden [&::-webkit-scrollbar]:hidden"
            >
              {LINKS.map((key) => (
                <a key={key} href={`#${key}`} className={tab}>
                  {copy[key]}
                </a>
              ))}
            </div>

            <button
              type="button"
              onClick={() => setOpen((value) => !value)}
              aria-expanded={menuOpen}
              aria-label={copy.menu}
              inert={!stuck}
              className="ml-auto hidden size-11 shrink-0 cursor-pointer place-items-center rounded-sm border-0 bg-transparent text-fg transition-colors duration-(--dur-fast) hover:bg-fg/8 focus-visible:outline-3 focus-visible:outline-focus max-md:group-data-[stuck=true]:grid"
            >
              <Icon icon={menuOpen ? Cancel01Icon : Menu03Icon} size={22} />
            </button>

            <div inert={!stuck} className={`${reveal} hidden shrink-0 group-data-[stuck=true]:max-w-32 md:block`}>
              <div className="flex items-center gap-1 pl-1">
                <ThemeButton labels={labels.theme} />
                <LocaleButton locale={locale} labels={labels.language} />
              </div>
            </div>

            <a
              href="#download"
              aria-label={copy.cta}
              className="relative inline-flex h-11 shrink-0 items-center justify-center gap-2 rounded-sm bg-accent px-3.5 text-sm font-semibold text-on-accent no-underline transition-[filter,transform] duration-(--dur-fast) hover:brightness-105 active:scale-[0.98] focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus sm:px-5"
            >
              <Icon icon={SmartPhone01Icon} size={18} />
              <span className="hidden sm:inline">{copy.cta}</span>
            </a>
          </div>

          {/* Phones, once floating: the sections open inside the bar. Inert while closed so it cannot take focus. */}
          <div
            inert={!menuOpen}
            data-nav-menu
            className={
              "relative grid transition-[grid-template-rows,opacity,visibility] duration-(--dur) ease-soft md:hidden " +
              (menuOpen ? "visible grid-rows-[1fr] opacity-100" : "invisible grid-rows-[0fr] opacity-0")
            }
          >
            <div className="overflow-hidden">
              <div className="flex flex-col gap-1 px-3 pb-4 pt-1">
                {LINKS.map((key) => (
                  <a key={key} href={`#${key}`} onClick={() => setOpen(false)} className={`${tab} py-3 text-base`}>
                    {copy[key]}
                  </a>
                ))}
                <div className="mt-2 flex flex-wrap items-center gap-3 px-1">{menuControls}</div>
              </div>
            </div>
          </div>
        </nav>
      </div>
    </>
  );
}
