"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { ArrowLeft01Icon, ArrowRight01Icon, Calendar02Icon } from "@hugeicons/core-free-icons";

import { addDays, addMonths, inRange, monthGrid, parseIso, toIso, type Iso } from "@/lib/ui/calendar";
import type { Side } from "@/lib/ui/placement";

import { Icon } from "./Icon";
import { FieldFrame, PANEL, describedBy, triggerClass } from "./Picker";
import { useAnchoredPanel } from "./useAnchoredPanel";

export type DatePickerText = {
  previousMonth: string;
  nextMonth: string;
  previousYear: string;
  nextYear: string;
  chooseMonth: string;
  today: string;
  choose: string;
};

const EN: DatePickerText = {
  previousMonth: "Previous month",
  nextMonth: "Next month",
  previousYear: "Previous year",
  nextYear: "Next year",
  chooseMonth: "Choose month and year",
  today: "Today",
  choose: "Choose a date",
};

type Props = {
  id: string;
  label: string;
  hideLabel?: boolean;
  name?: string;
  value?: Iso;
  defaultValue?: Iso;
  onChange?: (value: Iso) => void;
  min?: Iso;
  max?: Iso;
  /** Language of month and day names, for example "en" or "fr". */
  locale?: string;
  /** 0 for Sunday, 1 for Monday. */
  weekStartsOn?: 0 | 1;
  placeholder?: string;
  hint?: string;
  error?: string;
  disabled?: boolean;
  placement?: Side | "auto";
  text?: DatePickerText;
  className?: string;
};

const todayLocal = (): Iso => {
  const now = new Date();
  return toIso(now.getFullYear(), now.getMonth() + 1, now.getDate());
};

/**
 * A date field with a calendar drawn in the design system. Arrow keys move by day and week, Page
 * Up and Down by month, Home and End to the start and end of the week, Enter picks, Escape closes.
 * Shift with Page Up or Page Down changes the year, and the title opens a grid of months with year arrows,
 * so far dates are a few clicks away. Days outside min and max cannot be picked. The calendar opens up or down, whichever has room.
 * The chosen date is sent with the form as YYYY-MM-DD through a hidden input.
 */
