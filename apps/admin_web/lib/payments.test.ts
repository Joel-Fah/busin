import { describe, expect, it } from "vitest";

import { breakdownLines } from "./billing";
import {
  CSV_BOM,
  barPercent,
  canRefund,
  csvCell,
  csvRow,
  isLedgerKind,
  ledgerFileName,
  maskPhone,
  monthColumns,
  nextPayoutDay,
  parseAmount,
  parsePaymentFilter,
  parsePayoutProposal,
  parseRefundDecision,
  parseSchoolRefund,
  parseSummary,
  paymentStage,
  paymentsHref,
  payoutErrorKey,
  payoutGroup,
  payoutReadiness,
  refundErrorKey,
  refundGroup,
  showMasked,
} from "./payments";

const form = (values: Record<string, string>) => {
  const data = new FormData();
  for (const [k, v] of Object.entries(values)) data.set(k, v);
  return data;
};
const ID = "00000000-0000-4000-8000-0000000000aa";

describe("csv", () => {
  it("leaves plain text and numbers as they are", () => {
    expect(csvCell("Payment")).toBe("Payment");
    expect(csvCell(5000)).toBe("5000");
    expect(csvCell(-5000)).toBe("-5000");
    expect(csvCell(null)).toBe("");
    expect(csvCell(undefined)).toBe("");
    expect(csvCell(Number.NaN)).toBe("");
  });

  it("quotes commas, quotes and line breaks, doubling quotes", () => {
    expect(csvCell("a,b")).toBe('"a,b"');
    expect(csvCell('say "hi"')).toBe('"say ""hi"""');
    expect(csvCell("one\ntwo")).toBe('"one\ntwo"');
    expect(csvCell("one\r\ntwo")).toBe('"one\r\ntwo"');
  });

  it("defuses text that a spreadsheet would run as a formula", () => {
    expect(csvCell("=HYPERLINK(\"x\")")).toBe("\"'=HYPERLINK(\"\"x\"\")\"");
    expect(csvCell("+1")).toBe("'+1");
    expect(csvCell("-2+3")).toBe("'-2+3");
    expect(csvCell("@SUM(A1)")).toBe("'@SUM(A1)");
    expect(csvCell("\tx")).toBe("'\tx");
    expect(csvCell("\rx")).toBe("\"'\rx\"");
  });

  it("ends each row with CRLF and starts the file with a BOM", () => {
    expect(csvRow(["a", 1, null, "b,c"])).toBe('a,1,,"b,c"\r\n');
    expect(CSV_BOM).toBe("﻿");
  });

  it("names the file after the school in plain letters and the day", () => {
    expect(ledgerFileName("ICT University", "2026-11-17")).toBe("busin-ledger-ict-university-2026-11-17.csv");
    expect(ledgerFileName("École Supérieure d'Été", "2026-11-17")).toBe("busin-ledger-ecole-superieure-d-ete-2026-11-17.csv");
    expect(ledgerFileName("  ", "2026-11-17")).toBe("busin-ledger-school-2026-11-17.csv");
    expect(ledgerFileName("x".repeat(80), "2026-11-17")).toBe(`busin-ledger-${"x".repeat(60)}-2026-11-17.csv`);
  });

  it("knows the ledger's kinds", () => {
    expect(isLedgerKind("payout_reversal")).toBe(true);
    expect(isLedgerKind("gift")).toBe(false);
  });
});

