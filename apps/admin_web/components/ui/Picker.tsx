import type { ReactNode } from "react";

/** Shared pieces of the custom fields (dropdown, date and time pickers), so they look and read alike. */

export const PANEL =
  "m-0 inset-auto overflow-visible rounded-md border-0 bg-[color-mix(in_srgb,var(--surface)_96%,transparent)] p-1.5 text-fg shadow-float backdrop-blur-[18px] " +
  "[&:popover-open]:animate-[panel-in_var(--dur)_var(--ease-soft)]";

export function triggerClass(error: boolean): string {
  return (
    "flex h-12 w-full cursor-pointer items-center rounded-sm border bg-surface pr-11 pl-11 text-left font-sans text-base text-fg " +
    "transition-[border-color,box-shadow] duration-(--dur-fast) focus:outline-none focus-visible:ring-3 focus-visible:ring-focus/30 " +
    "aria-expanded:border-focus aria-expanded:ring-3 aria-expanded:ring-focus/30 disabled:cursor-not-allowed disabled:opacity-50 " +
    (error ? "border-bad" : "border-line focus-visible:border-focus")
  );
}

type FrameProps = {
  id: string;
  label: string;
  hideLabel?: boolean;
  hint?: string;
  error?: string;
  className?: string;
  children: ReactNode;
};

/** Label above, control in the middle, hint or error below. */
export function FieldFrame({ id, label, hideLabel, hint, error, className = "", children }: FrameProps) {
  return (
    <div className={`flex flex-col gap-1.5 ${className}`}>
      <label id={`${id}-label`} htmlFor={id} className={hideLabel ? "sr-only" : "text-sm font-semibold"}>
        {label}
      </label>
      {children}
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

export const describedBy = (id: string, hint?: string, error?: string) => (error ? `${id}-error` : hint ? `${id}-hint` : undefined);
