"use client";

import { Comment01Icon } from "@hugeicons/core-free-icons";
import { useState } from "react";

import { Textarea } from "@/components/ui/Textarea";
import { format } from "@/lib/i18n/messages";
import { REASON_MIN, tidyReason, withPreset } from "@/lib/reasons";

export type ReasonFieldText = {
  label: string;
  /** Under the field when there is nothing to correct, e.g. who will read it. */
  hint?: string;
  placeholder?: string;
  /** "Quick reasons". */
  presetsLabel: string;
  /** "{count} of {max} characters". */
  counter: string;
  /** "At least {min} characters." */
  minimum: string;
};

type Props = {
  id: string;
  name: string;
  text: ReasonFieldText;
  /** Ready-made reasons; a click fills the field, or adds to what is written. */
  presets: readonly string[];
  max: number;
  /** Whether the form refuses an empty field. An optional one still wants a real sentence once something is typed. */
  required?: boolean;
  defaultValue?: string;
  /** What is wrong with the text, in words, from the page or the server. */
  error?: string;
};

/**
 * A text field for a reason with clickable preset reasons and a live count. The presets are plain text to start from:
 * the administrator can edit them. The text is checked as it will be stored (trimmed, spaces collapsed), so what the
 * count shows is what counts.
 */
export function ReasonField({ id, name, text, presets, max, required = false, defaultValue = "", error }: Props) {
  const [value, setValue] = useState(defaultValue);
  const length = tidyReason(value).length;
  const set = (next: string) => setValue(next);
  const short = length > 0 && length < REASON_MIN;

  return (
    <div className="flex flex-col gap-3">
      <div role="group" aria-label={text.presetsLabel} className="flex flex-col gap-2">
        <span className="text-sm font-semibold">{text.presetsLabel}</span>
        <ul className="m-0 flex list-none flex-wrap gap-2 p-0">
          {presets.map((preset) => (
            <li key={preset}>
              <button
                type="button"
                onClick={() => set(withPreset(value, preset, max))}
                className="cursor-pointer rounded-xs border-0 bg-surface-2 px-3 py-1.5 text-left font-sans text-sm text-fg transition-colors duration-(--dur-fast) hover:bg-line focus-visible:outline-3 focus-visible:outline-focus"
              >
                {preset}
              </button>
            </li>
          ))}
        </ul>
      </div>
      <Textarea
        id={id}
        name={name}
        label={text.label}
        icon={Comment01Icon}
        required={required}
        value={value}
        onChange={(event) => set(event.target.value)}
        // Native check only once something is typed (an empty optional field is fine); the server does the real one.
        minLength={required ? REASON_MIN : undefined}
        maxLength={max}
        rows={3}
        placeholder={text.placeholder}
        hint={text.hint}
        error={error}
      />
      <p className={`m-0 text-xs ${short ? "text-warn" : "text-muted"}`} aria-live="polite">
        {format(text.counter, { count: length, max })}
        {short || (required && length === 0) ? ` ${format(text.minimum, { min: REASON_MIN })}` : null}
      </p>
    </div>
  );
}
