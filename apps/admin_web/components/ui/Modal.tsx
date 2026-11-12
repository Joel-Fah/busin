"use client";

import { useEffect, useRef } from "react";
import { gsap } from "gsap";

import { Contour } from "./Contour";
import { MarkedTitle } from "./MarkedTitle";
import { useScrollLock } from "./useScrollLock";

type Props = {
  open: boolean;
  onClose: () => void;
  title: string;
  /** Short explanation under the title. */
  description?: string;
  /** Buttons, usually a calm choice and one main action. */
  actions: React.ReactNode;
  children?: React.ReactNode;
};

const calm = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/** A floating dialog in the middle of the page, for a decision that needs an answer. Built on <dialog>. Needs <RoughFilter /> on the page for the marker under its title. */
export function Modal({ open, onClose, title, description, actions, children }: Props) {
  const ref = useRef<HTMLDialogElement>(null);
  useScrollLock(open);

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    if (open && !dialog.open) {
      dialog.showModal();
      gsap.fromTo(dialog, { y: 24, opacity: 0, scale: 0.96 }, { y: 0, opacity: 1, scale: 1, duration: calm() ? 0 : 0.4, ease: "back.out(1.4)" });
    } else if (!open && dialog.open) {
      gsap.to(dialog, { y: 12, opacity: 0, scale: 0.98, duration: calm() ? 0 : 0.22, ease: "power2.in", onComplete: () => dialog.close() });
    }
  }, [open]);

  return (
    <dialog
      ref={ref}
      aria-label={title}
      onCancel={(event) => {
        event.preventDefault();
        onClose();
      }}
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
      className="sheet m-auto w-[min(28rem,calc(100vw-2rem))] max-w-none rounded-xl border-0 bg-surface p-0 text-fg shadow-float"
    >
      <Contour radius={36} inset={14} />
      <div className="relative flex flex-col gap-4 p-8 sm:p-10">
        <MarkedTitle>{title}</MarkedTitle>
        {description ? <p className="text-base text-muted">{description}</p> : null}
        {children}
        <div className="mt-2 flex flex-wrap justify-end gap-3">{actions}</div>
      </div>
    </dialog>
  );
}
