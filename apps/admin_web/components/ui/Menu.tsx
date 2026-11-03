"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { MoreHorizontalIcon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import type { Side } from "@/lib/ui/placement";

import { Icon } from "./Icon";
import { PANEL } from "./Picker";
import { useAnchoredPanel } from "./useAnchoredPanel";

export type MenuItem = {
  label: string;
  icon?: IconSvgElement;
  /** A destructive choice (delete, suspend): drawn in the danger colours. */
  danger?: boolean;
} & ({ href: string; onSelect?: never } | { onSelect: () => void; href?: never });

type Props = {
  /** Accessible name of the button that opens the menu. */
  label: string;
  items: MenuItem[];
  /**
   * Where the menu opens. "auto" is below, then above. "left" and "right" open beside the button.
   * Whatever is asked, the menu moves to the side with room if it would run off the screen.
   */
  placement?: Side | "auto";
};

/** A button that opens a short list of actions. Arrow keys move, Escape and a click outside close it. */
export function Menu({ label, items, placement = "auto" }: Props) {
  const [open, setOpen] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  const { anchorRef, panelRef } = useAnchoredPanel<HTMLButtonElement>(open, placement);

  useEffect(() => {
    if (!open) return;
    const onPointer = (event: PointerEvent) => {
      if (root.current && !root.current.contains(event.target as Node)) setOpen(false);
    };
    window.addEventListener("pointerdown", onPointer);
    return () => window.removeEventListener("pointerdown", onPointer);
  }, [open]);

  function onKeyDown(event: React.KeyboardEvent) {
    if (event.key === "Escape" && open) {
      setOpen(false);
      anchorRef.current?.focus();
      return;
    }
    if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return;
    const entries = Array.from(panelRef.current?.querySelectorAll<HTMLElement>('[role="menuitem"]') ?? []);
    if (!entries.length) return;
    event.preventDefault();
    const at = entries.indexOf(document.activeElement as HTMLElement);
    const next = event.key === "ArrowDown" ? (at + 1) % entries.length : (at - 1 + entries.length) % entries.length;
    entries[next].focus();
  }

  const row =
    "flex w-full cursor-pointer items-center gap-3 rounded-sm border-0 bg-transparent px-3.5 py-2.5 text-left font-sans text-sm font-semibold no-underline " +
    "transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus ";

  return (
    <div ref={root} className="relative inline-block" onKeyDown={onKeyDown}>
      <button
        ref={anchorRef}
        type="button"
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label={label}
        onClick={() => setOpen((value) => !value)}
        className="inline-flex h-11 w-11 cursor-pointer items-center justify-center rounded-sm border-0 bg-transparent text-muted transition-colors duration-(--dur-fast) hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus"
      >
        <Icon icon={MoreHorizontalIcon} size={22} />
      </button>
      {open ? (
        <div ref={panelRef} popover="manual" role="menu" aria-label={label} className={`${PANEL} flex min-w-52 flex-col gap-0.5`}>
          {items.map((item) => {
            const tone = item.danger ? "text-bad hover:bg-bad-bg" : "text-fg hover:bg-surface-2";
            const inner = (
              <>
                {item.icon ? <Icon icon={item.icon} size={18} /> : null}
                {item.label}
              </>
            );
            return item.href !== undefined ? (
              <Link key={item.label} href={item.href} role="menuitem" className={row + tone} onClick={() => setOpen(false)}>
                {inner}
              </Link>
            ) : (
              <button
                key={item.label}
                type="button"
                role="menuitem"
                className={row + tone}
                onClick={() => {
                  setOpen(false);
                  item.onSelect();
                }}
              >
                {inner}
              </button>
            );
          })}
        </div>
      ) : null}
    </div>
  );
}
