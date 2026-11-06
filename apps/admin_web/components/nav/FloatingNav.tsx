"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import {
  Cancel01Icon,
  GeometricShapes01Icon,
  Menu03Icon,
  Navigation03Icon,
  ReceiptTextIcon,
  Ticket03Icon,
  UserMultiple02Icon,
} from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";
import { gsap } from "gsap";

import { BrandMark } from "@/components/brand/BrandMark";
import { Avatar } from "@/components/ui/Avatar";
import { Contour } from "@/components/ui/Contour";
import { Icon } from "@/components/ui/Icon";
import { useSlidingIndicator } from "@/components/ui/useSlidingIndicator";
import { INTRO_DONE_EVENT } from "@/lib/intro";

import { NAV_DOCK_ID } from "./NavDock";

export type NavKey = "overview" | "subscriptions" | "people" | "trips" | "scans";

const ICONS: Record<NavKey, IconSvgElement> = {
  overview: GeometricShapes01Icon,
  subscriptions: Ticket03Icon,
  people: UserMultiple02Icon,
  trips: Navigation03Icon,
  scans: ReceiptTextIcon,
};

const HREFS: Record<NavKey, string> = {
  overview: "/",
  subscriptions: "/subscriptions",
  people: "/people",
  trips: "/trips",
  scans: "/scans",
};

type Props = {
  /** Tabs in the order they appear on a wide screen. */
  keys: NavKey[];
  labels: Record<NavKey, string>;
  /** How the tabs are grouped in the menu on small screens. */
  groups: { label: string; keys: NavKey[] }[];
  /** `also` lists the setup pages the profile page opens: the Profile tab stays lit while the admin is on one. */
  profile: { name: string; avatarUrl: string | null; href: string; also?: string[] };
  text: { primary: string; menu: string; closeMenu: string; profile: string; profileTab: string; home: string; current: string };
};

function isActive(pathname: string, key: NavKey): boolean {
  const href = HREFS[key];
  return href === "/" ? pathname === "/" : pathname === href || pathname.startsWith(`${href}/`);
}

const TAB =
  "relative flex flex-col items-center gap-1 rounded-sm px-3.5 py-2 text-xs font-semibold no-underline " +
  "transition-colors duration-(--dur-fast) ease-soft focus-visible:outline-3 focus-visible:outline-focus";
const TAB_ON = "bg-[color-mix(in_srgb,var(--fg)_9%,transparent)] text-fg";
const TAB_ACTIVE_TEXT = "text-fg";
const TAB_OFF = "text-muted hover:text-fg";

/**
 * The floating bar at the bottom of every admin page. Wide screens show every tab with icon and
 * label. Smaller screens show the current page and a menu button that opens the tabs upward in
 * place. A dock above the tabs (see NavDock) lets a page add its own content to the bar.
 */
