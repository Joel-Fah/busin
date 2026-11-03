import type { SelectHTMLAttributes } from "react";
import { ArrowDown01Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { Icon } from "./Icon";

type Props = Omit<SelectHTMLAttributes<HTMLSelectElement>, "id"> & {
  id: string;
  label: string;
  /** Every field carries an icon inside it. */
  icon: IconSvgElement;
  hint?: string;
  error?: string;
};

/**
 * A dropdown field. It is the browser's own select under a BusIn face, so the list works with the
 * keyboard, with screen readers and with the native pickers on phones and tablets.
 */
export function Select({ id, label, icon, hint, error, className = "", children, ...rest }: Props) {
  const describedBy = error ? `${id}-error` : hint ? `${id}-hint` : undefined;
  return (
    <div className={`flex flex-col gap-1.5 ${className}`}>
      <label htmlFor={id} className="text-sm font-semibold">
        {label}
      </label>
      <div className="relative">
        <span className="pointer-events-none absolute inset-y-0 left-3.5 flex items-center text-muted">
          <Icon icon={icon} size={18} />
        </span>
        <select
          id={id}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy}
          className={
            "h-12 w-full cursor-pointer appearance-none rounded-sm border bg-surface pr-11 pl-11 font-sans text-base text-fg " +
            "transition-[border-color,box-shadow] duration-(--dur-fast) focus:outline-none focus:ring-3 focus:ring-focus/30 " +
            (error ? "border-bad focus:border-bad" : "border-line focus:border-focus")
          }
          {...rest}
        >
          {children}
        </select>
        <span className="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-muted">
          <Icon icon={ArrowDown01Icon} size={18} />
        </span>
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
