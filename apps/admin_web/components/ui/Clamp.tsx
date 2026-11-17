"use client";

import { useEffect, useId, useRef, useState, type FocusEvent, type ReactNode } from "react";
import { ArrowDown01Icon } from "@hugeicons/core-free-icons";

import { Icon } from "./Icon";

type Props = {
  children: ReactNode;
  moreLabel: string;
  lessLabel: string;
  className?: string;
};

/**
 * Keeps long content to about eight lines, faded at the bottom, with a "Show more" button that opens it in place.
 * Short content is shown as it is, with no button. Keyboard focus moving into the hidden part opens it, so nothing
 * focusable is ever out of sight. Without scripts the content is shown in full.
 */
export function Clamp({ children, moreLabel, lessLabel, className = "" }: Props) {
  const id = useId();
  const ref = useRef<HTMLDivElement>(null);
  const [overflows, setOverflows] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    // A few pixels over is not worth a button.
    const measure = () => setOverflows(el.scrollHeight > el.clientHeight + 8);
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  const clamped = !open;
  const onFocus = (event: FocusEvent<HTMLDivElement>) => {
    if (clamped && overflows && event.target instanceof HTMLElement && event.target.matches(":focus-visible")) setOpen(true);
  };

  return (
    <div className={className}>
      <div
        id={id}
        ref={ref}
        onFocus={onFocus}
        className={
          clamped
            ? `max-h-48 overflow-hidden [@media(scripting:none)]:max-h-none ${overflows ? "[mask-image:linear-gradient(to_bottom,var(--fg)_60%,transparent)]" : ""}`
            : ""
        }
      >
        {children}
      </div>
      {overflows || open ? (
        <button
          type="button"
          aria-expanded={open}
          aria-controls={id}
          onClick={() => setOpen((v) => !v)}
          className={
            "mt-2 inline-flex cursor-pointer items-center gap-1 border-0 bg-transparent p-0 font-sans text-sm font-semibold text-link " +
            "transition-colors duration-(--dur-fast) hover:text-fg focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus"
          }
        >
          {open ? lessLabel : moreLabel}
          <Icon icon={ArrowDown01Icon} size={16} className={`transition-transform duration-(--dur-fast) motion-reduce:transition-none ${open ? "rotate-180" : ""}`} />
        </button>
      ) : null}
    </div>
  );
}
