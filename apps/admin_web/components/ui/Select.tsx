"use client";

import { useEffect, useId, useRef, useState } from "react";
import { ArrowDown01Icon, Tick02Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import type { Side } from "@/lib/ui/placement";

import { Icon } from "./Icon";
import { FieldFrame, PANEL, describedBy, triggerClass } from "./Picker";
import { useAnchoredPanel } from "./useAnchoredPanel";

export type SelectOption = { value: string; label: string; disabled?: boolean };

type Props = {
  id: string;
  label: string;
  /** Every field carries an icon inside it. */
  icon: IconSvgElement;
  options: SelectOption[];
  /** Name of the form field that carries the chosen value. */
  name?: string;
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  /** Shown while nothing is chosen. */
  placeholder?: string;
  hint?: string;
  error?: string;
  disabled?: boolean;
  /** Where the list opens. It always moves to the side with room. */
  placement?: Side | "auto";
  className?: string;
};

/**
 * A dropdown field drawn in the design system. It follows the select-only combobox pattern: focus
 * stays on the button, arrow keys move through the list, typing jumps to a match, Enter picks,
 * Escape closes. The list opens up or down, whichever has room. The chosen value is sent with the
 * form through a hidden input.
 */
export function Select({
  id,
  label,
  icon,
  options,
  name,
  value,
  defaultValue = "",
  onChange,
  placeholder = "",
  hint,
  error,
  disabled,
  placement = "auto",
  className = "",
}: Props) {
  const [open, setOpen] = useState(false);
  const [inner, setInner] = useState(defaultValue);
  const [active, setActive] = useState(0);
  const root = useRef<HTMLDivElement>(null);
  const typed = useRef({ text: "", timer: 0 });
  const listId = useId();
  const { anchorRef, panelRef } = useAnchoredPanel<HTMLButtonElement>(open, placement, true);

  const current = value ?? inner;
  const selected = options.find((option) => option.value === current);
  const enabled = options.map((option, index) => (option.disabled ? -1 : index)).filter((index) => index >= 0);

  function choose(index: number) {
    const option = options[index];
    if (!option || option.disabled) return;
    setInner(option.value);
    onChange?.(option.value);
    setOpen(false);
    anchorRef.current?.focus();
  }

  function openList() {
    const at = options.findIndex((option) => option.value === current && !option.disabled);
    setActive(at >= 0 ? at : (enabled[0] ?? 0));
    setOpen(true);
  }

  function move(step: number) {
    const position = enabled.indexOf(active);
    const next = enabled[(position + step + enabled.length) % enabled.length];
    if (next !== undefined) setActive(next);
  }

  function onKeyDown(event: React.KeyboardEvent) {
    const { key } = event;
    if (!open) {
      if (key === "ArrowDown" || key === "ArrowUp" || key === "Enter" || key === " ") {
        event.preventDefault();
        openList();
      }
      return;
    }
    if (key === "ArrowDown" || key === "ArrowUp") {
      event.preventDefault();
      move(key === "ArrowDown" ? 1 : -1);
    } else if (key === "Home" || key === "End") {
      event.preventDefault();
      setActive(key === "Home" ? enabled[0] : enabled[enabled.length - 1]);
    } else if (key === "Enter" || (key === " " && !typed.current.text)) {
      // A space picks, unless it is part of what is being typed ("going h").
      event.preventDefault();
      choose(active);
    } else if (key === "Escape") {
      event.preventDefault();
      setOpen(false);
    } else if (key === "Tab") {
      setOpen(false);
    } else if (key.length === 1 && !event.ctrlKey && !event.metaKey) {
      // Typing jumps to the next option that starts with what was typed.
      window.clearTimeout(typed.current.timer);
      typed.current.text += key.toLowerCase();
      typed.current.timer = window.setTimeout(() => (typed.current.text = ""), 1000);
      const hit = options.findIndex((option, index) => !option.disabled && index >= 0 && option.label.toLowerCase().startsWith(typed.current.text));
      if (hit >= 0) setActive(hit);
    }
  }

  useEffect(() => {
    if (!open) return;
    const onPointer = (event: PointerEvent) => {
      if (root.current && !root.current.contains(event.target as Node)) setOpen(false);
    };
    window.addEventListener("pointerdown", onPointer);
    return () => window.removeEventListener("pointerdown", onPointer);
  }, [open]);

  // Keep the highlighted option in view inside a long list.
  useEffect(() => {
    if (open) panelRef.current?.querySelector(`[data-index="${active}"]`)?.scrollIntoView({ block: "nearest" });
  }, [open, active, panelRef]);

  return (
    <FieldFrame id={id} label={label} hint={hint} error={error} className={className}>
      <div ref={root} className="relative">
        <span className="pointer-events-none absolute inset-y-0 left-3.5 z-10 flex items-center text-muted">
          <Icon icon={icon} size={18} />
        </span>
        <button
          ref={anchorRef}
          id={id}
          type="button"
          role="combobox"
          disabled={disabled}
          aria-haspopup="listbox"
          aria-expanded={open}
          aria-controls={open ? listId : undefined}
          aria-activedescendant={open ? `${id}-option-${active}` : undefined}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy(id, hint, error)}
          onClick={() => (open ? setOpen(false) : openList())}
          onKeyDown={onKeyDown}
          className={triggerClass(Boolean(error))}
        >
          <span className={selected ? "truncate" : "truncate text-muted"}>{selected?.label ?? placeholder}</span>
        </button>
        <span className="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-muted">
          <Icon icon={ArrowDown01Icon} size={18} />
        </span>
        {name ? <input type="hidden" name={name} value={current} /> : null}

        {open ? (
          <div ref={panelRef} popover="manual" className={`${PANEL} max-h-72 overflow-y-auto`}>
            <div id={listId} role="listbox" aria-labelledby={`${id}-label`} className="flex flex-col gap-0.5">
              {options.map((option, index) => {
                const isSelected = option.value === current;
                return (
                  <div
                    key={option.value}
                    id={`${id}-option-${index}`}
                    data-index={index}
                    role="option"
                    aria-selected={isSelected}
                    aria-disabled={option.disabled || undefined}
                    // Keep focus on the button while the pointer picks.
                    onMouseDown={(event) => event.preventDefault()}
                    onClick={() => choose(index)}
                    onMouseMove={() => !option.disabled && active !== index && setActive(index)}
                    className={
                      "flex items-center justify-between gap-3 rounded-sm px-3.5 py-2.5 text-sm font-semibold " +
                      (option.disabled ? "cursor-not-allowed opacity-40 " : "cursor-pointer ") +
                      (index === active && !option.disabled ? "bg-surface-2 " : "") +
                      (isSelected ? "text-fg" : "text-muted")
                    }
                  >
                    <span className="truncate">{option.label}</span>
                    {isSelected ? <Icon icon={Tick02Icon} size={16} /> : null}
                  </div>
                );
              })}
            </div>
          </div>
        ) : null}
      </div>
    </FieldFrame>
  );
}
