"use client";

import { AtIcon, Cancel01Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";
import { useRef, useState, type KeyboardEvent } from "react";

import { MAX_OPEN_DOMAINS, isValidDomain, normalizeDomain } from "@/lib/school";

import { Icon } from "./Icon";

type Props = {
  id: string;
  /** The form field the tags are sent in, joined by commas. */
  name: string;
  label: string;
  icon: IconSvgElement;
  hint?: string;
  placeholder?: string;
  defaultValue?: readonly string[];
  /** Tidies a typed value before it becomes a tag (for example lowercase, no leading @). */
  normalize?: (value: string) => string;
  /** Tags that fail this are shown in the error colour and named in `invalidHint`. */
  isValid?: (value: string) => boolean;
  invalidHint?: string;
  /** The label of each tag's remove button, for assistive technology ("Remove gmail.com"). */
  removeLabel: (tag: string) => string;
  max?: number;
};

const SEPARATOR = /[\s,;]+/;

/**
 * A field of tags, like GitHub's topics: typing a comma, a space or Enter turns the text into a tag; each tag has a
 * remove button, and clicking a tag puts it back in the field to edit it. Backspace in the empty field edits the last
 * tag. Pasting a list makes one tag per item. The tags are sent with the form in a hidden field, joined by commas.
 */
export function TagInput({ id, name, label, icon, hint, placeholder, defaultValue = [], normalize = (v) => v.trim(), isValid, invalidHint, removeLabel, max = 50 }: Props) {
  const [tags, setTags] = useState<string[]>(() => [...defaultValue]);
  const [draft, setDraft] = useState("");
  const input = useRef<HTMLInputElement>(null);
  const invalid = isValid ? tags.filter((tag) => !isValid(tag)) : [];

  const add = (raw: string) => {
    const values = raw
      .split(SEPARATOR)
      .map(normalize)
      .filter((value) => value !== "");
    if (values.length === 0) return;
    setTags((current) => {
      const next = [...current];
      for (const value of values) if (!next.includes(value) && next.length < max) next.push(value);
      return next;
    });
  };

  const commit = () => {
    add(draft);
    setDraft("");
  };

  const edit = (tag: string) => {
    if (draft.trim()) add(draft);
    setTags((current) => current.filter((t) => t !== tag));
    setDraft(tag);
    input.current?.focus();
  };

  const onKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === "Enter" || event.key === "," || event.key === " " || event.key === ";") {
      // Enter must not send the whole form while a tag is being typed.
      if (draft.trim() || event.key !== "Enter") event.preventDefault();
      commit();
    } else if (event.key === "Backspace" && draft === "" && tags.length > 0) {
      event.preventDefault();
      edit(tags[tags.length - 1]);
    }
  };

  const describedBy = invalid.length > 0 ? `${id}-error` : hint ? `${id}-hint` : undefined;

  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={id} className="text-sm font-semibold">
        {label}
      </label>
      <div
        className={
          "flex min-h-12 w-full cursor-text flex-wrap items-center gap-1.5 rounded-sm border bg-surface py-1.5 pr-2 pl-11 relative " +
          "transition-[border-color,box-shadow] duration-(--dur-fast) focus-within:ring-3 focus-within:ring-focus/30 " +
          (invalid.length > 0 ? "border-bad" : "border-line focus-within:border-focus")
        }
        onClick={() => input.current?.focus()}
      >
        <span className="pointer-events-none absolute top-0 left-3.5 flex h-12 items-center text-muted">
          <Icon icon={icon} size={18} />
        </span>
        <ul className="m-0 contents list-none p-0">
          {tags.map((tag) => {
            const bad = isValid ? !isValid(tag) : false;
            return (
              <li key={tag} data-tag={tag} className={`flex items-center rounded-xs text-sm font-semibold ${bad ? "bg-bad-bg text-bad" : "bg-surface-2 text-fg"}`}>
                <button type="button" onClick={(event) => (event.stopPropagation(), edit(tag))} className="cursor-text rounded-xs border-0 bg-transparent py-1 pr-1 pl-2.5 font-sans text-inherit focus-visible:outline-3 focus-visible:outline-focus">
                  {tag}
                </button>
                <button
                  type="button"
                  aria-label={removeLabel(tag)}
                  onClick={(event) => {
                    event.stopPropagation();
                    setTags((current) => current.filter((t) => t !== tag));
                  }}
                  className="grid size-7 cursor-pointer place-items-center rounded-xs border-0 bg-transparent text-inherit opacity-70 hover:opacity-100 focus-visible:outline-3 focus-visible:outline-focus"
                >
                  <Icon icon={Cancel01Icon} size={14} />
                </button>
              </li>
            );
          })}
        </ul>
        <input
          ref={input}
          id={id}
          value={draft}
          onChange={(event) => {
            const value = event.target.value;
            // A pasted list (or a separator typed on a phone keyboard that skips key events) becomes tags at once.
            if (SEPARATOR.test(value)) {
              add(value);
              setDraft("");
            } else setDraft(value);
          }}
          onKeyDown={onKeyDown}
          onBlur={commit}
          placeholder={tags.length === 0 ? placeholder : undefined}
          aria-describedby={describedBy}
          aria-invalid={invalid.length > 0 ? true : undefined}
          autoComplete="off"
          autoCapitalize="none"
          spellCheck={false}
          className="h-9 min-w-[8rem] flex-1 border-0 bg-transparent px-1 font-sans text-base text-fg placeholder:text-muted focus:outline-none"
        />
      </div>
      <input type="hidden" name={name} value={tags.join(",")} />
      {invalid.length > 0 && invalidHint ? (
        <p id={`${id}-error`} role="alert" className="text-sm text-bad">
          {invalidHint}
        </p>
      ) : hint ? (
        <p id={`${id}-hint`} className="text-sm text-muted">
          {hint}
        </p>
      ) : null}
    </div>
  );
}

type DomainsProps = Omit<Props, "icon" | "normalize" | "isValid" | "max" | "removeLabel"> & { removeLabel: string };

/** A TagInput for email domains: "@Gmail.com" becomes "gmail.com", and anything that is not a domain is marked. */
export function DomainsTagInput({ removeLabel, ...rest }: DomainsProps) {
  return <TagInput {...rest} icon={AtIcon} normalize={normalizeDomain} isValid={isValidDomain} max={MAX_OPEN_DOMAINS} removeLabel={(tag) => `${removeLabel} ${tag}`} />;
}
