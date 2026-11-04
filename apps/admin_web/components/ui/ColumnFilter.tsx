"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useId, useRef, useState } from "react";
import { FilterHorizontalIcon, Search01Icon, Tick02Icon } from "@hugeicons/core-free-icons";

import { fillHref } from "@/lib/filters";

import { DatePicker, type DatePickerText } from "./DatePicker";
import { Icon } from "./Icon";
import { PANEL } from "./Picker";
import { useAnchoredPanel } from "./useAnchoredPanel";

export type FilterOption = { value: string; label: string; href: string };

type Common = {
  /** The column's name, shown as its heading. */
  label: string;
  /** The address of the list with this filter removed. */
  clearHref: string;
  /** The first choice, which removes the filter: "All stops". */
  allLabel: string;
  /** The current value, or null when the column is not filtered. */
  value: string | null;
  searchLabel: string;
  noMatchLabel: string;
  /** Read by screen readers after the heading while the column is filtered. */
  activeLabel: string;
};

type Props =
  | (Common & { kind?: "list"; options: FilterOption[] })
  | (Common & {
      kind: "date";
      /** The list's address with VALUE_TOKEN where the picked day goes. */
      hrefTemplate: string;
      /** Name of the calendar field inside the panel, for example "Day". */
      pickerLabel: string;
      locale: string;
      pickerText: DatePickerText;
      placeholder: string;
    });

/** Lists longer than this get a search box. */
const SEARCH_FROM = 8;

/**
 * A column heading that filters its column. A small button after the name opens a panel with the choices;
 * picking one goes to the list's address with that filter set (the filters live in the address, so a filtered
 * list can be shared and survives a reload). While the column is filtered, a dot marks the heading.
 * Choices are plain links; a date column opens a calendar instead.
 */
export function ColumnFilter(props: Props) {
  const { label, clearHref, allLabel, value, searchLabel, noMatchLabel, activeLabel } = props;
  const [open, setOpen] = useState(false);
  const [needle, setNeedle] = useState("");
  const root = useRef<HTMLSpanElement>(null);
  const router = useRouter();
  const id = useId();
  const { anchorRef, panelRef } = useAnchoredPanel<HTMLButtonElement>(open, "auto");
  const active = value !== null;

  useEffect(() => {
    if (!open) return;
    const onPointer = (event: PointerEvent) => {
      if (root.current && !root.current.contains(event.target as Node)) setOpen(false);
    };
    window.addEventListener("pointerdown", onPointer);
    return () => window.removeEventListener("pointerdown", onPointer);
  }, [open]);

  function close() {
    setOpen(false);
    setNeedle("");
  }

  const row =
    "flex w-full items-center justify-between gap-3 rounded-sm px-3 py-2 text-left text-sm font-semibold text-fg normal-case no-underline " +
    "transition-colors duration-(--dur-fast) hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus ";

  const options = props.kind === "date" ? [] : props.options;
  const shown = needle.trim() ? options.filter((option) => option.label.toLowerCase().includes(needle.trim().toLowerCase())) : options;

  return (
    <span
      ref={root}
      className="relative inline-flex"
      onKeyDown={(event) => {
        if (event.key === "Escape" && open) {
          close();
          anchorRef.current?.focus();
        }
      }}
    >
      <button
        ref={anchorRef}
        type="button"
        aria-haspopup="dialog"
        aria-expanded={open}
        aria-controls={open ? id : undefined}
        onClick={() => (open ? close() : setOpen(true))}
        className={
          "-mx-2 inline-flex cursor-pointer items-center gap-1.5 rounded-sm border-0 bg-transparent px-2 py-1 font-sans text-xs font-semibold tracking-wide uppercase " +
          "transition-colors duration-(--dur-fast) hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus " +
          (active || open ? "text-fg" : "text-muted")
        }
      >
        {label}
        <Icon icon={FilterHorizontalIcon} size={14} />
        {active ? <span aria-hidden className="size-2 rounded-full bg-accent" /> : null}
        {active ? <span className="sr-only">{activeLabel}</span> : null}
      </button>

      {open ? (
        <div ref={panelRef} id={id} popover="manual" role="dialog" aria-label={label} className={`${PANEL} flex w-64 flex-col gap-1 p-2 text-left`}>
          {/* A date column is "any day" until a day is picked, and the calendar below says so; the link is for removing it. */}
          {props.kind === "date" && !active ? null : (
            <Link href={clearHref} onClick={close} aria-current={active ? undefined : "true"} className={row}>
              {allLabel}
              {active ? null : <Icon icon={Tick02Icon} size={16} />}
            </Link>
          )}

          {props.kind === "date" ? (
            <DatePicker
              id={`${id}-day`}
              label={props.pickerLabel}
              hideLabel
              value={value ?? ""}
              locale={props.locale}
              text={props.pickerText}
              placeholder={props.placeholder}
              onChange={(iso) => {
                close();
                router.push(fillHref(props.hrefTemplate, iso));
              }}
            />
          ) : (
            <>
              {options.length > SEARCH_FROM ? (
                <label className="relative block">
                  <span className="sr-only">{searchLabel}</span>
                  <span className="pointer-events-none absolute top-1/2 left-3 -translate-y-1/2 text-muted">
                    <Icon icon={Search01Icon} size={16} />
                  </span>
                  <input
                    type="search"
                    value={needle}
                    onChange={(event) => setNeedle(event.target.value)}
                    placeholder={searchLabel}
                    className="h-10 w-full rounded-sm border border-line bg-surface pr-3 pl-9 font-sans text-sm text-fg placeholder:text-muted focus:border-focus focus:ring-3 focus:ring-focus/30 focus:outline-none"
                  />
                </label>
              ) : null}
              <ul className="m-0 flex max-h-64 list-none flex-col gap-0.5 overflow-y-auto p-0">
                {shown.map((option) => {
                  const current = option.value === value;
                  return (
                    <li key={option.value}>
                      <Link href={option.href} onClick={close} aria-current={current ? "true" : undefined} className={row + (current ? "bg-surface-2" : "")}>
                        <span className="truncate">{option.label}</span>
                        {current ? <Icon icon={Tick02Icon} size={16} /> : null}
                      </Link>
                    </li>
                  );
                })}
                {shown.length === 0 ? <li className="px-3 py-2 text-sm font-normal text-muted normal-case">{noMatchLabel}</li> : null}
              </ul>
            </>
          )}
        </div>
      ) : null}
    </span>
  );
}
