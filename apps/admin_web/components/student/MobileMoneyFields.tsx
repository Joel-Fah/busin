"use client";

import { SmartPhone01Icon } from "@hugeicons/core-free-icons";
import { useId, useState } from "react";

import { Icon } from "@/components/ui/Icon";
import { formatAmount } from "@/lib/billing";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import { guessOperator, localDigits, phoneProblem, type PriceLines, type Provider } from "@/lib/student/mobile-money";

import { OperatorBadge } from "./OperatorBadge";

type PayCopy = StudentCopy["subscription"]["pay"];

/** The operator to show and pay with: the one the student chose, else the one the number's range suggests. */
export function effectiveOperator(phone: string, chosen: Provider | null): Provider | null {
  return chosen ?? guessOperator(phone);
}

/**
 * The mobile money number: typed freely (spaces, +237 or not), its network recognised as it is typed and shown with its
 * mark, and a small Change to choose the other network when the guess is wrong (numbers move between networks). Only a
 * network the student chose is sent; otherwise the server asks pawaPay.
 */
export function MobileMoneyNumber({
  copy,
  value,
  onChange,
  chosen,
  onChoose,
  operators,
  disabled,
}: {
  copy: PayCopy;
  value: string;
  onChange: (value: string) => void;
  chosen: Provider | null;
  onChoose: (provider: Provider) => void;
  /** The networks the school takes payments with. */
  operators: Provider[];
  disabled?: boolean;
}) {
  const id = useId();
  const [touched, setTouched] = useState(false);
  const [changing, setChanging] = useState(false);
  const operator = effectiveOperator(value, chosen);
  const problem = phoneProblem(value);
  const showProblem = touched && problem === "invalid";
  const typedEnough = localDigits(value).length >= 3;
  const unavailable = operator !== null && !operators.includes(operator);

  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={`${id}-number`} className="text-sm font-semibold">
        {copy.numberLabel}
      </label>
      <div className="relative">
        <span className="pointer-events-none absolute inset-y-0 left-3.5 flex items-center text-muted">
          <Icon icon={SmartPhone01Icon} size={18} />
        </span>
        <input
          id={`${id}-number`}
          type="tel"
          inputMode="tel"
          autoComplete="tel-national"
          maxLength={20}
          value={value}
          disabled={disabled}
          placeholder="6 77 12 34 56"
          aria-invalid={showProblem ? true : undefined}
          aria-describedby={`${id}-hint ${id}-operator`}
          onChange={(event) => onChange(event.target.value)}
          onBlur={() => setTouched(true)}
          data-testid="momo-number"
          className={
            "h-12 w-full rounded-sm border bg-surface pr-4 pl-11 font-sans text-base text-fg tabular-nums " +
            "placeholder:text-muted transition-[border-color,box-shadow] duration-(--dur-fast) " +
            "focus:outline-none focus:ring-3 focus:ring-focus/30 disabled:opacity-60 " +
            (showProblem ? "border-bad focus:border-bad" : "border-line focus:border-focus")
          }
        />
      </div>
      {showProblem ? (
        <p id={`${id}-hint`} role="alert" className="m-0 text-sm text-bad">
          {copy.numberInvalid}
        </p>
      ) : (
        <p id={`${id}-hint`} className="m-0 text-sm text-muted">
          {copy.numberHint}
        </p>
      )}
      <div id={`${id}-operator`} className="flex min-h-8 flex-wrap items-center justify-between gap-2" aria-live="polite">
        {operator ? (
          <OperatorBadge provider={operator} name={copy.operators[operator]} />
        ) : typedEnough ? (
          <span className="text-sm text-muted">{copy.operatorUnknown}</span>
        ) : (
          <span />
        )}
        {(operator || typedEnough) && operators.length > 0 ? (
          <button
            type="button"
            disabled={disabled}
            aria-expanded={changing}
            onClick={() => setChanging((open) => !open)}
            className="min-h-8 cursor-pointer rounded-sm border-0 bg-transparent px-2 font-sans text-sm font-semibold text-fg hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus"
          >
            {copy.change}
          </button>
        ) : null}
      </div>
      {changing ? (
        <div role="radiogroup" aria-label={copy.operatorLabel} className="grid auto-cols-fr grid-flow-col gap-1 rounded-md bg-surface-2 p-1">
          {operators.map((p) => (
            <button
              key={p}
              type="button"
              role="radio"
              aria-checked={operator === p}
              disabled={disabled}
              onClick={() => {
                onChoose(p);
                setChanging(false);
              }}
              className={
                "flex min-h-11 cursor-pointer items-center justify-center rounded-sm border-0 px-3 font-sans text-fg transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus " +
                (operator === p ? "bg-surface shadow-soft" : "bg-transparent hover:bg-surface")
              }
            >
              <OperatorBadge provider={p} name={copy.operators[p]} />
            </button>
          ))}
        </div>
      ) : null}
      {unavailable ? (
        <p role="alert" className="m-0 text-sm text-bad">
          {format(copy.operatorUnavailable, { operator: copy.operators[operator] })}
        </p>
      ) : null}
    </div>
  );
}

/**
 * What paying comes to, before paying: the price (or the part), the mobile money fee when there is one, and the total.
 * With the network not known yet, the total for each.
 */
export function PriceSummary({
  copy,
  amountLabel,
  operator,
  lines,
  locale,
  currency,
}: {
  copy: PayCopy;
  amountLabel: string;
  operator: Provider | null;
  lines: Partial<Record<Provider, PriceLines>>;
  locale: string;
  currency: string;
}) {
  const money = (n: number) => formatAmount(n, locale, currency);
  const all = Object.values(lines);
  // Without the network, one set of lines when every network comes to the same, else the total for each.
  const known = operator ? lines[operator] : all.length > 0 && all.every((l) => l.total === all[0].total) ? all[0] : undefined;
  const any = all[0];
  if (!known && !any) return null;
  const row = (label: string, value: string, strong = false, testId?: string) => (
    <div className="flex items-baseline justify-between gap-3" data-testid={testId}>
      <dt className={strong ? "font-bold" : "text-muted"}>{label}</dt>
      <dd className={`m-0 tabular-nums ${strong ? "font-bold" : ""}`}>{value}</dd>
    </div>
  );
  return (
    <dl className="m-0 flex flex-col gap-1.5 rounded-md bg-surface-2 p-4 text-sm" data-testid="price-lines">
      {known ? (
        <>
          {row(amountLabel, money(known.amount))}
          {known.fee > 0 ? row(copy.fee, money(known.fee), false, "price-fee") : null}
          {row(copy.total, money(known.total), true, "price-total")}
        </>
      ) : (
        <>
          {row(amountLabel, money(any!.amount))}
          {(Object.entries(lines) as [Provider, PriceLines][]).map(([p, l]) => (
            <div key={p}>{row(`${copy.total} · ${copy.operators[p]}`, money(l.total), true)}</div>
          ))}
        </>
      )}
    </dl>
  );
}
