import { describe, expect, it } from "vitest";

import { formatAmount } from "@/lib/billing";
import { studentCatalogues } from "@/lib/i18n/student";

import {
  START_ERRORS,
  failureReason,
  guessOperator,
  isOpen,
  latestByItem,
  linesFromBreakdown,
  linesFromQuote,
  localDigits,
  maskedDisplay,
  normalizeCameroonPhone,
  offeredOperators,
  phoneProblem,
  prefillPhone,
  receiptPrice,
  receiptsOf,
  stageOfPayment,
  startErrorOf,
  type PaymentRow,
} from "./mobile-money";

const payment = (over: Partial<PaymentRow>): PaymentRow => ({
  id: "p",
  purpose: "subscription",
  subscription_id: "s",
  installment_id: null,
  amount_xaf: 20700,
  fee_xaf: 460,
  total_xaf: 21160,
  currency: "XAF",
  provider: "MTN_MOMO_CMR",
  payer_masked: "2376*****456",
  status: "initiated",
  failure_code: null,
  provider_txn: null,
  receipt_no: null,
  outcome: null,
  created_at: "2026-11-17T10:00:00Z",
  completed_at: null,
  ...over,
});

describe("the mobile money number", () => {
  it("is normalised exactly as the server does", () => {
    expect(normalizeCameroonPhone("6 77 12 34 56")).toBe("237677123456");
    expect(normalizeCameroonPhone("+237 677-12-34-56")).toBe("237677123456");
    expect(normalizeCameroonPhone("00237677123456")).toBe("237677123456");
    expect(normalizeCameroonPhone("237677123456")).toBe("237677123456");
    expect(normalizeCameroonPhone("(677) 123 456")).toBe("237677123456");
  });

  it("refuses what is not a Cameroonian mobile number", () => {
    expect(normalizeCameroonPhone("")).toBeNull();
    expect(normalizeCameroonPhone("67712345")).toBeNull(); // 8 digits
    expect(normalizeCameroonPhone("2 22 12 34 56")).toBeNull(); // a landline
    expect(normalizeCameroonPhone("+33 6 12 34 56 78")).toBeNull();
    expect(normalizeCameroonPhone("2376771234567")).toBeNull(); // one digit too many
    expect(phoneProblem("  ")).toBe("empty");
    expect(phoneProblem("6771")).toBe("invalid");
    expect(phoneProblem("677 12 34 56")).toBeNull();
  });

  it("keeps the local digits as they are typed", () => {
    expect(localDigits("+237 69")).toBe("69");
    expect(localDigits("00237 655")).toBe("655");
    expect(localDigits("6 5")).toBe("65");
  });

  it("recognises the network from the first local digits", () => {
    for (const n of ["650", "651", "652", "653", "654", "670", "679", "680", "681", "682", "683"]) expect(guessOperator(`${n}123456`), n).toBe("MTN_MOMO_CMR");
    for (const n of ["655", "656", "657", "658", "659", "690", "699"]) expect(guessOperator(`${n}123456`), n).toBe("ORANGE_CMR");
    for (const n of ["684", "685", "660", "620", "222"]) expect(guessOperator(`${n}123456`), n).toBeNull();
  });

  it("guesses while typing, and only once it can tell", () => {
    expect(guessOperator("6")).toBeNull();
    expect(guessOperator("65")).toBeNull(); // 650-654 MTN, 655-659 Orange
    expect(guessOperator("67")).toBe("MTN_MOMO_CMR");
    expect(guessOperator("69")).toBe("ORANGE_CMR");
    expect(guessOperator("68")).toBeNull();
    expect(guessOperator("+237 6 55")).toBe("ORANGE_CMR");
    expect(guessOperator("00237 6 8 3")).toBe("MTN_MOMO_CMR");
  });

  it("starts from the profile's number when it is a Cameroonian mobile one", () => {
    expect(prefillPhone("+237677123456")).toBe("6 77 12 34 56");
    expect(prefillPhone("+237222123456")).toBe("");
    expect(prefillPhone("+33612345678")).toBe("");
    expect(prefillPhone("+677123456")).toBe("");
    expect(prefillPhone(null)).toBe("");
  });

  it("shows the masked number with its plus", () => {
    expect(maskedDisplay("2376*****456")).toBe("+2376*****456");
    expect(maskedDisplay("+2376*****456")).toBe("+2376*****456");
    expect(maskedDisplay(null)).toBe("");
  });
});

