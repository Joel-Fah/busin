"use client";

import { Search01Icon, Tick02Icon } from "@hugeicons/core-free-icons";
import { useEffect, useId, useMemo, useRef, useState } from "react";

import { countryName } from "@/lib/phone/country";
import { COUNTRIES, type Country } from "@/lib/phone/countries";

export { countryName, findCountry } from "@/lib/phone/country";

import { Icon } from "./Icon";

export const COUNTRY_COPY = {
  en: { country: "Country", search: "Search a country", none: "No country matches." },
  fr: { country: "Pays", search: "Rechercher un pays", none: "Aucun pays ne correspond." },
} as const;

function plain(text: string): string {
  return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}

/** A country's flag: a small SVG served by the portal (country-flag-icons, MIT), never an emoji. */
export function Flag({ code }: { code: string }) {
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={`/flags/${code}.svg`} alt="" width={24} height={16} className="h-4 w-6 shrink-0 rounded-xs object-cover shadow-[0_0_0_1px_var(--color-line)]" />;
}

/**
 * The searchable list of countries, as it opens under a country field (the phone field's code, the school's country):
 * a search box (names in either language, two-letter codes, dialling codes) and the list, worked with the arrow keys,
 * Enter and Escape. `showDial` adds the dialling code to each row.
 */
export function CountryOptions({
  locale,
  selected,
  onChoose,
  onClose,
  showDial = false,
  listId: givenListId,
}: {
  locale: "en" | "fr";
  selected: string;
  onChoose: (country: Country) => void;
  onClose: () => void;
  showDial?: boolean;
  /** The list's id, when the field's button points at it (aria-controls). */
  listId?: string;
}) {
  const copy = COUNTRY_COPY[locale];
  const [query, setQuery] = useState("");
  const [active, setActive] = useState(() => Math.max(0, COUNTRIES.findIndex((c) => c.code === selected)));
  const search = useRef<HTMLInputElement>(null);
  const list = useRef<HTMLDivElement>(null);
  const ownListId = useId();
  const listId = givenListId ?? ownListId;

  const shown = useMemo(() => {
    const q = plain(query.trim()).replace(/^\+/, "");
    if (!q) return COUNTRIES;
    return COUNTRIES.filter((c) => plain(c.en).includes(q) || plain(c.fr).includes(q) || c.code.toLowerCase() === q || c.dial.startsWith(q));
  }, [query]);

  useEffect(() => search.current?.focus(), []);
  useEffect(() => {
    list.current?.querySelector(`[data-index="${active}"]`)?.scrollIntoView({ block: "nearest" });
  }, [active]);

  const onKey = (event: React.KeyboardEvent) => {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      setActive((a) => Math.min(Math.max(a + (event.key === "ArrowDown" ? 1 : -1), 0), shown.length - 1));
    } else if (event.key === "Enter") {
      event.preventDefault();
      if (shown[active]) onChoose(shown[active]);
    } else if (event.key === "Escape") {
      event.preventDefault();
      onClose();
    }
  };

  return (
    <>
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
          onKeyDown={onKey}
          className="h-10 w-full rounded-sm border border-line bg-surface pr-3 pl-9 font-sans text-sm text-fg focus:border-focus focus:outline-none"
        />
      </div>
      {shown.length === 0 ? (
        <p className="m-0 px-2 py-3 text-sm text-muted">{copy.none}</p>
      ) : (
        <div ref={list} id={listId} role="listbox" aria-label={copy.country} className="flex max-h-64 flex-col gap-0.5 overflow-y-auto">
          {shown.map((c, index) => (
            <div
              key={c.code}
              role="option"
              aria-selected={c.code === selected}
              data-index={index}
              onMouseDown={(event) => event.preventDefault()}
              onClick={() => onChoose(c)}
              onMouseMove={() => active !== index && setActive(index)}
              className={`flex cursor-pointer items-center gap-3 rounded-sm px-3 py-2 text-sm ${index === active ? "bg-surface-2" : ""}`}
            >
              <Flag code={c.code} />
              <span className="min-w-0 flex-1 truncate font-semibold">{countryName(c, locale)}</span>
              {showDial ? <span className="text-muted tabular-nums">+{c.dial}</span> : null}
              {c.code === selected ? <Icon icon={Tick02Icon} size={16} /> : null}
            </div>
          ))}
        </div>
      )}
    </>
  );
}