export function FloatingNav({ keys, labels, groups, profile, text }: Props) {
  const pathname = usePathname();
  const barRef = useRef<HTMLElement>(null);
  const [open, setOpen] = useState(false);
  const current = keys.find((key) => isActive(pathname, key));
  const profileActive = pathname === profile.href || (profile.also ?? []).some((base) => pathname === base || pathname.startsWith(`${base}/`));

  // Slide in from below when the dashboard loads (after the logo intro, when there is one).
  useEffect(() => {
    const bar = barRef.current;
    const root = document.documentElement;
    if (!bar || root.dataset.reveal === undefined) return;

    const play = () =>
      gsap.fromTo(
        bar,
        { y: 160, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          duration: 0.9,
          ease: "power3.out",
          onComplete: () => {
            delete root.dataset.reveal;
            gsap.set(bar, { clearProps: "transform,opacity" });
          },
        },
      );

    if (root.dataset.intro !== undefined) {
      window.addEventListener(INTRO_DONE_EVENT, play, { once: true });
      return () => window.removeEventListener(INTRO_DONE_EVENT, play);
    }
    const tween = play();
    return () => {
      tween.kill();
    };
  }, []);


  const { rowRef, indicatorRef } = useSlidingIndicator('[data-nav-tab][aria-current="page"]', pathname);

  // Other floating things (a sheet beside the page) keep clear of the bar by reading its height.
  useEffect(() => {
    const bar = barRef.current;
    if (!bar) return;
    const root = document.documentElement;
    const publish = () => root.style.setProperty("--nav-height", `${bar.offsetHeight}px`);
    publish();
    const observer = new ResizeObserver(publish);
    observer.observe(bar);
    return () => {
      observer.disconnect();
      root.style.removeProperty("--nav-height");
    };
  }, []);

  // Escape and a click outside close the menu.
  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => event.key === "Escape" && setOpen(false);
    const onPointer = (event: PointerEvent) => {
      if (barRef.current && !barRef.current.contains(event.target as Node)) setOpen(false);
    };
    window.addEventListener("keydown", onKey);
    window.addEventListener("pointerdown", onPointer);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("pointerdown", onPointer);
    };
  }, [open]);

  // Tabs in the bar take their highlight from the sliding indicator; tabs in the menu panel tint themselves.
  const tab = (key: NavKey, onNavigate?: () => void, slides = false) => {
    const active = key === current;
    return (
      <Link
        key={key}
        href={HREFS[key]}
        data-nav-tab={slides ? "" : undefined}
        aria-current={active ? "page" : undefined}
        onClick={onNavigate}
        className={`${TAB} ${active ? (slides ? TAB_ACTIVE_TEXT : TAB_ON) : TAB_OFF}`}
      >
        <Icon icon={ICONS[key]} size={22} />
        {labels[key]}
      </Link>
    );
  };

  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-4 z-40 flex justify-center px-3 sm:px-4">
      <nav
        ref={barRef}
        aria-label={text.primary}
        className="nav-bar pointer-events-auto relative w-full max-w-md rounded-lg bg-glass shadow-float backdrop-blur-[18px] lg:w-[58rem] lg:max-w-[calc(100vw-2rem)]"
      >
        <Contour radius={28} inset={6} dash={[6, 6]} />

        {/* Space a page can fill with its own content. Empty most of the time. */}
        <div id={NAV_DOCK_ID} className="relative empty:hidden" />

        {/* The tabs on small screens, opening upward. Inert while closed so it cannot take focus. */}
        <div
          inert={!open}
          className={
            "relative grid transition-[grid-template-rows,opacity,visibility] duration-(--dur) ease-soft lg:hidden " +
            (open ? "visible grid-rows-[1fr] opacity-100" : "invisible grid-rows-[0fr] opacity-0")
          }
        >
          <div className="overflow-hidden">
            <div className="flex flex-col gap-4 p-5 pb-2">
              {groups.map((group) => (
                <div key={group.label}>
                  <p className="mb-1.5 px-1 text-xs font-semibold tracking-wide text-muted uppercase">{group.label}</p>
                  <div className="grid grid-cols-3 gap-1 sm:grid-cols-4">{group.keys.map((key) => tab(key, () => setOpen(false)))}</div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div ref={rowRef} className="relative flex items-center gap-2 p-2.5">
          <span ref={indicatorRef} data-testid="nav-indicator" aria-hidden className="pointer-events-none absolute top-0 left-0 rounded-sm bg-[color-mix(in_srgb,var(--fg)_9%,transparent)] opacity-0" />
          <Link
            href="/"
            aria-label={text.home}
            data-tip={text.home}
            className="flex h-14 shrink-0 items-center rounded-sm px-3 text-brand focus-visible:outline-3 focus-visible:outline-focus"
          >
            <BrandMark className="h-8 w-auto" />
          </Link>

          <div className="hidden items-center gap-1.5 lg:flex lg:flex-1 lg:justify-evenly">{keys.map((key) => tab(key, undefined, true))}</div>

          <div className="flex min-w-0 flex-1 items-center gap-2 lg:hidden">
            <p className="flex min-w-0 flex-1 items-center gap-2 px-1 text-sm font-semibold">
              {current ? (
                <>
                  <Icon icon={ICONS[current]} size={20} />
                  <span className="sr-only">{text.current} </span>
                  <span className="truncate">{labels[current]}</span>
                </>
              ) : null}
            </p>
            <button
              type="button"
              onClick={() => setOpen((value) => !value)}
              aria-expanded={open}
              className={`${TAB} cursor-pointer border-0 bg-transparent ${open ? TAB_ON : TAB_OFF}`}
            >
              <Icon icon={open ? Cancel01Icon : Menu03Icon} size={22} />
              {open ? text.closeMenu : text.menu}
            </button>
          </div>

          <Link
            href={profile.href}
            data-nav-tab=""
            aria-current={profileActive ? "page" : undefined}
            className={`${TAB} ${profileActive ? TAB_ACTIVE_TEXT : TAB_OFF}`}
          >
            <Avatar name={profile.name} url={profile.avatarUrl} size={24} />
            {text.profileTab}
          </Link>
        </div>
      </nav>
    </div>
  );
}