describe("where a payment stands", () => {
  it("groups the statuses as the student sees them", () => {
    for (const status of ["initiated", "accepted", "processing", "in_reconciliation"]) {
      expect(stageOfPayment({ status, outcome: null })).toBe("waiting");
      expect(isOpen(status)).toBe(true);
    }
    expect(stageOfPayment({ status: "needs_attention", outcome: null })).toBe("checking");
    expect(isOpen("needs_attention")).toBe(false);
    expect(stageOfPayment({ status: "completed", outcome: "applied" })).toBe("paid");
    expect(stageOfPayment({ status: "completed", outcome: null })).toBe("paid");
    expect(stageOfPayment({ status: "completed", outcome: "refunded" })).toBe("refunded");
    expect(stageOfPayment({ status: "failed", outcome: null })).toBe("failed");
  });

  it("keeps the newest payment of each request and part", () => {
    const list = [
      payment({ id: "a", created_at: "2026-11-17T10:00:00Z", status: "failed" }),
      payment({ id: "b", created_at: "2026-11-17T10:05:00Z", status: "accepted" }),
      payment({ id: "c", purpose: "installment", installment_id: "i2", created_at: "2026-11-17T09:00:00Z" }),
      payment({ id: "d", purpose: "installment", installment_id: "i2", created_at: "2026-11-17T11:00:00Z", status: "failed" }),
    ];
    const latest = latestByItem(list);
    expect(latest.subscription.s.id).toBe("b");
    expect(latest.installment.i2.id).toBe("d");
  });

  it("lists completed payments as receipts, the latest first", () => {
    const list = [
      payment({ id: "a", status: "completed", receipt_no: "BI-2026-000001", completed_at: "2026-11-01T10:00:00Z" }),
      payment({ id: "b", status: "failed" }),
      payment({ id: "c", status: "completed", receipt_no: "BI-2026-000002", completed_at: "2026-11-02T10:00:00Z", outcome: "refunded" }),
    ];
    expect(receiptsOf(list).map((p) => p.id)).toEqual(["c", "a"]);
  });
});

describe("what went wrong, in the student's words", () => {
  it("turns each pawaPay failure code into a reason", () => {
    expect(failureReason("PAYMENT_NOT_APPROVED")).toBe("notApproved");
    expect(failureReason("INSUFFICIENT_BALANCE")).toBe("balance");
    expect(failureReason("PAYER_NOT_FOUND")).toBe("payerNotFound");
    expect(failureReason("PAYER_LIMIT_REACHED")).toBe("limit");
    expect(failureReason("PAYMENT_IN_PROGRESS")).toBe("inProgress");
    expect(failureReason("PROVIDER_TEMPORARILY_UNAVAILABLE")).toBe("operatorDown");
    expect(failureReason("AMOUNT_OUT_OF_BOUNDS")).toBe("amount");
    expect(failureReason("INVALID_PHONE_NUMBER")).toBe("invalidNumber");
    expect(failureReason("NOT_FOUND")).toBe("notReached");
    expect(failureReason("UNKNOWN")).toBe("other");
    expect(failureReason("SOMETHING_NEW")).toBe("other");
    expect(failureReason(null)).toBe("other");
  });

  it("has words for every reason and every refusal, in both languages", () => {
    for (const locale of ["en", "fr"] as const) {
      const pay = studentCatalogues[locale].subscription.pay;
      for (const code of ["PAYMENT_NOT_APPROVED", "INSUFFICIENT_BALANCE", "PAYER_NOT_FOUND", "PAYER_LIMIT_REACHED", "PAYMENT_IN_PROGRESS", "PROVIDER_TEMPORARILY_UNAVAILABLE", "AMOUNT_OUT_OF_BOUNDS", "INVALID_PHONE_NUMBER", "NOT_FOUND", "X"]) {
        expect(pay.reasons[failureReason(code)].length).toBeGreaterThan(10);
      }
      for (const code of START_ERRORS) expect(pay.errors[code].length).toBeGreaterThan(10);
    }
    expect(studentCatalogues.en.subscription.pay.errors.payments_unavailable).toBe("Mobile money is not available right now. You can upload a receipt instead.");
  });

  it("reads the payments function's refusals", () => {
    expect(startErrorOf(400, { error: "bad_phone" })).toBe("bad_phone");
    expect(startErrorOf(409, { error: "payment_in_progress" })).toBe("payment_in_progress");
    expect(startErrorOf(503, { error: "payments_unavailable" })).toBe("payments_unavailable");
    expect(startErrorOf(429, { error: "too_many_attempts" })).toBe("too_many_attempts");
    expect(startErrorOf(429, null)).toBe("too_many_attempts");
    expect(startErrorOf(403, { error: "account_not_verified" })).toBe("not_allowed");
    expect(startErrorOf(400, { error: "bad_provider" })).toBe("unknown_provider");
    // The gateway, when the function cannot be reached.
    expect(startErrorOf(503, { message: "name resolution failed" })).toBe("payments_unavailable");
    expect(startErrorOf(502, null)).toBe("payments_unavailable");
    expect(startErrorOf(500, null)).toBe("payments_unavailable");
    expect(startErrorOf(500, { error: "payment_error" })).toBe("payment_error");
    expect(startErrorOf(500, { error: "something_else" })).toBe("payment_error");
    expect(startErrorOf(400, null)).toBe("payment_error");
  });
});

