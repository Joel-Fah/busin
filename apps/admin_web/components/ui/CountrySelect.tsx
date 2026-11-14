"use client";

import { ArrowDown01Icon } from "@hugeicons/core-free-icons";
import { useEffect, useId, useRef, useState } from "react";

import { COUNTRIES, type Country } from "@/lib/phone/countries";

import { CountryOptions, Flag, countryName, findCountry } from "./CountryList";
import { Icon } from "./Icon";
import { FieldFrame, PANEL, describedBy, triggerClass } from "./Picker";
import { useAnchoredPanel } from "./useAnchoredPanel";

/**
 * A country, picked from the known list with a search box (names in English and French, two-letter codes), each with
 * its flag. The form gets the country's English name under `name`, so a stored value reads the same whatever the
 * language of the admin who chose it; the list shows names in the page's language. Starts on `defaultValue` when it
 * names a country, else on `fallback` (Cameroon unless told otherwise).
 */
export function CountrySelect({
  id,
  label,
  name,
  defaultValue,
  fallback = "CM",
  locale,
  hint,
  error,
  className = "",
}: {
  id: string;
  label: string;
  name: string;
  defaultValue?: string | null;
  fallback?: string;
  locale: "en" | "fr";
  hint?: string;
  error?: string;
  className?: string;
}) {
  const [country, setCountry] = useState<Country | undefined>(() => findCountry(defaultValue) ?? COUNTRIES.find((c) => c.code === fallback));
  const [open, setOpen] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  const listId = useId();
  const { anchorRef, panelRef } = useAnchoredPanel<HTMLButtonElement>(open, "auto", true);

  useEffect(() => {
    if (!open) return;
    const onPointer = (event: PointerEvent) => {
      if (root.current && !root.current.contains(event.target as Node)) setOpen(false);
    };
    window.addEventListener("pointerdown", onPointer);
    return () => window.removeEventListener("pointerdown", onPointer);
  }, [open]);

  return (
    <FieldFrame id={id} label={label} hint={hint} error={error} className={className}>
      <div ref={root} className="relative" data-testid={`${id}-field`}>
        <button
          ref={anchorRef}
          id={id}
          type="button"
          role="combobox"
          aria-haspopup="listbox"
          aria-expanded={open}
          aria-controls={open ? listId : undefined}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy(id, hint, error)}
          onClick={() => setOpen((o) => !o)}
          className={`${triggerClass(Boolean(error))} pl-3.5!`}
        >
          <span className="flex min-w-0 items-center gap-3">
            {country ? <Flag code={country.code} /> : null}
            <span className="truncate">{country ? countryName(country, locale) : ""}</span>
          </span>
        </button>
        <span className="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-muted">
          <Icon icon={ArrowDown01Icon} size={18} />
        </span>
        <input type="hidden" name={name} value={country?.en ?? ""} />
        {open ? (
          <div ref={panelRef} popover="manual" className={`${PANEL} flex min-w-72 flex-col gap-2`}>
            <CountryOptions
              locale={locale}
              listId={listId}
              selected={country?.code ?? ""}
              onChoose={(c) => {
                setCountry(c);
                setOpen(false);
                anchorRef.current?.focus();
              }}
              onClose={() => {
                setOpen(false);
                anchorRef.current?.focus();
              }}
            />
          </div>
        ) : null}
      </div>
    </FieldFrame>
  );
}
