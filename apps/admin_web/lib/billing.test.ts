import { describe, expect, it } from "vitest";

import { billingSaveError, formatAmount, parseBillingForm, partsAttention, schoolBilling, splitAmount } from "./billing";

function form(values: Record<string, string>): FormData {
  const data = new FormData();
  for (const [key, value] of Object.entries(values)) data.set(key, value);
  return data;
}

describe("school billing", () => {
  it("splits a price into parts that add up exactly, the last taking what is left", () => {
    expect(splitAmount(30000, "40-30-30")).toEqual([12000, 9000, 9000]);
    expect(splitAmount(30001, "40-30-30")).toEqual([12000, 9000, 9001]);
    expect(splitAmount(10001, "30-60-10")).toEqual([3000, 6000, 1001]);
    for (const total of [1, 7, 99, 25001, 9_999_999]) {
      for (const plan of ["50-50", "40-30-30", "30-60-10"] as const) {
        expect(splitAmount(total, plan).reduce((a, b) => a + b, 0)).toBe(total);
      }
    }
  });

  it("writes amounts as each language does", () => {
    expect(formatAmount(30000, "en")).toBe("30,000 XAF");
    expect(formatAmount(30000, "fr").replace(/\s/g, " ")).toBe("30 000 XAF");
  });

  it("reads the form: a period, a price written with or without separators, and how students may pay", () => {
    expect(parseBillingForm(form({ period: "semester", price: "30 000", payment: "40-30-30" }))).toEqual({ ok: true, value: { period: "semester", price: 30000, plan: "40-30-30" } });
    expect(parseBillingForm(form({ period: "month", price: "5,000", payment: "full" }))).toEqual({ ok: true, value: { period: "month", price: 5000, plan: null } });
  });

  it("says which field is wrong", () => {
    expect(parseBillingForm(form({ period: "weekly", price: "1" }))).toEqual({ ok: false, field: "period" });
    expect(parseBillingForm(form({ period: "semester", price: "0" }))).toEqual({ ok: false, field: "price" });
    expect(parseBillingForm(form({ period: "semester", price: "12.5k" }))).toEqual({ ok: false, field: "price" });
    expect(parseBillingForm(form({ period: "semester", price: "10000001" }))).toEqual({ ok: false, field: "price" });
    expect(parseBillingForm(form({ period: "semester", price: "100", payment: "20-80" }))).toEqual({ ok: false, field: "plan" });
    expect(parseBillingForm(form({ period: "month", price: "100", payment: "50-50" })), "a month is paid in full").toEqual({ ok: false, field: "plan" });
    expect(billingSaveError("invalid_plan")).toBe("plan");
    expect(billingSaveError("something")).toBe("generic");
  });

  it("knows when a school has not set billing yet", () => {
    expect(schoolBilling(null)).toBeNull();
    expect(schoolBilling({ billing_period: null, price_xaf: null, installment_plan: null, currency: "XAF" })).toBeNull();
    expect(schoolBilling({ billing_period: "semester", price_xaf: 30000, installment_plan: "50-50", currency: "XAF" })).toEqual({ period: "semester", price: 30000, plan: "50-50", currency: "XAF" });
  });

  it("points at the part that needs the school: one to check first, else one that is late", () => {
    const today = "2026-11-14";
    expect(partsAttention([{ seq: 1, status: "paid", due_date: "2026-09-01" }, { seq: 2, status: "due", due_date: "2026-12-01" }], today)).toBeNull();
    expect(partsAttention([{ seq: 2, status: "due", due_date: "2026-11-14" }], today)).toEqual({ seq: 2, kind: "overdue" });
    expect(partsAttention([{ seq: 2, status: "rejected", due_date: "2026-11-01" }, { seq: 3, status: "submitted", due_date: "2026-12-20" }], today)).toEqual({ seq: 3, kind: "toCheck" });
    expect(partsAttention([{ seq: 1, status: "submitted", due_date: "2026-11-14" }], today), "part 1 is the request itself").toBeNull();
  });
});