export function DatePicker({
  id,
  label,
  hideLabel,
  name,
  value,
  defaultValue = "",
  onChange,
  min,
  max,
  locale = "en",
  weekStartsOn = 1,
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
  const [focusDay, setFocusDay] = useState<Iso>(todayLocal());
  const [mode, setMode] = useState<"days" | "months">("days");
  const root = useRef<HTMLDivElement>(null);
  const { anchorRef, panelRef } = useAnchoredPanel<HTMLButtonElement>(open, placement);

  const current = value ?? inner;
  const view = parseIso(focusDay)!;
  const grid = useMemo(() => monthGrid(view.year, view.month, weekStartsOn), [view.year, view.month, weekStartsOn]);

  const format = useMemo(() => {
    const monthName = new Intl.DateTimeFormat(locale, { month: "long", timeZone: "UTC" });
    const day = new Intl.DateTimeFormat(locale, { dateStyle: "long", timeZone: "UTC" });
    const month = new Intl.DateTimeFormat(locale, { month: "long", year: "numeric", timeZone: "UTC" });
    const short = new Intl.DateTimeFormat(locale, { weekday: "short", timeZone: "UTC" });
    const at = (iso: Iso) => {
      const p = parseIso(iso)!;
      return new Date(Date.UTC(p.year, p.month - 1, p.day));
    };
    return {
      monthName: (year: number, month: number) => monthName.format(new Date(Date.UTC(year, month - 1, 1))),
      day: (iso: Iso) => day.format(at(iso)), month: (iso: Iso) => month.format(at(iso)), weekday: (iso: Iso) => short.format(at(iso)),
    };
  }, [locale]);

  function openCalendar() {
    const start = parseIso(current) ? current : todayLocal();
    setFocusDay(inRange(start, min, max) ? start : (min ?? max ?? start));
    setMode("days");
    setOpen(true);
  }

  function pick(iso: Iso) {
    if (!inRange(iso, min, max)) return;
    setInner(iso);
    onChange?.(iso);
    setOpen(false);
    anchorRef.current?.focus();
  }

  function go(iso: Iso) {
    if (inRange(iso, min, max)) setFocusDay(iso);
  }

  function onGridKeyDown(event: React.KeyboardEvent) {
    const steps: Record<string, () => Iso> = {
      ArrowLeft: () => addDays(focusDay, -1),
      ArrowRight: () => addDays(focusDay, 1),
      ArrowUp: () => addDays(focusDay, -7),
      ArrowDown: () => addDays(focusDay, 7),
      PageUp: () => addMonths(focusDay, event.shiftKey ? -12 : -1),
      PageDown: () => addMonths(focusDay, event.shiftKey ? 12 : 1),
      Home: () => addDays(focusDay, -((new Date(`${focusDay}T00:00:00Z`).getUTCDay() - weekStartsOn + 7) % 7)),
      End: () => addDays(focusDay, 6 - ((new Date(`${focusDay}T00:00:00Z`).getUTCDay() - weekStartsOn + 7) % 7)),
    };
    const step = steps[event.key];
    if (!step) return;
    event.preventDefault();
    go(step());
  }

  const monthAllowed = (month: number) => {
    const first = toIso(view.year, month, 1);
    const last = toIso(view.year, month + 1, 0);
    return inRange(first, min, max) || inRange(last, min, max) || (!!min && !!max && first <= min && last >= max);
  };

  function chooseMonth(month: number) {
    if (!monthAllowed(month)) return;
    const moved = addMonths(focusDay, month - view.month);
    setFocusDay(inRange(moved, min, max) ? moved : toIso(view.year, month, 1) < (min ?? "") ? (min as Iso) : (max ?? toIso(view.year, month, 1)));
    setMode("days");
  }

  function onMonthsKeyDown(event: React.KeyboardEvent) {
    const buttons = Array.from(panelRef.current?.querySelectorAll<HTMLElement>("[data-month]") ?? []);
    const at = buttons.indexOf(document.activeElement as HTMLElement);
    const moves: Record<string, number> = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -3, ArrowDown: 3 };
    if (event.key in moves) {
      event.preventDefault();
      buttons[Math.min(Math.max(at + moves[event.key], 0), buttons.length - 1)]?.focus();
    } else if (event.key === "PageUp" || event.key === "PageDown") {
      event.preventDefault();
      setFocusDay(addMonths(focusDay, event.key === "PageUp" ? -12 : 12));
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

  // Move keyboard focus to the day being looked at, once the calendar is drawn and whenever it changes.
  useEffect(() => {
    if (!open) return;
    const target = mode === "days" ? `[data-iso="${focusDay}"]` : `[data-month="${view.month}"]`;
    panelRef.current?.querySelector<HTMLElement>(target)?.focus({ preventScroll: true });
  }, [open, focusDay, mode, view.month, panelRef]);

  const today = todayLocal();

  return (
    <FieldFrame id={id} label={label} hideLabel={hideLabel} hint={hint} error={error} className={className}>
      <div ref={root} className="relative">
        <span className="pointer-events-none absolute inset-y-0 left-3.5 z-10 flex items-center text-muted">
          <Icon icon={Calendar02Icon} size={18} />
        </span>
        <button
          ref={anchorRef}
          id={id}
          type="button"
          disabled={disabled}
          aria-haspopup="dialog"
          aria-expanded={open}
          aria-describedby={describedBy(id, hint, error)}
          onClick={() => (open ? setOpen(false) : openCalendar())}
          className={triggerClass(Boolean(error))}
        >
          <span className={parseIso(current) ? "truncate" : "truncate text-muted"}>
            {parseIso(current) ? format.day(current) : placeholder || text.choose}
          </span>
        </button>
        {name ? <input type="hidden" name={name} value={current} /> : null}

        {open ? (
          <div ref={panelRef} popover="manual" role="dialog" aria-label={label} className={`${PANEL} w-[19.5rem] p-3`}>
            <div className="mb-2 flex items-center justify-between gap-2">
              <button
                type="button"
                aria-label={mode === "days" ? text.previousMonth : text.previousYear}
                onClick={() => go(addMonths(focusDay, mode === "days" ? -1 : -12))}
                className="inline-flex h-10 w-10 cursor-pointer items-center justify-center rounded-sm border-0 bg-transparent text-muted transition-colors duration-(--dur-fast) hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus"
              >
                <Icon icon={ArrowLeft01Icon} size={20} />
              </button>
              <button
                type="button"
                aria-label={text.chooseMonth}
                aria-expanded={mode === "months"}
                onClick={() => setMode(mode === "days" ? "months" : "days")}
                className="inline-flex h-10 cursor-pointer items-center rounded-sm border-0 bg-transparent px-3 font-sans text-sm font-bold text-fg capitalize transition-colors duration-(--dur-fast) hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus"
              >
                <span aria-live="polite">{mode === "days" ? format.month(focusDay) : view.year}</span>
              </button>
              <button
                type="button"
                aria-label={mode === "days" ? text.nextMonth : text.nextYear}
                onClick={() => go(addMonths(focusDay, mode === "days" ? 1 : 12))}
                className="inline-flex h-10 w-10 cursor-pointer items-center justify-center rounded-sm border-0 bg-transparent text-muted transition-colors duration-(--dur-fast) hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus"
              >
                <Icon icon={ArrowRight01Icon} size={20} />
              </button>
            </div>

            {mode === "months" ? (
              <div role="group" aria-label={text.chooseMonth} onKeyDown={onMonthsKeyDown} className="grid grid-cols-3 gap-1">
                {Array.from({ length: 12 }, (_, index) => index + 1).map((month) => {
                  const chosen = month === view.month;
                  return (
                    <button
                      key={month}
                      type="button"
                      data-month={month}
                      tabIndex={chosen ? 0 : -1}
                      disabled={!monthAllowed(month)}
                      aria-pressed={chosen}
                      aria-current={today.startsWith(`${view.year}-${String(month).padStart(2, "0")}`) ? "date" : undefined}
                      onClick={() => chooseMonth(month)}
                      className={
                        "inline-flex h-14 cursor-pointer items-center justify-center rounded-sm border-0 font-sans text-sm font-semibold capitalize " +
                        "transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus disabled:cursor-not-allowed disabled:opacity-30 " +
                        (chosen ? "bg-accent text-on-accent" : "bg-transparent text-fg hover:bg-surface-2")
                      }
                    >
                      {format.monthName(view.year, month)}
                    </button>
                  );
                })}
              </div>
            ) : (
              <>
                <div className="grid grid-cols-7 gap-0.5 text-center text-xs font-semibold text-muted" aria-hidden>
                  {grid.slice(0, 7).map((iso) => (
                    <span key={iso} className="py-1.5 capitalize">
                      {format.weekday(iso)}
                    </span>
                  ))}
                </div>

                <div role="grid" aria-label={format.month(focusDay)} onKeyDown={onGridKeyDown} className="grid grid-cols-7 gap-0.5">
                  {grid.map((iso) => {
                    const inMonth = parseIso(iso)!.month === view.month;
                    const isSelected = iso === current;
                    const allowed = inRange(iso, min, max);
                    return (
                      <button
                        key={iso}
                        type="button"
                        role="gridcell"
                        data-iso={iso}
                        tabIndex={iso === focusDay ? 0 : -1}
                        disabled={!allowed}
                        aria-label={format.day(iso)}
                        aria-selected={isSelected}
                        aria-current={iso === today ? "date" : undefined}
                        onClick={() => pick(iso)}
                        className={
                          "inline-flex h-10 cursor-pointer items-center justify-center rounded-sm border-0 text-sm font-semibold " +
                          "transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus disabled:cursor-not-allowed disabled:opacity-30 " +
                          (isSelected
                            ? "bg-accent text-on-accent"
                            : (inMonth ? "bg-transparent text-fg hover:bg-surface-2 " : "bg-transparent text-muted hover:bg-surface-2 ") +
                              (iso === today ? "shadow-[inset_0_0_0_1.5px_var(--accent)]" : ""))
                        }
                      >
                        {parseIso(iso)!.day}
                      </button>
                    );
                  })}
                </div>
              </>
            )}

            <div className="mt-2 flex justify-end">
              <button
                type="button"
                disabled={!inRange(today, min, max)}
                onClick={() => pick(today)}
                className="h-9 cursor-pointer rounded-sm border-0 bg-transparent px-3 font-sans text-sm font-semibold text-muted transition-colors duration-(--dur-fast) hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus disabled:cursor-not-allowed disabled:opacity-40"
              >
                {text.today}
              </button>
            </div>
          </div>
        ) : null}
      </div>
    </FieldFrame>
  );
}
