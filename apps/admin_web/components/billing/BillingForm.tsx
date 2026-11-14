"use client";

import { Coins01Icon } from "@hugeicons/core-free-icons";
import { useState } from "react";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Radio } from "@/components/ui/Choice";
import { Input } from "@/components/ui/Input";
import { Notice } from "@/components/ui/Notice";
import { INSTALLMENT_PLANS, formatAmount, planPercents, splitAmount, type BillingField, type BillingPeriod, type InstallmentPlan, type SchoolBilling } from "@/lib/billing";
import { format, type Messages } from "@/lib/i18n/messages";

import { PlanParts } from "./PlanParts";

/**
 * The school's billing: per semester or per month, the price, and in full or one of the installment plans (semester
 * only). A line under it says what a student will pay, as they type.
 */
export function BillingForm({
  copy,
  current,
  locale,
  action,
  error,
}: {
  copy: Messages["billing"];
  current: SchoolBilling | null;
  locale: string;
  action: (formData: FormData) => Promise<void>;
  error: BillingField | "generic" | null;
}) {
  const [period, setPeriod] = useState<BillingPeriod>(current?.period ?? "semester");
  const [price, setPrice] = useState(current ? String(current.price) : "");
  const [payment, setPayment] = useState<"full" | InstallmentPlan>(current?.plan ?? "full");
  const amount = Number(price.replace(/[\s,.  ]/g, ""));
  const valid = Number.isInteger(amount) && amount > 0;
  const plan = period === "semester" && payment !== "full" ? payment : null;
  const money = (n: number) => formatAmount(n, locale, current?.currency ?? "XAF");

  const preview = !valid
    ? null
    : plan
      ? format(copy.preview, { parts: splitAmount(amount, plan).map(money).join(", ") })
      : format(copy.previewFull, { amount: money(amount) });

  return (
    <form action={action} className="flex flex-col gap-6">
      {error ? <Notice tone="bad">{copy.errors[error]}</Notice> : null}

      <Card className="flex flex-col gap-4">
        <h2 className="text-xl font-bold">{copy.period.title}</h2>
        <fieldset className="m-0 flex flex-col gap-3 border-0 p-0">
          <legend className="sr-only">{copy.period.title}</legend>
          {(["semester", "month"] as const).map((value) => (
            <Radio
              key={value}
              name="period"
              value={value}
              label={copy.period[value].label}
              hint={copy.period[value].hint}
              checked={period === value}
              onChange={() => setPeriod(value)}
            />
          ))}
        </fieldset>
      </Card>

      <Card className="flex flex-col gap-4">
        <h2 className="text-xl font-bold">{copy.price.title}</h2>
        <Input
          id="billing-price"
          name="price"
          label={copy.price.label}
          hint={copy.price.hint}
          icon={Coins01Icon}
          inputMode="numeric"
          autoComplete="off"
          required
          value={price}
          onChange={(event) => setPrice(event.target.value)}
          error={error === "price" ? copy.errors.price : undefined}
          className="max-w-xs"
        />
      </Card>

      <Card className="flex flex-col gap-4">
        <h2 className="text-xl font-bold">{copy.payment.title}</h2>
        {period === "month" ? <Notice tone="info">{copy.payment.monthNote}</Notice> : null}
        <fieldset className="m-0 flex flex-col gap-4 border-0 p-0">
          <legend className="sr-only">{copy.payment.title}</legend>
          <Radio name="payment" value="full" label={copy.payment.full.label} hint={copy.payment.full.hint} checked={plan === null} onChange={() => setPayment("full")} />
          {INSTALLMENT_PLANS.map((value) => (
            <div key={value} className="flex flex-col gap-2">
              <Radio
                name="payment"
                value={value}
                label={format(copy.payment.plan, { parts: planPercents(value).map((p) => `${p}%`).join(", ") })}
                hint={copy.payment.planHint}
                checked={plan === value}
                disabled={period === "month"}
                onChange={() => setPayment(value)}
              />
              <div className="pl-9">
                <PlanParts
                  percents={planPercents(value)}
                  amounts={valid ? splitAmount(amount, value).map(money) : undefined}
                  label={format(copy.payment.plan, { parts: value })}
                />
              </div>
            </div>
          ))}
        </fieldset>
      </Card>

      <div className="flex flex-col gap-3">
        {preview ? (
          <p className="text-lg font-semibold" aria-live="polite" data-testid="billing-preview">
            {preview}
          </p>
        ) : null}
        <p className="text-sm text-muted">{copy.note}</p>
        <div>
          <Button type="submit">{copy.save}</Button>
        </div>
      </div>
    </form>
  );
}
