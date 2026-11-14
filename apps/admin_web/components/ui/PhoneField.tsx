"use client";

import { ArrowDown01Icon, Search01Icon, Tick02Icon } from "@hugeicons/core-free-icons";
import { AsYouType, parsePhoneNumberFromString, type CountryCode } from "libphonenumber-js/min";
import { useEffect, useId, useMemo, useRef, useState } from "react";

import { COUNTRIES, type Country } from "@/lib/phone/countries";

import { Icon } from "./Icon";
import { FieldFrame, PANEL, describedBy } from "./Picker";
import { useAnchoredPanel } from "./useAnchoredPanel";

const COPY = {
  en: { country: "Country", search: "Search a country", none: "No country matches." },
  fr: { country: "Pays", search: "Rechercher un pays", none: "Aucun pays ne correspond." },
} as const;

function plain(text: string): string {
  return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}

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

function Flag({ code }: { code: string }) {
  // A small SVG served by the portal (country-flag-icons, MIT): flags are never emoji here.
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={`/flags/${code}.svg`} alt="" width={24} height={16} className="h-4 w-6 shrink-0 rounded-xs object-cover shadow-[0_0_0_1px_var(--color-line)]" />;
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
  const copy = COPY[locale];
  const initial = useMemo(() => split(defaultValue, defaultCountry), [defaultValue, defaultCountry]);
  const [country, setCountry] = useState(initial.country);
  const [text, setText] = useState(initial.text);
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [active, setActive] = useState(0);
  const root = useRef<HTMLDivElement>(null);
  const search = useRef<HTMLInputElement>(null);
  const input = useRef<HTMLInputElement>(null);
  const listId = useId();
  const { anchorRef, panelRef } = useAnchoredPanel<HTMLButtonElement>(open, "auto", false);

  const current = COUNTRIES.find((c) => c.code === country);
  const shown = useMemo(() => {
    const q = plain(query.trim()).replace(/^\+/, "");
    if (!q) return COUNTRIES;
    return COUNTRIES.filter((c) => plain(c.en).includes(q) || plain(c.fr).includes(q) || c.code.toLowerCase() === q || c.dial.startsWith(q));
  }, [query]);

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
    setQuery("");
    input.current?.focus();
  };

  useEffect(() => {
    if (!open) return;
    search.current?.focus();
    const onPointer = (event: PointerEvent) => {
      if (root.current && !root.current.contains(event.target as Node)) setOpen(false);
    };
    window.addEventListener("pointerdown", onPointer);
    return () => window.removeEventListener("pointerdown", onPointer);
  }, [open]);

  useEffect(() => {
    if (open) panelRef.current?.querySelector(`[data-index="${active}"]`)?.scrollIntoView({ block: "nearest" });
  }, [open, active, panelRef]);

  const onSearchKey = (event: React.KeyboardEvent) => {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      setActive((a) => Math.min(Math.max(a + (event.key === "ArrowDown" ? 1 : -1), 0), shown.length - 1));
    } else if (event.key === "Enter") {
      event.preventDefault();
      if (shown[active]) choose(shown[active]);
    } else if (event.key === "Escape") {
      event.preventDefault();
      setOpen(false);
      anchorRef.current?.focus();
    }
  };

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
          onClick={() => {
            // Opening starts on the chosen country.
            if (!open) setActive(Math.max(0, COUNTRIES.findIndex((c) => c.code === country)));
            setQuery("");
            setOpen(!open);
          }}
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
            <div className="relative">
              <span className="pointer-events-none absolute inset-y-0 left-3 flex items-center text-muted">
                <Icon icon={Search01Icon} size={16} />
              </span>
              <input
                ref={search}
                type="search"
                aria-label={copy.search}
                aria-controls={listId}
                placeholder={copy.search}
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
              <p className="m-0 px-2 py-3 text-sm text-muted">{copy.none}</p>
            ) : (
              <div id={listId} role="listbox" aria-label={copy.country} className="flex max-h-64 flex-col gap-0.5 overflow-y-auto">
                {shown.map((c, index) => (
                  <div
                    key={c.code}
                    role="option"
                    aria-selected={c.code === country}
                    data-index={index}
                    onMouseDown={(event) => event.preventDefault()}
                    onClick={() => choose(c)}
                    onMouseMove={() => active !== index && setActive(index)}
                    className={`flex cursor-pointer items-center gap-3 rounded-sm px-3 py-2 text-sm ${index === active ? "bg-surface-2" : ""}`}
                  >
                    <Flag code={c.code} />
                    <span className="min-w-0 flex-1 truncate font-semibold">{locale === "fr" ? c.fr : c.en}</span>
                    <span className="text-muted tabular-nums">+{c.dial}</span>
                    {c.code === country ? <Icon icon={Tick02Icon} size={16} /> : null}
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
