"use client";

import { ArrowDown01Icon, Search01Icon, Tick02Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";
import { useEffect, useId, useMemo, useRef, useState } from "react";

import { Icon } from "./Icon";
import { FieldFrame, PANEL, describedBy, triggerClass } from "./Picker";
import { useAnchoredPanel } from "./useAnchoredPanel";

export type SearchOption = { value: string; label: string; /** Shown muted at the end of the row, and searched. */ detail?: string };

function plain(text: string): string {
  return text.normalize("NFD").replace(/[̀-ͯ]/g, "").replaceAll("_", " ").toLowerCase();
}

/**
 * A dropdown for a long list (time zones, for example): the field opens a panel with a search box and the list, worked
 * with the arrow keys, Enter and Escape, and drawn like the other fields. It replaces the browser's own suggestions
 * (a datalist), which ignore the theme, cannot be searched in the middle of a name and differ on every phone. The
 * chosen value is sent with the form through a hidden input; nothing can be typed that is not in the list.
 */
export function SearchSelect({
  id,
  label,
  icon,
  name,
  options,
  defaultValue = "",
  placeholder = "",
  searchLabel,
  noneText,
  hint,
  error,
  required,
  className = "",
}: {
  id: string;
  label: string;
  icon: IconSvgElement;
  name: string;
  options: SearchOption[];
  defaultValue?: string;
  placeholder?: string;
  /** The search box's label and placeholder. */
  searchLabel: string;
  /** Shown when nothing matches the search. */
  noneText: string;
  hint?: string;
  error?: string;
  required?: boolean;
  className?: string;
}) {
  const [value, setValue] = useState(() => (options.some((o) => o.value === defaultValue) ? defaultValue : ""));
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [active, setActive] = useState(0);
  const root = useRef<HTMLDivElement>(null);
  const search = useRef<HTMLInputElement>(null);
  const list = useRef<HTMLDivElement>(null);
  const listId = useId();
  const { anchorRef, panelRef } = useAnchoredPanel<HTMLButtonElement>(open, "auto", true);

  const selected = options.find((o) => o.value === value);
  const shown = useMemo(() => {
    const q = plain(query.trim());
    if (!q) return options;
    return options.filter((o) => plain(o.label).includes(q) || plain(o.value).includes(q) || (o.detail ? plain(o.detail).startsWith(q) : false));
  }, [options, query]);

  function openList() {
    setQuery("");
    setActive(Math.max(0, options.findIndex((o) => o.value === value)));
    setOpen(true);
  }

  function close(refocus = true) {
    setOpen(false);
    if (refocus) anchorRef.current?.focus();
  }

  function choose(option: SearchOption | undefined) {
    if (!option) return;
    setValue(option.value);
    close();
  }

  useEffect(() => {
    if (open) search.current?.focus();
  }, [open]);

  // Keep the highlighted row in view inside the list (and only the list: the panel floats above the page).
  useEffect(() => {
    if (!open) return;
    const row = list.current?.querySelector<HTMLElement>(`[data-index="${active}"]`);
    const box = list.current;
    if (!row || !box) return;
    if (row.offsetTop < box.scrollTop) box.scrollTop = row.offsetTop;
    else if (row.offsetTop + row.offsetHeight > box.scrollTop + box.clientHeight) box.scrollTop = row.offsetTop + row.offsetHeight - box.clientHeight;
  }, [open, active, shown]);

  useEffect(() => {
    if (!open) return;
    const onPointer = (event: PointerEvent) => {
      if (root.current && !root.current.contains(event.target as Node)) setOpen(false);
    };
    window.addEventListener("pointerdown", onPointer);
    return () => window.removeEventListener("pointerdown", onPointer);
  }, [open]);

  const onTriggerKey = (event: React.KeyboardEvent) => {
    if (!open && (event.key === "ArrowDown" || event.key === "ArrowUp")) {
      event.preventDefault();
      openList();
    }
  };

  const onSearchKey = (event: React.KeyboardEvent) => {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      setActive((a) => Math.min(Math.max(a + (event.key === "ArrowDown" ? 1 : -1), 0), shown.length - 1));
    } else if (event.key === "Home" || event.key === "End") {
      if (!query) {
        event.preventDefault();
        setActive(event.key === "Home" ? 0 : shown.length - 1);
      }
    } else if (event.key === "Enter") {
      event.preventDefault();
      choose(shown[active]);
    } else if (event.key === "Escape") {
      event.preventDefault();
      close();
    } else if (event.key === "Tab") {
      close(false);
    }
  };

  return (
    <FieldFrame id={id} label={label} hint={hint} error={error} className={className}>
      <div ref={root} className="relative" data-testid={`${id}-field`}>
        <span className="pointer-events-none absolute inset-y-0 left-3.5 z-10 flex items-center text-muted">
          <Icon icon={icon} size={18} />
        </span>
        <button
          ref={anchorRef}
          id={id}
          type="button"
          role="combobox"
          aria-haspopup="listbox"
          aria-expanded={open}
          aria-controls={open ? listId : undefined}
          aria-required={required || undefined}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy(id, hint, error)}
          onClick={() => (open ? close() : openList())}
          onKeyDown={onTriggerKey}
          className={triggerClass(Boolean(error))}
        >
          <span className={selected ? "truncate" : "truncate text-muted"}>{selected?.label ?? placeholder}</span>
        </button>
        <span className="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-muted">
          <Icon icon={ArrowDown01Icon} size={18} />
        </span>
        <input type="hidden" name={name} value={value} />
        {open ? (
          <div ref={panelRef} popover="manual" className={`${PANEL} flex w-72 flex-col gap-2`}>
            <div className="relative">
              <span className="pointer-events-none absolute inset-y-0 left-3 flex items-center text-muted">
                <Icon icon={Search01Icon} size={16} />
              </span>
              <input
                ref={search}
                type="search"
                aria-label={searchLabel}
                aria-controls={listId}
                aria-activedescendant={shown[active] ? `${id}-option-${active}` : undefined}
                placeholder={searchLabel}
                autoComplete="off"
                value={query}
                onChange={(event) => {
                  setQuery(event.target.value);
                  setActive(0);
                }}
                onKeyDown={onSearchKey}
                className="h-10 w-full rounded-sm border border-line bg-surface pr-3 pl-9 font-sans text-sm text-fg focus:border-focus focus:outline-none"
              />
            </div>
            {shown.length === 0 ? (
              <p className="m-0 px-2 py-3 text-sm text-muted">{noneText}</p>
            ) : (
              <div ref={list} id={listId} role="listbox" aria-labelledby={`${id}-label`} className="relative flex max-h-64 flex-col gap-0.5 overflow-y-auto overscroll-contain">
                {shown.map((option, index) => (
                  <div
                    key={option.value}
                    id={`${id}-option-${index}`}
                    role="option"
                    aria-selected={option.value === value}
                    data-index={index}
                    onMouseDown={(event) => event.preventDefault()}
                    onClick={() => choose(option)}
                    onMouseMove={() => active !== index && setActive(index)}
                    className={`flex cursor-pointer items-center gap-3 rounded-sm px-3 py-2 text-sm ${index === active ? "bg-surface-2" : ""}`}
                  >
                    <span className="min-w-0 flex-1 truncate font-semibold">{option.label}</span>
                    {option.detail ? <span className="shrink-0 text-muted tabular-nums">{option.detail}</span> : null}
                    {option.value === value ? <Icon icon={Tick02Icon} size={16} /> : null}
                  </div>
                ))}
              </div>
            )}
          </div>
        ) : null}
      </div>
    </FieldFrame>
  );
}