describe("prices", () => {
  const breakdown = [
    { method: "receipt", student_pays: 20700 },
    { method: "MTN_MOMO_CMR", student_pays: 21160 },
    { method: "ORANGE_CMR", student_pays: 21165 },
  ];

  it("offers mobile money only with the networks in the breakdown", () => {
    expect(offeredOperators(breakdown)).toEqual(["MTN_MOMO_CMR", "ORANGE_CMR"]);
    expect(offeredOperators([{ method: "receipt", student_pays: 20700 }])).toEqual([]);
    expect(offeredOperators([{ method: "receipt", student_pays: 1 }, { method: "ORANGE_CMR", student_pays: 2 }])).toEqual(["ORANGE_CMR"]);
    expect(offeredOperators(null)).toEqual([]);
  });

  it("says what paying in full comes to with each network", () => {
    expect(receiptPrice(breakdown)).toBe(20700);
    expect(receiptPrice([])).toBeNull();
    expect(linesFromBreakdown(breakdown, "MTN_MOMO_CMR")).toEqual({ amount: 20700, fee: 460, total: 21160 });
    expect(linesFromBreakdown(breakdown, "ORANGE_CMR")).toEqual({ amount: 20700, fee: 465, total: 21165 });
    expect(linesFromBreakdown([{ method: "receipt", student_pays: 20700 }], "ORANGE_CMR")).toBeNull();
    // A school that bears the fees: no fee on top.
    expect(linesFromBreakdown([{ method: "receipt", student_pays: 20000 }, { method: "MTN_MOMO_CMR", student_pays: 20000 }], "MTN_MOMO_CMR")).toEqual({ amount: 20000, fee: 0, total: 20000 });
  });

  it("reads a quote, and an unavailable network as nothing", () => {
    const quote = [
      { provider: "MTN_MOMO_CMR", amount_xaf: 8280, fee_xaf: 184, total_xaf: 8464, currency: "XAF" },
      { provider: "ORANGE_CMR", amount_xaf: 8280, fee_xaf: null, total_xaf: null, currency: "XAF" },
    ];
    expect(linesFromQuote(quote, "MTN_MOMO_CMR")).toEqual({ amount: 8280, fee: 184, total: 8464 });
    expect(linesFromQuote(quote, "ORANGE_CMR")).toBeNull();
    expect(linesFromQuote(null, "MTN_MOMO_CMR")).toBeNull();
  });

  it("writes amounts in whole francs, the student's way", () => {
    expect(formatAmount(21160, "en")).toBe("21,160 XAF");
    expect(formatAmount(21160, "fr").replace(/\s/g, " ")).toBe("21 160 XAF");
  });
});
