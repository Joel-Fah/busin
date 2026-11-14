"use client";

import { ArrowDown01Icon } from "@hugeicons/core-free-icons";
import { AsYouType, parsePhoneNumberFromString, type CountryCode } from "libphonenumber-js/min";
import { useEffect, useMemo, useRef, useState } from "react";

import { COUNTRIES, type Country } from "@/lib/phone/countries";

import { COUNTRY_COPY, CountryOptions, Flag } from "./CountryList";
import { Icon } from "./Icon";
import { FieldFrame, PANEL, describedBy } from "./Picker";
import { useAnchoredPanel } from "./useAnchoredPanel";

/**
 * The digits written the country's way while they are typed (`6 12 34 56 78` for France). Typed with the national 0
 * (`06...`), they are written as the country writes them at home; without it, as after the dialling code.
 */
function formatNational(digits: string, country: string): string {
  if (!digits) return "";
  if (digits.startsWith("0")) return new AsYouType(country as CountryCode).input(digits);
  const dial = COUNTRIES.find((c) => c.code === country)?.dial;
  if (!dial) return digits;
  const international = new AsYouType().input(`+${dial}${digits}`);
  return international.startsWith(`+${dial}`) ? international.slice(dial.length + 1).trim() : digits;
}

/** A saved E.164 number split into its country and its national digits; anything else is kept as typed. */
function split(value: string, fallback: string): { country: string; text: string } {
  const number = value.startsWith("+") ? parsePhoneNumberFromString(value) : undefined;
  if (number?.country) return { country: number.country, text: formatNational(number.nationalNumber, number.country) };
  return { country: fallback, text: value };
}

type Props = {
  id: string;
  label: string;
  /** The form field for the number; the country goes as `${name}Country`. The server reads them together (ADR 0024). */
  name?: string;
  /** A saved number (E.164), to start from. */
  defaultValue?: string;
  /** The country to start on when nothing is saved (see `defaultPhoneCountry`). */
  defaultCountry: string;
  locale: "en" | "fr";
  hint?: string;
  error?: string;
  required?: boolean;
  disabled?: boolean;
  className?: string;
};

/**
 * A phone number with its country, on one row (ADR 0024): a flag and the dialling code open a searchable list of
 * countries; the number is written the country's way as it is typed, and a number pasted with `+` picks its country.
 * The form gets the national number and the country; the stored form is E.164, worked out on the server.
 */
export function PhoneField({ id, label, name = "phone", defaultValue = "", defaultCountry, locale, hint, error, required, disabled, className = "" }: Props) {
  const copy = COUNTRY_COPY[locale];
  const initial = useMemo(() => split(defaultValue, defaultCountry), [defaultValue, defaultCountry]);
  const [country, setCountry] = useState(initial.country);
  const [text, setText] = useState(initial.text);
  const [open, setOpen] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  const input = useRef<HTMLInputElement>(null);
  const { anchorRef, panelRef } = useAnchoredPanel<HTMLButtonElement>(open, "auto", false);

  const current = COUNTRIES.find((c) => c.code === country);

  const type = (raw: string) => {
    if (raw.trim().startsWith("+")) {
      // A full number (pasted, or typed with its code): its own country, then the national part.
      const typing = new AsYouType();
      typing.input(raw);
      const number = typing.getNumber();
      const found = number?.country ?? typing.getCountry();
      const national = number?.nationalNumber;
      if (found && national) {
        setCountry(found);
        setText(formatNational(national, found));
        return;
      }
      setText(raw);
      return;
    }
    setText(formatNational(raw.replace(/[^0-9]/g, ""), country));
  };

  const choose = (c: Country) => {
    setCountry(c.code);
    setText((t) => formatNational(t.replace(/[^0-9]/g, ""), c.code));
    setOpen(false);
    input.current?.focus();
  };

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
      <div ref={root} className="flex gap-2" data-testid={`${id}-field`}>
        <button
          ref={anchorRef}
          type="button"
          disabled={disabled}
          aria-label={`${copy.country}: ${current ? (locale === "fr" ? current.fr : current.en) : country}`}
          aria-haspopup="listbox"
          aria-expanded={open}
          onClick={() => setOpen(!open)}
          className={
            "flex h-12 shrink-0 cursor-pointer items-center gap-2 rounded-sm border bg-surface px-3 font-sans text-base text-fg transition-[border-color,box-shadow] duration-(--dur-fast) " +
            "focus:outline-none focus:ring-3 focus:ring-focus/30 disabled:cursor-default disabled:opacity-60 " +
            (error ? "border-bad" : "border-line focus:border-focus")
          }
        >
          <Flag code={country} />
          <span className="tabular-nums">+{current?.dial ?? ""}</span>
          <Icon icon={ArrowDown01Icon} size={16} className="text-muted" />
        </button>
        <input
          ref={input}
          id={id}
          type="tel"
          inputMode="tel"
          autoComplete="tel-national"
          required={required}
          disabled={disabled}
          value={text}
          onChange={(event) => type(event.target.value)}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy(id, hint, error)}
          className={
            "h-12 min-w-0 flex-1 rounded-sm border bg-surface px-4 font-sans text-base text-fg tabular-nums placeholder:text-muted " +
            "transition-[border-color,box-shadow] duration-(--dur-fast) focus:outline-none focus:ring-3 focus:ring-focus/30 " +
            (error ? "border-bad focus:border-bad" : "border-line focus:border-focus")
          }
        />
        <input type="hidden" name={name} value={text} />
        <input type="hidden" name={`${name}Country`} value={country} />

        {open ? (
          <div ref={panelRef} popover="manual" className={`${PANEL} flex w-[min(20rem,calc(100vw-2rem))] flex-col gap-2`}>
            <CountryOptions
              locale={locale}
              selected={country}
              showDial
              onChoose={choose}
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
