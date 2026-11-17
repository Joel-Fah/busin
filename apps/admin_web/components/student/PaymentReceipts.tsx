import { Chip } from "@/components/ui/Chip";
import { Contour } from "@/components/ui/Contour";
import { formatAmount } from "@/lib/billing";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import { isProvider, maskedDisplay, type PaymentRow } from "@/lib/student/mobile-money";
import { canAskRefund, latestRefunds, refundStage, type RefundRow } from "@/lib/student/refunds";

import { Notice } from "@/components/ui/Notice";

import { OperatorBadge } from "./OperatorBadge";
import { RefundAsk } from "./RefundAsk";

/**
 * The student's receipts for what they paid by mobile money (ADR 0029): number, date, amount, fee, total, network, the
 * number that paid (masked) and pawaPay's transaction id. A payment the request could no longer take is being refunded
 * in full, and says so. Under each, its refund (ADR 0029): where it stands, or "Ask for a refund" while none is under way.
 */
export function PaymentReceipts({
  copy,
  receipts,
  partOf,
  timeOf,
  locale,
  refunds = [],
}: {
  copy: StudentCopy["subscription"]["pay"];
  receipts: PaymentRow[];
  /** The part number a payment paid, by installment id. */
  partOf: Record<string, number>;
  timeOf: (iso: string) => string;
  locale: string;
  /** The refunds of these payments, newest first. */
  refunds?: RefundRow[];
}) {
  if (receipts.length === 0) return null;
  const r = copy.receipts;
  const latest = latestRefunds(refunds);
  const rc = copy.refunds;
  return (
    <section aria-labelledby="payments-title" className="relative flex flex-col gap-3 rounded-lg bg-surface p-6 shadow-soft" data-testid="payment-receipts">
      <Contour radius={28} inset={10} />
      <div>
        <h2 id="payments-title" className="m-0 text-lg font-bold">
          {r.title}
        </h2>
        <p className="m-0 text-sm text-muted">{r.hint}</p>
      </div>
      <ul className="m-0 flex list-none flex-col gap-3 p-0">
        {receipts.map((p) => {
          const money = (n: number) => formatAmount(n, locale, p.currency);
          const refunded = p.outcome === "refunded";
          const what = p.purpose === "installment" && p.installment_id && partOf[p.installment_id] ? format(r.forPart, { n: partOf[p.installment_id] }) : r.forRequest;
          const line = (label: string, value: string, strong = false) => (
            <div className="flex items-baseline justify-between gap-3">
              <dt className={strong ? "font-bold" : "text-muted"}>{label}</dt>
              <dd className={`m-0 min-w-0 text-right tabular-nums break-all ${strong ? "font-bold" : ""}`}>{value}</dd>
            </div>
          );
          return (
            <li key={p.id} className="flex flex-col gap-3 rounded-md bg-surface-2 p-4" data-testid="payment-receipt">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <p className="m-0 font-bold">{format(r.number, { number: p.receipt_no ?? "" })}</p>
                <Chip tone={refunded ? "warn" : "ok"}>{refunded ? copy.refunding : r.paid}</Chip>
              </div>
              <p className="m-0 text-sm text-muted">{what}</p>
              {refunded ? <p className="m-0 text-sm">{r.refundedBody}</p> : null}
              <dl className="m-0 flex flex-col gap-1.5 text-sm">
                {line(r.date, timeOf(p.completed_at ?? p.created_at))}
                {line(r.amount, money(p.amount_xaf))}
                {p.fee_xaf > 0 ? line(r.fee, money(p.fee_xaf)) : null}
                {line(r.total, money(p.total_xaf), true)}
                <div className="flex items-center justify-between gap-3">
                  <dt className="text-muted">{r.operator}</dt>
                  <dd className="m-0 min-w-0">{isProvider(p.provider) ? <OperatorBadge provider={p.provider} name={copy.operators[p.provider]} /> : p.provider}</dd>
                </div>
                {line(r.payer, maskedDisplay(p.payer_masked))}
                {p.provider_txn ? line(r.txn, p.provider_txn) : null}
              </dl>
              {latest[p.id] ? <RefundLine copy={rc} refund={latest[p.id]} money={money} /> : null}
              {canAskRefund(p, refunds) ? <RefundAsk copy={rc} paymentId={p.id} /> : null}
            </li>
          );
        })}
      </ul>
    </section>
  );
}

function RefundLine({ copy, refund, money }: { copy: StudentCopy["subscription"]["pay"]["refunds"]; refund: RefundRow; money: (n: number) => string }) {
  const stage = refundStage(refund.status);
  const amount = money(refund.total_xaf);
  const text = { requested: copy.requested, onItsWay: format(copy.onItsWay, { amount }), done: format(copy.done, { amount }), declined: copy.declined, delayed: copy.delayed }[stage];
  const tone = stage === "done" ? "ok" : stage === "declined" ? "bad" : stage === "delayed" ? "warn" : "info";
  return (
    <Notice tone={tone} className="flex flex-col gap-1">
      <span data-testid="refund-line">{text}</span>
      {stage === "declined" && refund.decision_note ? <span>{refund.decision_note}</span> : null}
      {refund.receipt_no ? <span>{format(copy.receipt, { number: refund.receipt_no })}</span> : null}
    </Notice>
  );
}
