"use client";

import { useEffect, useRef } from "react";
import { Cancel01Icon } from "@hugeicons/core-free-icons";
import { gsap } from "gsap";

import { Contour } from "./Contour";
import { Icon } from "./Icon";

type Props = {
  open: boolean;
  onClose: () => void;
  title: string;
  closeLabel: string;
  children: React.ReactNode;
};

const calm = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/** A panel that slides in from the right over a dimmed page. Built on <dialog>, so focus and Escape work. */
export function SideSheet({ open, onClose, title, closeLabel, children }: Props) {
  const ref = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    if (open && !dialog.open) {
      dialog.showModal();
      gsap.fromTo(dialog, { xPercent: 100 }, { xPercent: 0, duration: calm() ? 0 : 0.45, ease: "power3.out" });
    } else if (!open && dialog.open) {
      gsap.to(dialog, { xPercent: 100, duration: calm() ? 0 : 0.3, ease: "power2.in", onComplete: () => dialog.close() });
    }
  }, [open]);

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
        if (event.target === event.currentTarget) onClose();
      }}
      className="sheet fixed inset-y-0 right-0 left-auto m-0 h-dvh max-h-none w-[min(32rem,100vw)] max-w-none overflow-y-auto rounded-l-xl border-0 bg-surface p-0 text-fg shadow-float"
    >
      <Contour radius={36} inset={14} />
      <div className="relative flex flex-col gap-6 p-8 sm:p-10">
        <div className="flex items-start justify-between gap-4">
          <h2 className="text-2xl font-extrabold tracking-tight">{title}</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label={closeLabel}
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
