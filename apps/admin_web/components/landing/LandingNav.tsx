"use client";

import Link from "next/link";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { Cancel01Icon, Menu03Icon, SmartPhone01Icon } from "@hugeicons/core-free-icons";

import { BrandMark } from "@/components/brand/BrandMark";
import { Icon } from "@/components/ui/Icon";
import type { LandingCopy } from "@/lib/i18n/landing";

const LINKS = ["day", "people", "schools", "faq"] as const;

type Props = {
  copy: LandingCopy["nav"];
  /** The theme and language choices, rendered by the server (the language one is a server form). */
  switches: ReactNode;
};

/**
 * The navigation sits right under the big headline, as plain text on the sky. When it reaches the top of the screen it
 * stays there and the wordmark and a soft backdrop appear, so it blends in rather than switching to a different bar. On a
 * small screen the sections and the choices fold into a menu that needs no script.
 */
export function LandingNav({ copy, switches }: Props) {
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

  const link =
    "rounded-sm px-4 py-2.5 text-sm font-semibold text-fg no-underline transition-colors duration-(--dur) hover:bg-fg/8 focus-visible:outline-3 focus-visible:outline-focus";

  return (
    <>
      <div ref={sentinel} aria-hidden className="h-px" />
      <nav
        aria-label={copy.label}
        data-stuck={stuck}
        className="sticky top-0 z-40 border-b border-transparent transition-[background-color,border-color,backdrop-filter] duration-(--dur-slow) ease-soft data-[stuck=true]:border-line/70 data-[stuck=true]:bg-glass data-[stuck=true]:backdrop-blur-(--glass-blur)"
      >
        <div className="mx-auto grid max-w-[88rem] grid-cols-[1fr_auto_1fr] items-center gap-3 px-3 py-3 sm:px-8">
          <div className="flex items-center">
            <Link
              href="/"
              aria-label="BusIn"
              tabIndex={stuck ? 0 : -1}
              className="hidden rounded-sm p-1 text-fg opacity-0 transition-opacity duration-(--dur-slow) focus-visible:outline-3 focus-visible:outline-focus data-[stuck=true]:opacity-100 md:block"
              data-stuck={stuck}
            >
              <BrandMark className="h-8 w-auto" />
            </Link>
            <details className="group relative md:hidden">
              <summary
                aria-label={copy.menu}
                className="grid size-11 cursor-pointer list-none place-items-center rounded-sm text-fg focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden"
              >
                <Icon icon={Menu03Icon} size={22} className="group-open:hidden" />
                <Icon icon={Cancel01Icon} size={22} className="hidden group-open:block" />
              </summary>
              <div className="absolute left-0 top-[calc(100%+0.5rem)] flex w-60 flex-col gap-1 rounded-lg bg-surface p-2 shadow-float">
                {LINKS.map((key) => (
                  <a key={key} href={`#${key}`} className={link}>
                    {copy[key]}
                  </a>
                ))}
                <div className="mt-1 flex flex-wrap items-center gap-2 border-t border-dashed border-line px-2 pt-3">{switches}</div>
              </div>
            </details>
          </div>

          <div className="hidden items-center gap-1 md:flex">
            {LINKS.map((key) => (
              <a key={key} href={`#${key}`} className={link}>
                {copy[key]}
              </a>
            ))}
          </div>
          <div className="md:hidden" />

          <div className="flex items-center justify-end gap-2">
            <div className="hidden items-center gap-2 md:flex">{switches}</div>
            <a
              href="#download"
              aria-label={copy.cta}
              className="inline-flex h-11 items-center justify-center gap-2 rounded-sm bg-accent px-3.5 text-sm font-semibold text-on-accent no-underline transition-[filter,transform] duration-(--dur-fast) hover:brightness-105 active:scale-[0.98] focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus sm:px-5"
            >
              <Icon icon={SmartPhone01Icon} size={18} />
              <span className="hidden sm:inline">{copy.cta}</span>
            </a>
          </div>
        </div>
      </nav>
    </>
  );
}
