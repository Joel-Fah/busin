"use client";

import { gsap } from "gsap";
import { useEffect, useRef, type ReactNode } from "react";

import { useScrollLock } from "@/components/ui/useScrollLock";

const calm = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

/**
 * A dialog of the student web app, on the browser's <dialog> (focus, Escape and the backdrop come with it). "bottom"
 * slides up from the bottom edge like a phone's sheet; "center" settles in the middle with a soft spring. Its content is
 * not clipped, so art can float above its top edge. Closing slides it away again.
 */
export function Sheet({
  open,
  onClose,
  label,
  placement = "center",
  fit = false,
  className = "",
  children,
}: {
  open: boolean;
  onClose: () => void;
  label: string;
  placement?: "center" | "bottom";
  /** Centered and as large as its content (a photo), within the screen, instead of a fixed width. */
  fit?: boolean;
  className?: string;
  children: ReactNode;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  useScrollLock(open);

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    const quick = calm();
    if (open && !dialog.open) {
      dialog.showModal();
      if (placement === "bottom") gsap.fromTo(dialog, { yPercent: 100 }, { yPercent: 0, duration: quick ? 0 : 0.5, ease: "power3.out" });
      else gsap.fromTo(dialog, { y: 28, opacity: 0, scale: 0.95 }, { y: 0, opacity: 1, scale: 1, duration: quick ? 0 : 0.5, ease: "back.out(1.5)" });
    } else if (!open && dialog.open) {
      const done = () => dialog.close();
      if (placement === "bottom") gsap.to(dialog, { yPercent: 100, duration: quick ? 0 : 0.3, ease: "power2.in", onComplete: done });
      else gsap.to(dialog, { y: 14, opacity: 0, scale: 0.97, duration: quick ? 0 : 0.22, ease: "power2.in", onComplete: done });
    }
  }, [open, placement]);

  const frame =
    placement === "bottom"
      ? "mt-auto mb-0 w-full max-w-[640px] rounded-t-xl rounded-b-none pb-[max(1.5rem,env(safe-area-inset-bottom))]"
      : fit
        ? "m-auto w-fit max-w-[calc(100vw-2rem)] rounded-xl"
        : "m-auto w-[min(28rem,calc(100vw-2rem))] rounded-xl";

  return (
    <dialog
      ref={ref}
      aria-label={label}
      onCancel={(event) => {
        event.preventDefault();
        onClose();
      }}
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
      className={`sheet max-w-none overflow-visible border-0 bg-surface p-0 text-fg shadow-float ${frame} ${className}`}
    >
      {children}
    </dialog>
  );
}
