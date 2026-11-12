"use client";

import { useEffect, useId, useLayoutEffect, useRef, useState } from "react";

import { placePanel, type Side } from "@/lib/ui/placement";

type Tip = { text: string; box: DOMRect; side: Side | "auto" };

const SHOW_AFTER_MS = 350;
const SHOW_AFTER_FOCUS_MS = 120;

/**
 * Tooltips in the design system, instead of the browser's own. Any element with a `data-tip` attribute
 * gets one on hover (after a short pause) and on keyboard focus; `data-tip-side` picks the side
 * (top by default, and it moves to the side with room). One layer serves the whole page, so it also works
 * for elements built outside React, such as map markers. It is a hint, not the only name: icon buttons
 * keep their `aria-label`. Escape, a click, or scrolling hides it. Mounted once, in the root layout.
 */
export function TooltipLayer() {
  const [tip, setTip] = useState<Tip | null>(null);
  const panel = useRef<HTMLDivElement>(null);
  const id = useId();

  useEffect(() => {
    let timer = 0;
    let current: HTMLElement | null = null;
    let previousDescription: string | null = null;

    const find = (target: EventTarget | null) => (target instanceof Element ? target.closest<HTMLElement>("[data-tip]") : null);

    const hide = () => {
      window.clearTimeout(timer);
      if (current) {
        if (previousDescription === null) current.removeAttribute("aria-describedby");
        else current.setAttribute("aria-describedby", previousDescription);
      }
      current = null;
      setTip(null);
    };

    const show = (el: HTMLElement, delay: number) => {
      window.clearTimeout(timer);
      timer = window.setTimeout(() => {
        const text = el.dataset.tip;
        if (!text) return;
        current = el;
        previousDescription = el.getAttribute("aria-describedby");
        if (previousDescription === null) el.setAttribute("aria-describedby", id);
        setTip({ text, box: el.getBoundingClientRect(), side: (el.dataset.tipSide as Side | undefined) ?? "top" });
      }, delay);
    };

    const onOver = (event: PointerEvent) => {
      const el = find(event.target);
      if (el && el !== current && event.pointerType !== "touch") show(el, SHOW_AFTER_MS);
    };
    const onOut = (event: PointerEvent) => {
      const el = find(event.target);
      if (el && !el.contains(event.relatedTarget as Node | null)) hide();
    };
    const onFocusIn = (event: FocusEvent) => {
      const el = find(event.target);
      if (el?.matches(":focus-visible")) show(el, SHOW_AFTER_FOCUS_MS);
    };
    const onKey = (event: KeyboardEvent) => event.key === "Escape" && hide();

    document.addEventListener("pointerover", onOver);
    document.addEventListener("pointerout", onOut);
    document.addEventListener("focusin", onFocusIn);
    document.addEventListener("focusout", hide);
    document.addEventListener("pointerdown", hide);
    document.addEventListener("keydown", onKey);
    window.addEventListener("scroll", hide, true);
    return () => {
      hide();
      document.removeEventListener("pointerover", onOver);
      document.removeEventListener("pointerout", onOut);
      document.removeEventListener("focusin", onFocusIn);
      document.removeEventListener("focusout", hide);
      document.removeEventListener("pointerdown", hide);
      document.removeEventListener("keydown", onKey);
      window.removeEventListener("scroll", hide, true);
    };
  }, [id]);

  // Place it in the browser's top layer, centred on the element, on the side that has room.
  useLayoutEffect(() => {
    const el = panel.current;
    if (!tip || !el) return;
    try {
      el.showPopover();
    } catch {
      // Already shown, or no popover support.
    }
    const size = el.getBoundingClientRect();
    const viewport = { width: window.innerWidth, height: window.innerHeight };
    const placed = placePanel({ anchor: tip.box, panel: { width: size.width, height: size.height }, viewport, preferred: tip.side, gap: 8 });
    const clamp = (value: number, extent: number, limit: number) => Math.max(8, Math.min(value, limit - extent - 8));
    const centreX = tip.box.left + tip.box.width / 2 - size.width / 2;
    const centreY = tip.box.top + tip.box.height / 2 - size.height / 2;
    const sideways = placed.side === "left" || placed.side === "right";
    el.style.left = `${sideways ? placed.left : clamp(centreX, size.width, viewport.width)}px`;
    el.style.top = `${sideways ? clamp(centreY, size.height, viewport.height) : placed.top}px`;
    return () => {
      try {
        el.hidePopover();
      } catch {
        // Already gone.
      }
    };
  }, [tip]);

  if (!tip) return null;
  return (
    <div
      ref={panel}
      id={id}
      role="tooltip"
      popover="manual"
      className="pointer-events-none m-0 inset-auto max-w-64 animate-[panel-in_var(--dur-fast)_var(--ease-soft)] overflow-visible rounded-xs border-0 bg-fg px-3 py-1.5 text-xs font-semibold text-bg shadow-float"
    >
      {tip.text}
    </div>
  );
}
