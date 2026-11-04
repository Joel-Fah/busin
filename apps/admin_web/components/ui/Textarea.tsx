import type { TextareaHTMLAttributes } from "react";
import type { IconSvgElement } from "@hugeicons/react";

import { Icon } from "./Icon";

type Props = Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, "id"> & {
  id: string;
  label: string;
  /** Every field carries an icon inside it; here it sits at the top left, beside the first line. */
  icon: IconSvgElement;
  hint?: string;
  error?: string;
};

/** A multi-line field in the same face as Input. */
export function Textarea({ id, label, icon, hint, error, className = "", rows = 4, ...rest }: Props) {
  const describedBy = error ? `${id}-error` : hint ? `${id}-hint` : undefined;
  return (
    <div className={`flex flex-col gap-1.5 ${className}`}>
      <label htmlFor={id} className="text-sm font-semibold">
        {label}
      </label>
      <div className="relative">
        <span className="pointer-events-none absolute top-3.5 left-3.5 text-muted">
          <Icon icon={icon} size={18} />
        </span>
        <textarea
          id={id}
          rows={rows}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy}
          className={
            "w-full resize-y rounded-sm border bg-surface py-3 pr-4 pl-11 font-sans text-base text-fg " +
            "placeholder:text-muted transition-[border-color,box-shadow] duration-(--dur-fast) " +
            "focus:outline-none focus:ring-3 focus:ring-focus/30 " +
            (error ? "border-bad focus:border-bad" : "border-line focus:border-focus")
          }
          {...rest}
        />
      </div>
      {error ? (
        <p id={`${id}-error`} role="alert" className="text-sm text-bad">
          {error}
        </p>
      ) : hint ? (
        <p id={`${id}-hint`} className="text-sm text-muted">
          {hint}
        </p>
      ) : null}
    </div>
  );
}
