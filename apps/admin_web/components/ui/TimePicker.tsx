"use client";

import { useEffect, useRef, useState } from "react";
import { Clock01Icon } from "@hugeicons/core-free-icons";

import { formatTime, minuteOptions, parseTime } from "@/lib/ui/calendar";
import type { Side } from "@/lib/ui/placement";

import { Icon } from "./Icon";
import { FieldFrame, PANEL, describedBy, triggerClass } from "./Picker";
import { useAnchoredPanel } from "./useAnchoredPanel";

export type TimePickerText = { choose: string; hours: string; minutes: string; done: string };

const EN: TimePickerText = { choose: "Choose a time", hours: "Hours", minutes: "Minutes", done: "Done" };

type Props = {
  id: string;
  label: string;
  hideLabel?: boolean;
  name?: string;
  /** "HH:mm". */
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  /** Minutes between the choices: 1, 5, 10, 15 or 30. */
  step?: number;
  placeholder?: string;
  hint?: string;
  error?: string;
  disabled?: boolean;
  placement?: Side | "auto";
  text?: TimePickerText;
  className?: string;
};

const HOURS = Array.from({ length: 24 }, (_, index) => index);

function TimeOption({ selected, onPick, children }: { selected: boolean; onPick: () => void; children: string }) {
  return (
    <button
      type="button"
      role="option"
      aria-selected={selected}
      tabIndex={selected ? 0 : -1}
      onClick={onPick}
      className={
        "inline-flex h-10 w-full shrink-0 cursor-pointer items-center justify-center rounded-sm border-0 font-sans text-sm font-semibold tabular-nums " +
        "transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus " +
        (selected ? "bg-accent text-on-accent" : "bg-transparent text-fg hover:bg-surface-2")
      }
    >
      {children}
    </button>
  );
}

/**
 * A time field with two scrolling columns, hours and minutes, drawn in the design system.
 * Choosing an hour sets the time straight away (minutes keep their value or start at 00), so there
 * is never a half-finished value. Arrow keys move within a column and between columns, Enter picks,
 * Escape closes. The value is sent with the form as HH:mm through a hidden input.
 */
export function TimePicker({
  id,
  label,
  hideLabel,
  name,
  value,
  defaultValue = "",
  onChange,
  step = 5,
  placeholder = "",
  hint,
  error,
  disabled,
  placement = "auto",
  text = EN,
  className = "",
}: Props) {
  const [open, setOpen] = useState(false);
  const [inner, setInner] = useState(defaultValue);
  const root = useRef<HTMLDivElement>(null);
  const { anchorRef, panelRef } = useAnchoredPanel<HTMLButtonElement>(open, placement);

  const current = value ?? inner;
  const parts = parseTime(current);
  const minutes = minuteOptions(step);

  function set(hour: number, minute: number, close = false) {
    const next = formatTime(hour, minute);
    setInner(next);
    onChange?.(next);
    if (close) {
      setOpen(false);
      anchorRef.current?.focus();
    }
  }

  useEffect(() => {
    if (!open) return;
    const onPointer = (event: PointerEvent) => {
      if (root.current && !root.current.contains(event.target as Node)) setOpen(false);
    };
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setOpen(false);
        anchorRef.current?.focus();
      }
    };
    window.addEventListener("pointerdown", onPointer);
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("pointerdown", onPointer);
      window.removeEventListener("keydown", onKey);
    };
  }, [open, anchorRef]);

  // On opening, scroll each column so the chosen value is in view, and focus it.
  useEffect(() => {
    const panel = panelRef.current;
    if (!open || !panel) return;
    for (const column of Array.from(panel.querySelectorAll<HTMLElement>("[data-column]"))) {
      const chosen = column.querySelector<HTMLElement>('[aria-selected="true"]');
      if (chosen) column.scrollTop = chosen.offsetTop - column.clientHeight / 2 + chosen.offsetHeight / 2;
    }
    (panel.querySelector<HTMLElement>('[data-column="hours"] [tabindex="0"]'))?.focus({ preventScroll: true });
  }, [open, panelRef]);

  function onColumnKeyDown(event: React.KeyboardEvent<HTMLElement>) {
    const target = event.target as HTMLElement;
    const column = event.currentTarget;
    const items = Array.from(column.querySelectorAll<HTMLElement>('[role="option"]'));
    const at = items.indexOf(target);
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      const next = items[Math.min(Math.max(at + (event.key === "ArrowDown" ? 1 : -1), 0), items.length - 1)];
      next?.focus();
    } else if (event.key === "ArrowRight" || event.key === "ArrowLeft") {
      event.preventDefault();
      const other = panelRef.current?.querySelector<HTMLElement>(`[data-column="${column.dataset.column === "hours" ? "minutes" : "hours"}"] [tabindex="0"]`);
      other?.focus();
    }
  }

  const firstHour = parts?.hour ?? 0;
  const firstMinute = parts?.minute !== undefined && minutes.includes(parts.minute) ? parts.minute : minutes[0];

  return (
    <FieldFrame id={id} label={label} hideLabel={hideLabel} hint={hint} error={error} className={className}>
      <div ref={root} className="relative">
        <span className="pointer-events-none absolute inset-y-0 left-3.5 z-10 flex items-center text-muted">
          <Icon icon={Clock01Icon} size={18} />
        </span>
        <button
          ref={anchorRef}
          id={id}
          type="button"
          disabled={disabled}
          aria-haspopup="dialog"
          aria-expanded={open}
          aria-describedby={describedBy(id, hint, error)}
          onClick={() => setOpen((value) => !value)}
          className={triggerClass(Boolean(error))}
        >
          <span className={parts ? "truncate tabular-nums" : "truncate text-muted"}>{parts ? current : placeholder || text.choose}</span>
        </button>
        {name ? <input type="hidden" name={name} value={current} /> : null}

        {open ? (
          <div ref={panelRef} popover="manual" role="dialog" aria-label={label} className={`${PANEL} w-60 p-3`}>
            <div className="grid grid-cols-2 gap-2">
              <div role="listbox" aria-label={text.hours} data-column="hours" onKeyDown={onColumnKeyDown} className="flex max-h-56 flex-col gap-0.5 overflow-y-auto pr-1">
                {HOURS.map((hour) => (
                  <TimeOption key={hour} selected={parts?.hour === hour || (!parts && hour === firstHour)} onPick={() => set(hour, firstMinute)}>
                    {String(hour).padStart(2, "0")}
                  </TimeOption>
                ))}
              </div>
              <div role="listbox" aria-label={text.minutes} data-column="minutes" onKeyDown={onColumnKeyDown} className="flex max-h-56 flex-col gap-0.5 overflow-y-auto pr-1">
                {minutes.map((minute) => (
                  <TimeOption key={minute} selected={parts?.minute === minute || (!parts && minute === firstMinute)} onPick={() => set(firstHour, minute, true)}>
                    {String(minute).padStart(2, "0")}
                  </TimeOption>
                ))}
              </div>
            </div>
            <div className="mt-2 flex justify-end">
              <button
                type="button"
                onClick={() => {
                  if (!parts) set(firstHour, firstMinute);
                  setOpen(false);
                  anchorRef.current?.focus();
                }}
                className="h-9 cursor-pointer rounded-sm border-0 bg-transparent px-3 font-sans text-sm font-semibold text-muted transition-colors duration-(--dur-fast) hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus"
              >
                {text.done}
              </button>
            </div>
          </div>
        ) : null}
      </div>
    </FieldFrame>
  );
}
