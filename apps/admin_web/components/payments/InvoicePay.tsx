"use client";

import { Call02Icon, SmartPhone01Icon } from "@hugeicons/core-free-icons";
import { useRouter } from "next/navigation";
import { useEffect, useState, useTransition } from "react";

import type { InvoicePaymentStart, InvoicePaymentState } from "@/app/(admin)/payments/actions";
import { Button } from "@/components/ui/Button";
import { Radio } from "@/components/ui/Choice";
import { Input } from "@/components/ui/Input";
import { Notice } from "@/components/ui/Notice";
import { formatAmount } from "@/lib/billing";
import { format } from "@/lib/i18n/messages";
import type { PaymentsCopy } from "@/lib/i18n/payments";
import { PROVIDERS, guessOperator, isOpenPayment, normalizeCameroonPhone, type Provider } from "@/lib/payments";

type QuoteLine = { provider: string; amount: number; fee: number | null; total: number | null };

type Props = {
  invoice: { id: string };
  quote: QuoteLine[];
  /** A payment of this invoice still going when the page opened: the form waits for it. */
  pending: { id: string; total: number } | null;
  locale: string;
  copy: PaymentsCopy["pay"];
  operators: PaymentsCopy["operators"];
  start: (input: { invoice: string; phone: string; provider?: string | null }) => Promise<InvoicePaymentStart>;
  check: (paymentId: string) => Promise<InvoicePaymentState>;
};

type Stage = { kind: "form" } | { kind: "waiting"; id: string; total: number } | { kind: "checking"; id: string; total: number } | { kind: "paid"; receipt: string } | { kind: "failed" };

/** How often a waiting payment is asked about, in milliseconds. */
const POLL_MS = 4000;

/**
 * Paying BusIn's open invoice by mobile money from the portal: the number (its network guessed as it is typed, and
 * changeable), what paying comes to, then a waiting state that asks about the payment every few seconds until it is
 * paid or failed. The server starts the payment with the administrator's own session.
 */
export function InvoicePay({ invoice, quote, pending, locale, copy, operators, start, check }: Props) {
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [chosen, setChosen] = useState<Provider | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [stage, setStage] = useState<Stage>(pending ? { kind: "waiting", id: pending.id, total: pending.total } : { kind: "form" });
  const [starting, startTransition] = useTransition();
  const provider = chosen ?? guessOperator(phone);
  const line = quote.find((q) => q.provider === provider) ?? null;
  const money = (n: number) => formatAmount(n, locale);

  // Ask about a waiting payment every few seconds, while the tab is visible.
  const waitingId = stage.kind === "waiting" || stage.kind === "checking" ? stage.id : null;
  useEffect(() => {
    if (!waitingId) return;
    let stopped = false;
    const timer = window.setInterval(async () => {
      if (document.visibilityState !== "visible") return;
      const state = await check(waitingId);
      if (stopped || !state) return;
      if (state.status === "completed") {
        setStage({ kind: "paid", receipt: state.receiptNo ?? "" });
        router.refresh();
      } else if (state.status === "failed") {
        setStage({ kind: "failed" });
      } else if (state.status === "needs_attention") {
        setStage((s) => (s.kind === "waiting" ? { kind: "checking", id: s.id, total: s.total } : s));
      } else if (!isOpenPayment(state.status)) {
        setStage({ kind: "failed" });
      }
    }, POLL_MS);
    return () => {
      stopped = true;
      window.clearInterval(timer);
    };
  }, [waitingId, check, router]);

  const submit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    if (!normalizeCameroonPhone(phone)) {
      setError(copy.errors.bad_phone);
      return;
    }
    startTransition(async () => {
      const result = await start({ invoice: invoice.id, phone, provider });
      if (!result.ok) {
        setError(copy.errors[result.error] ?? copy.errors.payment_error);
        return;
      }
      setStage({ kind: "waiting", id: result.paymentId, total: result.total || line?.total || 0 });
    });
  };

  if (stage.kind === "waiting" || stage.kind === "checking") {
    return (
      <div className="flex flex-col gap-2 rounded-md bg-info-bg p-4 text-info" role="status" data-testid="invoice-waiting">
        <p className="m-0 font-semibold">{stage.kind === "checking" ? copy.checking : format(copy.waiting, { total: money(stage.total) })}</p>
      </div>
    );
  }
  if (stage.kind === "paid") {
    return <Notice tone="ok">{format(copy.paid, { number: stage.receipt })}</Notice>;
  }

  return (
    <form onSubmit={submit} className="flex flex-col gap-4" data-testid="invoice-pay">
      <div>
        <h3 className="text-lg font-bold">{copy.title}</h3>
        <p className="mt-1 text-sm text-muted">{copy.hint}</p>
      </div>
      {stage.kind === "failed" ? <Notice tone="bad">{copy.failed}</Notice> : null}
      <Input
        id="invoice-phone"
        name="phone"
        label={copy.number}
        hint={copy.numberHint}
        icon={SmartPhone01Icon}
        inputMode="tel"
        autoComplete="tel"
        maxLength={40}
        required
        value={phone}
        onChange={(event) => setPhone(event.target.value)}
        className="max-w-sm"
      />
      <fieldset className="m-0 flex flex-col gap-3 border-0 p-0">
        <legend className="mb-1 p-0 text-sm font-semibold">{copy.network}</legend>
        {PROVIDERS.map((p) => (
          <Radio key={p} name="provider" value={p} label={operators[p]} checked={provider === p} onChange={() => setChosen(p)} />
        ))}
        {provider ? null : <p className="m-0 text-sm text-muted">{copy.unknownNetwork}</p>}
      </fieldset>
      {line && line.fee !== null && line.total !== null ? (
        <dl className="m-0 grid max-w-sm gap-1 rounded-md bg-surface-2 p-4 text-sm" data-testid="invoice-quote">
          <div className="flex justify-between gap-4">
            <dt className="text-muted">{copy.amount}</dt>
            <dd className="m-0 tabular-nums">{money(line.amount)}</dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt className="text-muted">{copy.fee}</dt>
            <dd className="m-0 tabular-nums">{money(line.fee)}</dd>
          </div>
          <div className="flex justify-between gap-4 font-bold">
            <dt>{copy.total}</dt>
            <dd className="m-0 tabular-nums">{money(line.total)}</dd>
          </div>
        </dl>
      ) : null}
      {error ? <Notice tone="bad">{error}</Notice> : null}
      <div>
        <Button type="submit" icon={Call02Icon} disabled={starting}>
          {line?.total ? format(copy.start, { total: money(line.total) }) : copy.title}
        </Button>
      </div>
    </form>
  );
}