describe("where a payment stands", () => {
  it("groups each payment once", () => {
    expect(paymentStage({ status: "initiated", outcome: null })).toBe("waiting");
    expect(paymentStage({ status: "needs_attention", outcome: null })).toBe("waiting");
    expect(paymentStage({ status: "failed", outcome: null })).toBe("failed");
    expect(paymentStage({ status: "completed", outcome: "applied" })).toBe("paid");
    expect(paymentStage({ status: "completed", outcome: "refunded" })).toBe("refunded");
    expect(paymentStage({ status: "completed", outcome: "applied" }, [{ status: "queued" }])).toBe("refunded");
    // Asked, declined or failed refunds leave it paid.
    expect(paymentStage({ status: "completed", outcome: "applied" }, [{ status: "requested" }, { status: "declined" }, { status: "failed" }])).toBe("paid");
  });

  it("says when the school can refund it itself", () => {
    const paid = { status: "completed", outcome: "applied", purpose: "subscription" };
    expect(canRefund(paid, [])).toBe(true);
    expect(canRefund(paid, [{ status: "declined" }, { status: "failed" }])).toBe(true);
    expect(canRefund(paid, [{ status: "requested" }])).toBe(false);
    expect(canRefund(paid, [{ status: "completed" }])).toBe(false);
    expect(canRefund({ ...paid, purpose: "invoice" }, [])).toBe(false);
    expect(canRefund({ ...paid, outcome: "refunded" }, [])).toBe(false);
    expect(canRefund({ ...paid, status: "processing" }, [])).toBe(false);
  });

  it("names refund and payout statuses", () => {
    expect(refundGroup("requested")).toBe("requested");
    expect(refundGroup("declined")).toBe("declined");
    expect(refundGroup("queued")).toBe("sending");
    expect(refundGroup("in_reconciliation")).toBe("sending");
    expect(refundGroup("completed")).toBe("refunded");
    expect(refundGroup("failed")).toBe("failed");
    expect(payoutGroup("completed")).toBe("sent");
    expect(payoutGroup("queued")).toBe("sending");
    expect(payoutGroup("failed")).toBe("failed");
  });

  it("reads the list filter and builds its address", () => {
    expect(parsePaymentFilter("waiting")).toBe("waiting");
    expect(parsePaymentFilter(["refunded", "paid"])).toBe("refunded");
    expect(parsePaymentFilter("anything")).toBe("all");
    expect(paymentsHref({ status: "all" })).toBe("/payments#payments-list");
    expect(paymentsHref({ status: "failed", size: 50 }, 2)).toBe("/payments?status=failed&page=2&size=50#payments-list");
  });
});

describe("the summary", () => {
  it("reads the database's answer, and survives a broken one", () => {
    const s = parseSummary({
      balance: { available_xaf: 12000, on_hold_xaf: 3000, owed_xaf: 0 },
      fees_paid_by: "school",
      mobile_money: true,
      months: [{ month: "2026-11-01", mobile_money: 20000, receipts: 0, refunds: 1000, charges: 700, payouts: 0, transfer_costs: 400 }, { nope: 1 }],
      payout_account: { provider: "MTN_MOMO_CMR", phone_masked: "2376*****456", account_name: "ICT", usable_from: "2026-11-10T00:00:00Z" },
      refunds_waiting: 2,
      open_invoice: { id: ID, number: "BF-2026-000001", amount_xaf: 1400, due_date: "2026-12-15" },
    });
    expect(s.balance).toEqual({ available: 12000, onHold: 3000, owed: 0 });
    expect(s.feesPaidBy).toBe("school");
    expect(s.months).toHaveLength(1);
    expect(s.payoutAccount?.phoneMasked).toBe("2376*****456");
    expect(s.openInvoice).toEqual({ id: ID, number: "BF-2026-000001", amount: 1400, dueDate: "2026-12-15" });
    const empty = parseSummary(null);
    expect(empty).toMatchObject({ balance: { available: 0, onHold: 0, owed: 0 }, feesPaidBy: "student", mobileMoney: false, months: [], payoutAccount: null, openInvoice: null });
  });

  it("shows transfer costs only when the school bears them or some were taken", () => {
    const month = { month: "2026-11-01", mobile_money: 1, receipts: 0, refunds: 0, charges: 0, payouts: 0, transfer_costs: 0 };
    expect(monthColumns([month], "student")).not.toContain("transfer_costs");
    expect(monthColumns([month], "school")).toContain("transfer_costs");
    expect(monthColumns([{ ...month, transfer_costs: 10 }], "student")).toContain("transfer_costs");
  });

  it("scales bars to the largest figure, with a sliver for small ones", () => {
    expect(barPercent(50, 100)).toBe(50);
    expect(barPercent(1, 1000)).toBe(2);
    expect(barPercent(0, 100)).toBe(0);
    expect(barPercent(-5, 100)).toBe(0);
    expect(barPercent(5, 0)).toBe(0);
  });
});

