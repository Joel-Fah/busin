"use client";

import { useState } from "react";

import { joinDateTime, splitDateTime } from "@/lib/ui/calendar";

import { DatePicker, type DatePickerText } from "./DatePicker";
import { describedBy } from "./Picker";
import { TimePicker, type TimePickerText } from "./TimePicker";

type Props = {
  id: string;
  label: string;
  /** Name of the form field. It carries "YYYY-MM-DDTHH:mm", like a datetime-local input. */
  name?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  locale?: string;
  step?: number;
  hint?: string;
  error?: string;
  disabled?: boolean;
  /** The earliest day that can be picked (YYYY-MM-DD). The time of day is not limited here; the server checks it. */
  minDate?: string;
  text?: { date: DatePickerText; time: TimePickerText; dateLabel: string; timeLabel: string };
  className?: string;
};

/** A date picker and a time picker side by side, sending one combined value with the form. */
export function DateTimePicker({ id, label, name, defaultValue = "", onChange, locale, step, hint, error, disabled, minDate, text, className = "" }: Props) {
  const initial = splitDateTime(defaultValue);
  const [date, setDate] = useState(initial.date);
  const [time, setTime] = useState(initial.time);
  const combined = joinDateTime(date, time);

  return (
    <fieldset className={`m-0 flex flex-col gap-1.5 border-0 p-0 ${className}`} aria-describedby={describedBy(id, hint, error)}>
      <legend className="mb-1.5 p-0 text-sm font-semibold">{label}</legend>
      <div className="grid gap-3 sm:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <DatePicker
          id={`${id}-date`}
          label={text?.dateLabel ?? "Date"}
          hideLabel
          value={date}
          locale={locale}
          text={text?.date}
          min={minDate}
          disabled={disabled}
          error={error ? " " : undefined}
          onChange={(next) => {
            setDate(next);
            onChange?.(joinDateTime(next, time));
          }}
        />
        <TimePicker
          id={`${id}-time`}
          label={text?.timeLabel ?? "Time"}
          hideLabel
          value={time}
          step={step}
          text={text?.time}
          disabled={disabled}
          error={error ? " " : undefined}
          onChange={(next) => {
            setTime(next);
            onChange?.(joinDateTime(date, next));
          }}
        />
      </div>
      {name ? <input type="hidden" name={name} value={combined} /> : null}
      {error ? (
        <p id={`${id}-error`} role="alert" className="text-sm text-bad">
          {error}
        </p>
      ) : hint ? (
        <p id={`${id}-hint`} className="text-sm text-muted">
          {hint}
        </p>
      ) : null}
    </fieldset>
  );
}
