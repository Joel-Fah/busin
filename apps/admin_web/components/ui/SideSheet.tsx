"use client";

import { useEffect, useRef } from "react";
import { Cancel01Icon } from "@hugeicons/core-free-icons";
import { gsap } from "gsap";

import { Contour } from "./Contour";
import { Icon } from "./Icon";
import { MarkedTitle } from "./MarkedTitle";
import { useScrollLock } from "./useScrollLock";

type Props = {
  open: boolean;
  onClose: () => void;
  title: string;
  closeLabel: string;
  /**
   * Modal (the default) dims the page and blocks it, for a sheet that needs your full attention. Pass
   * false for a sheet that works beside the page, such as one you fill in while clicking a map: the
   * page stays usable, nothing is dimmed or locked, and Escape and the close button still close it.
   */
  modal?: boolean;
  children: React.ReactNode;
};

const calm = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/**
 * A floating panel that glides in from the right. It is not docked to the screen edge: it keeps a
 * margin all round and has rounded corners on every side. Clean edges, because it holds reading
 * text; the only rough touch is the marker highlight under the title (needs <RoughFilter /> on the
 * page). Built on <dialog>, so focus handling and Escape come for free.
 */
export function SideSheet({ open, onClose, title, closeLabel, modal = true, children }: Props) {
  const ref = useRef<HTMLDialogElement>(null);
  useScrollLock(open && modal);

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    if (open && !dialog.open) {
      if (modal) dialog.showModal();
      else dialog.show();
      gsap.fromTo(dialog, { x: 80, opacity: 0, scale: 0.97 }, { x: 0, opacity: 1, scale: 1, duration: calm() ? 0 : 0.5, ease: "power3.out" });
    } else if (!open && dialog.open) {
      gsap.to(dialog, { x: 60, opacity: 0, scale: 0.98, duration: calm() ? 0 : 0.3, ease: "power2.in", onComplete: () => dialog.close() });
    }
  }, [open, modal]);

  // A modal dialog reports Escape itself; one that is not modal does not, so listen for it.
  useEffect(() => {
    if (!open || modal) return;
    const onKey = (event: KeyboardEvent) => event.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, modal, onClose]);

  return (
    <dialog
      ref={ref}
      aria-label={title}
      // Escape closes through our own state, so the slide-out still plays.
      onCancel={(event) => {
        event.preventDefault();
        onClose();
      }}
      // A click on the dimmed area lands on the dialog element itself, not on its content.
      onClick={(event) => {
        if (modal && event.target === event.currentTarget) onClose();
      }}
      className={
        "sheet fixed top-4 right-4 left-auto z-30 m-0 max-h-none w-[min(30rem,calc(100vw-2rem))] max-w-none overflow-y-auto rounded-xl border-0 bg-surface p-0 text-fg shadow-float " +
        // A sheet beside the page stops above the navigation bar, which can be tall when it holds a page's content.
        (modal ? "bottom-4 h-[calc(100dvh-2rem)]" : "bottom-[calc(var(--nav-height,0px)+2rem)] h-[calc(100dvh-var(--nav-height,0px)-3rem)]")
      }
    >
      <Contour radius={36} inset={14} />
      <div className="relative flex flex-col gap-6 p-8 sm:p-10">
        <div className="flex items-start justify-between gap-4">
          <MarkedTitle>{title}</MarkedTitle>
          <button
            type="button"
            onClick={onClose}
            aria-label={closeLabel}
            data-tip={closeLabel}
            className="inline-flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center rounded-sm border-0 bg-transparent text-muted transition-colors duration-(--dur-fast) hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus"
          >
            <Icon icon={Cancel01Icon} size={20} />
          </button>
        </div>
        {children}
      </div>
    </dialog>
  );
}
