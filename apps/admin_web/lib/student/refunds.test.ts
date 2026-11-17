import { describe, expect, it } from "vitest";

import { canAskRefund, latestRefunds, reasonProblem, refundStage, type RefundRow } from "./refunds";

const row = (status: RefundRow["status"], payment_id = "p1"): RefundRow => ({
  id: `r-${status}`,
  payment_id,
  amount_xaf: 15000,
  total_xaf: 15000,
  status,
  decision_note: null,
  receipt_no: null,
  requested_at: "2026-11-17T08:00:00Z",
});

describe("refunds", () => {
  it("reads pawaPay's stages and a case set aside as on its way", () => {
    for (const s of ["queued", "accepted", "processing", "in_reconciliation", "needs_attention"] as const) expect(refundStage(s)).toBe("onItsWay");
    expect(refundStage("requested")).toBe("requested");
    expect(refundStage("completed")).toBe("done");
    expect(refundStage("declined")).toBe("declined");
    expect(refundStage("failed")).toBe("delayed");
  });

  it("allows one refund at a time, and asking again after a decline or a failure", () => {
    const paid = { id: "p1", status: "completed", outcome: "applied" };
    expect(canAskRefund(paid, [])).toBe(true);
    expect(canAskRefund(paid, [row("requested")])).toBe(false);
    expect(canAskRefund(paid, [row("completed")])).toBe(false);
    expect(canAskRefund(paid, [row("declined")])).toBe(true);
    expect(canAskRefund(paid, [row("failed")])).toBe(true);
    expect(canAskRefund(paid, [row("requested", "other")])).toBe(true);
    // BusIn already refunds it.
    expect(canAskRefund({ ...paid, outcome: "refunded" }, [])).toBe(false);
    expect(canAskRefund({ ...paid, status: "failed" }, [])).toBe(false);
  });

  it("keeps the newest refund of each payment", () => {
    const newest = row("requested");
    expect(latestRefunds([newest, row("declined")])).toEqual({ p1: newest });
  });

  it("checks the reason as the server does", () => {
    expect(reasonProblem("  too   short ")).toBe("short");
    expect(reasonProblem("I am leaving the school")).toBeNull();
    expect(reasonProblem("x".repeat(501))).toBe("long");
  });
});