describe("payouts", () => {
  it("finds the next Monday run (06:00 UTC)", () => {
    expect(nextPayoutDay(new Date("2026-11-17T10:00:00Z"))).toBe("2026-11-23"); // Tuesday
    expect(nextPayoutDay(new Date("2026-11-22T23:00:00Z"))).toBe("2026-11-23"); // Sunday
    expect(nextPayoutDay(new Date("2026-11-23T05:59:00Z"))).toBe("2026-11-23"); // Monday before the run
    expect(nextPayoutDay(new Date("2026-11-23T06:00:00Z"))).toBe("2026-11-30"); // Monday after it
  });

  const base = {
    mobileMoney: true,
    balance: { available: 20000, onHold: 0, owed: 0 },
    payoutAccount: { provider: "MTN_MOMO_CMR", phoneMasked: "2376*****456", accountName: "ICT", usableFrom: "2026-11-01T00:00:00Z" },
  };
  const now = new Date("2026-11-17T10:00:00Z");

  it("says what is missing for a payout, in order", () => {
    expect(payoutReadiness({ ...base, mobileMoney: false }, false, now)).toEqual({ kind: "off" });
    expect(payoutReadiness({ ...base, payoutAccount: null }, false, now)).toEqual({ kind: "noNumber" });
    expect(payoutReadiness({ ...base, payoutAccount: null }, true, now)).toEqual({ kind: "waitingConfirmation" });
    expect(payoutReadiness({ ...base, payoutAccount: { ...base.payoutAccount, usableFrom: "2026-11-20T00:00:00Z" } }, false, now)).toEqual({ kind: "usableFrom", date: "2026-11-20T00:00:00Z" });
    expect(payoutReadiness({ ...base, balance: { available: 4999, onHold: 0, owed: 0 } }, false, now)).toEqual({ kind: "belowMin", available: 4999, min: 5000 });
  });

  it("is ready with the day, the amount and the number", () => {
    expect(payoutReadiness(base, true, now)).toEqual({ kind: "ready", day: "2026-11-23", amount: 20000, provider: "MTN_MOMO_CMR", phone: "2376*****456" });
    // A minimum of zero still needs something to send.
    expect(payoutReadiness({ ...base, balance: { available: 0, onHold: 0, owed: 0 } }, false, now, 0)).toMatchObject({ kind: "belowMin", min: 1 });
  });

  it("masks numbers the server's way", () => {
    expect(maskPhone("237677123456")).toBe("+2376*****456");
    expect(maskPhone(null)).toBe("");
    expect(showMasked("2376*****456")).toBe("+2376*****456");
    expect(showMasked("+2376*****456")).toBe("+2376*****456");
    expect(showMasked(null)).toBe("");
  });
});

