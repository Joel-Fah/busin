"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Bus01Icon, QrCodeIcon, Ticket03Icon, UserIcon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { Icon } from "@/components/ui/Icon";
import { useSlidingIndicator } from "@/components/ui/useSlidingIndicator";
import type { StudentCopy } from "@/lib/i18n/student";

type Tab = { href: string; label: string; name?: string; icon: IconSvgElement };

/**
 * The student app's four tabs, as on the phone (Subscription, Code, My bus, Profile): a floating glass bar at the bottom,
 * the short label under each icon and the full name for screen readers. Pages opened from a tab (history, settings) keep
 * that tab lit.
 */
export function TabBar({ copy }: { copy: StudentCopy["nav"] }) {
  const pathname = usePathname();
  const tabs: Tab[] = [
    { href: "/app/subscription", label: copy.subscription, icon: Ticket03Icon },
    { href: "/app/code", label: copy.code, name: copy.codeFull, icon: QrCodeIcon },
    { href: "/app/bus", label: copy.bus, icon: Bus01Icon },
    { href: "/app/profile", label: copy.profile, icon: UserIcon },
  ];
  const active = tabs.find((tab) => pathname === tab.href || pathname.startsWith(`${tab.href}/`))?.href ?? (pathname.startsWith("/app/history") || pathname.startsWith("/app/settings") ? "/app/profile" : null);
  const { rowRef, indicatorRef } = useSlidingIndicator('[data-tab][aria-current="page"]', active);

  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-[max(0.75rem,env(safe-area-inset-bottom))] z-40 flex justify-center px-3">
      <nav aria-label={copy.label} className="pointer-events-auto relative w-full max-w-md rounded-lg bg-glass shadow-float backdrop-blur-[18px]">
        <div ref={rowRef} className="relative grid grid-cols-4 gap-1 p-2">
          <span ref={indicatorRef} aria-hidden className="pointer-events-none absolute top-0 left-0 rounded-sm bg-[color-mix(in_srgb,var(--fg)_9%,transparent)] opacity-0" />
          {tabs.map((tab) => {
            const on = tab.href === active;
            return (
              <Link
                key={tab.href}
                href={tab.href}
                data-tab
                aria-current={on ? "page" : undefined}
                aria-label={tab.name}
                className={
                  "relative flex flex-col items-center gap-1 rounded-sm px-2 py-2 text-xs font-semibold no-underline transition-colors duration-(--dur-fast) ease-soft focus-visible:outline-3 focus-visible:outline-focus " +
                  (on ? "text-fg" : "text-muted hover:text-fg")
                }
              >
                <Icon icon={tab.icon} size={22} />
                <span aria-hidden={tab.name ? true : undefined}>{tab.label}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
