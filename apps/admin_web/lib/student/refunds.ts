// Refunds of mobile money payments, as the student sees them (ADR 0029). Pure logic, tested in refunds.test.ts.

export type RefundStatus = "requested" | "declined" | "queued" | "accepted" | "processing" | "in_reconciliation" | "completed" | "failed" | "needs_attention";

export type RefundRow = {
  id: string;
  payment_id: string;
  amount_xaf: number;
  total_xaf: number;
  status: RefundStatus;
  decision_note: string | null;
  receipt_no: string | null;
  requested_at: string;
};

/** Named columns only; the reason the student wrote is theirs and not needed back on this page. */
export const REFUND_COLUMNS = "id, payment_id, amount_xaf, total_xaf, status, decision_note, receipt_no, requested_at";

/** Where a refund stands in the student's words: pawaPay's stages and a case BusIn checks all read as on its way. */
export type RefundStage = "requested" | "onItsWay" | "done" | "declined" | "delayed";

export function refundStage(status: string): RefundStage {
  if (status === "requested") return "requested";
  if (status === "declined") return "declined";
  if (status === "completed") return "done";
  if (status === "failed") return "delayed";
  return "onItsWay";
}

/** A declined or failed refund leaves the payment refundable again; any other one is under way or done. */
export function isLive(refund: Pick<RefundRow, "status">): boolean {
  return refund.status !== "declined" && refund.status !== "failed";
}

/** The newest refund of each payment (the rows come newest first). */
export function latestRefunds(refunds: RefundRow[]): Record<string, RefundRow> {
  const out: Record<string, RefundRow> = {};
  for (const r of refunds) if (!out[r.payment_id]) out[r.payment_id] = r;
  return out;
}

/** Whether the student can ask for a refund of a payment: paid and used for their request, with no refund under way. */
export function canAskRefund(payment: { id: string; status: string; outcome: string | null }, refunds: RefundRow[]): boolean {
  return payment.status === "completed" && payment.outcome === "applied" && !refunds.some((r) => r.payment_id === payment.id && isLive(r));
}

/** A reason the server accepts: 10 to 500 characters once spaces are tidied. */
export function reasonProblem(reason: string): "short" | "long" | null {
  const clean = reason.replace(/\s+/g, " ").trim();
  if (clean.length < 10) return "short";
  if (clean.length > 500) return "long";
  return null;
}