describe("forms", () => {
  it("reads whole amounts as people type them", () => {
    expect(parseAmount("5 000")).toBe(5000);
    expect(parseAmount("5,000")).toBe(5000);
    expect(parseAmount("0")).toBeNull();
    expect(parseAmount("-5")).toBeNull();
    expect(parseAmount("12.5x")).toBeNull();
    expect(parseAmount("20000000")).toBeNull();
    expect(parseAmount(null)).toBeNull();
  });

  it("reads a refund decision: all, part with an amount, or declined with a reason", () => {
    expect(parseRefundDecision(form({ refund: ID, decision: "all" }))).toEqual({ ok: true, value: { refund: ID, approve: true, amount: null, note: null } });
    expect(parseRefundDecision(form({ refund: ID, decision: "part", amount: "2 500" }))).toEqual({ ok: true, value: { refund: ID, approve: true, amount: 2500, note: null } });
    expect(parseRefundDecision(form({ refund: ID, decision: "part", amount: "" }))).toEqual({ ok: false, error: "bad_amount" });
    expect(parseRefundDecision(form({ refund: ID, decision: "decline", note: "too short" }))).toEqual({ ok: false, error: "reason_too_short" });
    expect(parseRefundDecision(form({ refund: ID, decision: "decline", note: "" }))).toEqual({ ok: false, error: "reason_required" });
    expect(parseRefundDecision(form({ refund: ID, decision: "decline", note: "  The refund   period has ended.  " }))).toEqual({
      ok: true,
      value: { refund: ID, approve: false, amount: null, note: "The refund period has ended." },
    });
    expect(parseRefundDecision(form({ refund: "nope", decision: "all" }))).toEqual({ ok: false, error: "not_found" });
    expect(parseRefundDecision(form({ refund: ID, decision: "maybe" }))).toEqual({ ok: false, error: "bad_decision" });
  });

  it("reads a refund the school starts", () => {
    expect(parseSchoolRefund(form({ payment: ID, amount: "1000", note: "The student stopped using the bus." }))).toEqual({
      ok: true,
      value: { payment: ID, amount: 1000, reason: "The student stopped using the bus." },
    });
    expect(parseSchoolRefund(form({ payment: ID, amount: "1000", note: "" }))).toEqual({ ok: false, error: "reason_required" });
    expect(parseSchoolRefund(form({ payment: ID, amount: "x", note: "The student stopped using the bus." }))).toEqual({ ok: false, error: "bad_amount" });
  });

  it("reads a payout number proposal", () => {
    expect(parsePayoutProposal(form({ provider: "MTN_MOMO_CMR", phone: "6 77 12 34 56", name: "  ICT   University " }))).toEqual({
      ok: true,
      value: { provider: "MTN_MOMO_CMR", phone: "237677123456", name: "ICT University" },
    });
    expect(parsePayoutProposal(form({ provider: "WAVE", phone: "677123456", name: "ICT" }))).toEqual({ ok: false, error: "bad_provider" });
    expect(parsePayoutProposal(form({ provider: "ORANGE_CMR", phone: "2 22 12 34", name: "ICT" }))).toEqual({ ok: false, error: "bad_phone" });
    expect(parsePayoutProposal(form({ provider: "ORANGE_CMR", phone: "699123456", name: "I" }))).toEqual({ ok: false, error: "bad_name" });
  });

  it("maps the database's refusals to messages", () => {
    expect(refundErrorKey("55000", "not_requested")).toBe("not_requested");
    expect(refundErrorKey("55000", "not_refundable")).toBe("not_refundable");
    expect(refundErrorKey("22023", "bad_amount")).toBe("bad_amount");
    expect(refundErrorKey("22023", "reason_too_short")).toBe("reason_too_short");
    expect(refundErrorKey("P0002", "not_found")).toBe("not_found");
    expect(refundErrorKey("42501", "Admin access required")).toBe("generic");
    expect(payoutErrorKey("55000", "same_admin")).toBe("same_admin");
    expect(payoutErrorKey("55000", "not_proposed")).toBe("not_proposed");
    expect(payoutErrorKey("22023", "bad_phone")).toBe("bad_phone");
    expect(payoutErrorKey("P0002", "not_found")).toBe("not_found");
    expect(payoutErrorKey(undefined, undefined)).toBe("generic");
  });
});

describe("the price breakdown", () => {
  it("puts the receipt first, then each operator", () => {
    const row = (method: string) => ({ method, student_pays: 1, busin_charge: 0, transaction_cost: 0, school_receives: 1 });
    expect(breakdownLines([row("ORANGE_CMR"), row("receipt"), row("MTN_MOMO_CMR")]).map((r) => r.method)).toEqual(["receipt", "MTN_MOMO_CMR", "ORANGE_CMR"]);
    expect(breakdownLines([row("receipt")])[0]).toEqual({ method: "receipt", studentPays: 1, businCharge: 0, transactionCost: 0, schoolReceives: 1 });
  });
});
