"use client";

import Link from "next/link";
import { useEffect, useRef, useState, useTransition } from "react";

import { Card } from "@/components/ui/Card";
import { Radio } from "@/components/ui/Choice";
import { Notice } from "@/components/ui/Notice";
import { useToast } from "@/components/ui/Toast";
import { formatAmount } from "@/lib/billing";
import { format } from "@/lib/i18n/messages";
import type { PaymentsCopy } from "@/lib/i18n/payments";
import type { FeesPaidBy } from "@/lib/payments";

import { PriceBreakdown } from "./PriceBreakdown";

type Line = { method: string; studentPays: number; businCharge: number; transactionCost: number; schoolReceives: number };

type Props = {
  copy: PaymentsCopy["billing"];
  locale: string;
  /** The price as typed, when it is a valid one; null otherwise. */
  price: number | null;
  period: "semester" | "month";
  feesPaidBy: FeesPaidBy;
  mobileMoney: boolean;
  /** The breakdown of the saved price, worked out with the page. */
  initial: Line[];
  saveFees: (who: string) => Promise<{ ok: boolean }>;
  preview: (price: number) => Promise<Line[] | null>;
};

/**
 * Who pays the fees, beside the price (ADR 0029), and what the typed price means per way of paying. The choice is saved
 * as soon as it is made, because the breakdown follows the saved choice; the breakdown asks the database again a moment
 * after the price stops changing, so the portal never repeats the fee rules.
 */
export function FeesAndBreakdown({ copy, locale, price, period, feesPaidBy, mobileMoney, initial, saveFees, preview }: Props) {
  const toast = useToast();
  const [who, setWho] = useState<FeesPaidBy>(feesPaidBy);
  const [lines, setLines] = useState<Line[] | null>(initial);
  const [failed, setFailed] = useState(false);
  const [saving, startSaving] = useTransition();
  const [loading, setLoading] = useState(false);
  const [version, setVersion] = useState(0);
  const latest = useRef(0);

  // A moment after the price stops changing (or the choice is saved), ask the database what it means.
  useEffect(() => {
    if (price === null) return;
    const ask = ++latest.current;
    const timer = window.setTimeout(async () => {
      setLoading(true);
      const answer = await preview(price);
      if (ask !== latest.current) return;
      setLoading(false);
      setFailed(answer === null);
      if (answer) setLines(answer);
    }, 350);
    return () => window.clearTimeout(timer);
  }, [price, version, preview]);

  const choose = (next: FeesPaidBy) => {
    if (next === who) return;
    const before = who;
    setWho(next);
    startSaving(async () => {
      const { ok } = await saveFees(next);
      if (!ok) {
        setWho(before);
        toast(copy.saveError, { tone: "bad" });
        return;
      }
      toast(format(copy.saved, { who: copy.savedWho[next] }), { tone: "ok" });
      setVersion((v) => v + 1);
    });
  };

  const money = (n: number) => formatAmount(n, locale);
  const charge = lines?.[0]?.businCharge ?? 0;
  const methodLabel = (method: string) => (method in copy.methods ? copy.methods[method as keyof typeof copy.methods] : method);

  return (
    <Card className="flex flex-col gap-5">
      <div>
        <h2 className="text-xl font-bold">{copy.feesTitle}</h2>
        <p className="mt-1 max-w-3xl text-sm text-muted">{charge > 0 ? format(copy.feesHint, { charge: money(charge) }) : copy.feesHintNoCharge}</p>
      </div>
      <fieldset className="m-0 flex flex-col gap-3 border-0 p-0" disabled={saving} aria-busy={saving || undefined}>
        <legend className="sr-only">{copy.feesLegend}</legend>
        {(["student", "school"] as const).map((value) => (
          <Radio
            key={value}
            name="fees_paid_by"
            value={value}
            label={value === "student" ? copy.students.label : copy.school.label}
            hint={value === "student" ? copy.students.hint : copy.school.hint}
            checked={who === value}
            onChange={() => choose(value)}
          />
        ))}
      </fieldset>

      <div className="flex flex-col gap-3">
        <div>
          <h3 className="text-lg font-bold">{copy.breakdownTitle}</h3>
          <p className="mt-1 max-w-3xl text-sm text-muted">{format(copy.breakdownHint, { period: copy.periods[period] })}</p>
        </div>
        {mobileMoney ? null : <Notice tone="info">{copy.mobileMoneyOff}</Notice>}
        {price === null ? (
          <p className="text-sm text-muted">{copy.typePrice}</p>
        ) : failed ? (
          <Notice tone="bad">{copy.breakdownError}</Notice>
        ) : lines && lines.length > 0 ? (
          <div data-testid="price-breakdown">
            <PriceBreakdown
              caption={copy.breakdownCaption}
              busy={loading}
              labels={{ method: copy.method, studentPays: copy.studentPays, businCharge: copy.businCharge, transactionCost: copy.transferCost, schoolReceives: copy.schoolReceives }}
              rows={lines.map((l) => ({
                method: methodLabel(l.method),
                studentPays: money(l.studentPays),
                businCharge: money(l.businCharge),
                transactionCost: money(l.transactionCost),
                schoolReceives: money(l.schoolReceives),
              }))}
            />
          </div>
        ) : null}
        <p className="sr-only" aria-live="polite">
          {loading ? copy.loading : ""}
        </p>
        <p>
          <Link href="/payments" className="text-sm font-semibold no-underline">
            {copy.paymentsLink}
          </Link>
        </p>
      </div>
    </Card>
  );
}
