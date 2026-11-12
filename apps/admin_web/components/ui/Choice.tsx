import type { InputHTMLAttributes, ReactNode } from "react";
import { Tick02Icon } from "@hugeicons/core-free-icons";

import { Icon } from "./Icon";

type Base = Omit<InputHTMLAttributes<HTMLInputElement>, "type" | "children"> & {
  label: ReactNode;
  hint?: string;
};

const FOCUS = "peer-focus-visible:outline-3 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-focus";
const ROW = "group relative flex cursor-pointer items-start gap-3 has-[:disabled]:cursor-not-allowed has-[:disabled]:opacity-50";
// The real input lies invisibly over the visible face, so a click lands on the control itself.
const INPUT_OVER_FACE = "peer absolute top-0.5 left-0 m-0 cursor-pointer opacity-0 disabled:cursor-not-allowed";

function Text({ label, hint }: { label: ReactNode; hint?: string }) {
  return (
    <span className="flex flex-col pt-0.5">
      <span className="text-base font-semibold">{label}</span>
      {hint ? <span className="text-sm text-muted">{hint}</span> : null}
    </span>
  );
}

/** A tick box. The real checkbox lies invisibly over the face, so clicks, forms, labels and keyboards behave normally. */
export function Checkbox({ label, hint, className = "", ...rest }: Base) {
  return (
    <label className={`${ROW} ${className}`}>
      <input type="checkbox" className={`${INPUT_OVER_FACE} size-6`} {...rest} />
      <span
        aria-hidden
        className={
          "pointer-events-none mt-0.5 inline-flex size-6 shrink-0 items-center justify-center rounded-xs border-2 border-line bg-surface text-on-accent " +
          "transition-[background-color,border-color] duration-(--dur-fast) group-hover:border-muted " +
          "peer-checked:border-accent peer-checked:bg-accent [&>svg]:scale-50 [&>svg]:opacity-0 " +
          "peer-checked:[&>svg]:scale-100 peer-checked:[&>svg]:opacity-100 [&>svg]:transition-[opacity,transform] " +
          FOCUS
        }
      >
        <Icon icon={Tick02Icon} size={16} />
      </span>
      <Text label={label} hint={hint} />
    </label>
  );
}

/** One round choice among several. Use RadioGroup so the choices share a name and a legend. */
export function Radio({ label, hint, className = "", ...rest }: Base) {
  return (
    <label className={`${ROW} ${className}`}>
      <input type="radio" className={`${INPUT_OVER_FACE} size-6`} {...rest} />
      <span
        aria-hidden
        className={
          "pointer-events-none mt-0.5 inline-flex size-6 shrink-0 rounded-full border-2 border-line bg-surface " +
          "transition-[background,border-color] duration-(--dur) ease-soft group-hover:border-muted " +
          "peer-checked:border-accent peer-checked:bg-[radial-gradient(circle,var(--accent)_0_42%,transparent_46%)] " +
          FOCUS
        }
      />
      <Text label={label} hint={hint} />
    </label>
  );
}

type GroupProps = {
  legend: string;
  name: string;
  options: { value: string; label: ReactNode; hint?: string; disabled?: boolean }[];
  defaultValue?: string;
  className?: string;
};

export function RadioGroup({ legend, name, options, defaultValue, className = "" }: GroupProps) {
  return (
    <fieldset className={`m-0 flex flex-col gap-3 border-0 p-0 ${className}`}>
      <legend className="mb-1 p-0 text-sm font-semibold">{legend}</legend>
      {options.map((option) => (
        <Radio
          key={option.value}
          name={name}
          value={option.value}
          label={option.label}
          hint={option.hint}
          disabled={option.disabled}
          defaultChecked={defaultValue === option.value}
        />
      ))}
    </fieldset>
  );
}

/** An on and off switch. Rounded square, not a pill, like every other shape here. */
export function Switch({ label, hint, className = "", ...rest }: Base) {
  return (
    <label className={`${ROW} ${className}`}>
      <input type="checkbox" role="switch" className={`${INPUT_OVER_FACE} h-7 w-12`} {...rest} />
      <span
        aria-hidden
        className={
          "pointer-events-none relative mt-0.5 inline-block h-7 w-12 shrink-0 rounded-sm border-2 border-line bg-surface-2 " +
          "transition-[background-color,border-color] duration-(--dur) ease-soft group-hover:border-muted " +
          "peer-checked:border-accent peer-checked:bg-accent " +
          "after:absolute after:top-1 after:left-1 after:size-4 after:rounded-xs after:bg-fg after:transition-transform " +
          "after:duration-(--dur) after:ease-soft peer-checked:after:translate-x-5 peer-checked:after:bg-on-accent " +
          FOCUS
        }
      />
      <Text label={label} hint={hint} />
    </label>
  );
}
