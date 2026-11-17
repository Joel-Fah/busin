import { describe, expect, it } from "vitest";

import {
  costMonths,
  costsByMonth,
  currentMonths,
  feeEstimate,
  parseAlerts,
  parseDecimal,
  parseInfraCost,
  parsePlatformPayments,
  parseSchoolPayments,
  parseSchoolTerms,
  parseSettings,
  parseSettingsForm,
  parseWalletMovement,
  parseWhole,
  platformPaymentErrorKey,
  rateField,
  serviceFee,
  settingsChanges,
  transferCost,
  walletGap,
  type PaymentSettings,
  type ProviderRate,
} from "./platform-payments";

const base: PaymentSettings = {
  pawapay_percent: 1,
  pawapay_vat_percent: 0,
  fee_buffer_percent: 0.2,
  fee_min_xaf: 0,
  student_fee_allowed: true,
  hold_days: 7,
  payout_min_xaf: 5000,
  charge_semester_xaf: 0,
  charge_month_xaf: 0,
  max_starts_per_hour: 6,
};
const zero = { percent: 0, fixed: 0 };
const ratesOf = (mtn: { deposit: number | null; payout: number | null }, orange = { deposit: 0, payout: 0 } as { deposit: number | null; payout: number | null }): ProviderRate[] => [
  { provider: "MTN_MOMO_CMR", operation: "deposit", percent: mtn.deposit, fixed: 0 },
  { provider: "MTN_MOMO_CMR", operation: "payout", percent: mtn.payout, fixed: 0 },
  { provider: "MTN_MOMO_CMR", operation: "refund", percent: 0, fixed: 0 },
  { provider: "ORANGE_CMR", operation: "deposit", percent: orange.deposit, fixed: 0 },
  { provider: "ORANGE_CMR", operation: "payout", percent: orange.payout, fixed: 0 },
  { provider: "ORANGE_CMR", operation: "refund", percent: 0, fixed: 0 },
];

describe("serviceFee, as private.service_fee", () => {
  it("is 445 on 20,000 XAF with pawaPay 1%, operators at 0 and a 0.2% margin", () => {
    expect(serviceFee(base, { deposit: zero, payout: zero }, 20000)).toBe(445);
    const estimate = feeEstimate(base, ratesOf({ deposit: 0, payout: 0 }), 20000, 0);
    expect(estimate.operators).toEqual([
      expect.objectContaining({ provider: "MTN_MOMO_CMR", fee: 445, studentPays: 20445 }),
      expect.objectContaining({ provider: "ORANGE_CMR", fee: 445, studentPays: 20445 }),
    ]);
  });

  it("is 662 with MTN at 0.75% in and 0.30% out", () => {
    expect(serviceFee(base, { deposit: { percent: 0.75, fixed: 0 }, payout: { percent: 0.3, fixed: 0 } }, 20000)).toBe(662);
  });

  it("does not round a franc up when the result is exact (ADR 0029: 20,700 gives 21,160)", () => {
    expect(serviceFee(base, { deposit: zero, payout: zero }, 20700)).toBe(460);
    const estimate = feeEstimate({ ...base, charge_semester_xaf: 700 }, ratesOf({ deposit: 0, payout: 0 }), 20000, 700);
    expect(estimate.receipt).toBe(20700);
    expect(estimate.operators[0]).toMatchObject({ studentPays: 21160 });
  });

  it("counts VAT on pawaPay's share, the smallest fee and a fixed part", () => {
    // 1% with 19.25% VAT is 1.1925%.
    expect(serviceFee({ ...base, pawapay_vat_percent: 19.25 }, { deposit: zero, payout: zero }, 20000)).toBe(524);
    expect(serviceFee({ ...base, fee_min_xaf: 600 }, { deposit: zero, payout: zero }, 20000)).toBe(600);
    expect(serviceFee(base, { deposit: { percent: 0, fixed: 99 }, payout: zero }, 20000)).toBe(545);
  });

  it("is the payment's cost only without a payout, and null while a rate is not set", () => {
    expect(serviceFee(base, { deposit: zero, payout: zero }, 20000, false)).toBe(203);
    expect(serviceFee(base, { deposit: { percent: null, fixed: 0 }, payout: zero }, 20000)).toBeNull();
    const estimate = feeEstimate(base, ratesOf({ deposit: 0.75, payout: null }), 20000, 0);
    expect(estimate.operators[0]).toEqual({ provider: "MTN_MOMO_CMR", stopped: true });
  });

  it("charges no fee on top when the platform withholds it, and the school bears the costs", () => {
    const estimate = feeEstimate({ ...base, student_fee_allowed: false }, ratesOf({ deposit: 0, payout: 0 }), 20000, 0);
    expect(estimate.operators[0]).toMatchObject({ studentPays: 20000, fee: 0, transferCost: 400, schoolBears: 400 });
  });

  it("works out a transfer's cost as private.transfer_cost", () => {
    expect(transferCost(base, zero, 20445)).toBe(205);
    expect(transferCost(base, { percent: 0.75, fixed: 0 }, 20000)).toBe(350);
    expect(transferCost(base, { percent: null, fixed: 0 }, 20000)).toBeNull();
  });
});

describe("walletGap", () => {
  it("flags a gap above 1% of the books or above 5,000 XAF", () => {
    expect(walletGap({ balance: 1_000_000, book: 1_000_000 })).toEqual({ gap: 0, flagged: false });
    expect(walletGap({ balance: 1_004_000, book: 1_000_000 })).toEqual({ gap: 4000, flagged: false });
    expect(walletGap({ balance: 994_000, book: 1_000_000 })).toEqual({ gap: -6000, flagged: true });
    // A small book: 1% of 100,000 is 1,000.
    expect(walletGap({ balance: 101_500, book: 100_000 }).flagged).toBe(true);
    expect(walletGap({ balance: 100_900, book: 100_000 }).flagged).toBe(false);
    expect(walletGap({ balance: 0, book: 0 }).flagged).toBe(false);
  });
});

describe("parsing the overview and the alerts", () => {
  it("reads the overview defensively", () => {
    const parsed = parsePlatformPayments({
      months: [{ month: "2026-11-01", volume: 100, fees: "5", margin: -3 }, { volume: 1 }],
      held_for_schools: 20,
      wallet: { balance_xaf: 10, book_xaf: 9, taken_at: "2026-11-17T06:00:00Z" },
      top_schools: [{ id: "00000000-0000-4000-8000-000000000001", name: "ICT", volume: 7, payments: 1 }, { id: "x" }],
      operators: [{ provider: "MTN_MOMO_CMR", completed: 3, failed: 1, failure_rate: 0.25, top_failure: "PAYER_NOT_FOUND" }],
    });
    expect(parsed.months).toHaveLength(1);
    expect(parsed.months[0]).toMatchObject({ month: "2026-11-01", volume: 100, fees: 5, margin: -3, infra: 0 });
    expect(parsed.wallet).toEqual({ balance: 10, book: 9, takenAt: "2026-11-17T06:00:00Z" });
    expect(parsed.topSchools).toHaveLength(1);
    expect(parsed.operators[0]).toEqual({ provider: "MTN_MOMO_CMR", completed: 3, failed: 1, failureRate: 0.25, topFailure: "PAYER_NOT_FOUND" });
    expect(parsePlatformPayments(null)).toMatchObject({ months: [], wallet: null, owedBySchools: 0 });
  });

  it("finds this month and last month", () => {
    const parsed = parsePlatformPayments({ months: [{ month: "2026-10-01", margin: 1 }, { month: "2026-11-01", margin: 2 }] });
    const { current, previous } = currentMonths(parsed.months, new Date("2026-11-17T10:00:00Z"));
    expect(current?.margin).toBe(2);
    expect(previous?.margin).toBe(1);
    expect(currentMonths(parsed.months, new Date("2027-01-02T00:00:00Z"))).toEqual({ current: null, previous: null });
  });

  it("keeps known alert kinds only", () => {
    const school = "00000000-0000-4000-8000-000000000001";
    const id = "00000000-0000-4000-8000-0000000000aa";
    const alerts = parseAlerts([
      { kind: "payout_account", id, school_id: school, school_name: "ICT", amount_xaf: null, status: "proposed", code: "MTN_MOMO_CMR", at: "2026-11-17T06:00:00Z" },
      { kind: "other", id, school_id: school },
    ]);
    expect(alerts).toEqual([{ kind: "payout_account", id, schoolId: school, schoolName: "ICT", amount: null, status: "proposed", code: "MTN_MOMO_CMR", at: "2026-11-17T06:00:00Z" }]);
  });
});

describe("the settings form", () => {
  const form = (values: Record<string, string>) => {
    const data = new FormData();
    for (const [key, value] of Object.entries(values)) data.set(key, value);
    return data;
  };
  const valid = {
    pawapay_percent: "1",
    pawapay_vat_percent: "0",
    fee_buffer_percent: "0,2",
    fee_min_xaf: "0",
    student_fee_allowed: "on",
    hold_days: "7",
    payout_min_xaf: "5 000",
    charge_semester_xaf: "700",
    charge_month_xaf: "0",
    max_starts_per_hour: "6",
    [rateField("MTN_MOMO_CMR", "deposit", "percent")]: "0.75",
    [rateField("ORANGE_CMR", "payout", "percent")]: "",
  };

  it("reads decimals and whole numbers as typed in English or French", () => {
    expect(parseDecimal("1,5")).toBe(1.5);
    expect(parseDecimal("0.75 %")).toBe(0.75);
    expect(parseDecimal("1.234")).toBeNull();
    expect(parseDecimal("-1")).toBeNull();
    expect(parseWhole("20 000")).toBe(20000);
    expect(parseWhole("20,000")).toBe(20000);
    expect(parseWhole("1.5")).toBeNull();
    expect(parseWhole("abc")).toBeNull();
  });

  it("reads every setting and rate, an empty rate as not set", () => {
    const parsed = parseSettingsForm(form(valid));
    expect(parsed.ok).toBe(true);
    if (!parsed.ok) return;
    expect(parsed.value.settings).toMatchObject({ fee_buffer_percent: 0.2, payout_min_xaf: 5000, charge_semester_xaf: 700, student_fee_allowed: true });
    expect(parsed.value.rates.find((r) => r.provider === "MTN_MOMO_CMR" && r.operation === "deposit")).toEqual({ provider: "MTN_MOMO_CMR", operation: "deposit", percent: 0.75, fixed: 0 });
    expect(parsed.value.rates.find((r) => r.provider === "ORANGE_CMR" && r.operation === "payout")?.percent).toBeNull();
    const off = parseSettingsForm(form({ ...valid, student_fee_allowed: "" }));
    expect(off.ok && off.value.settings.student_fee_allowed).toBe(false);
  });

  it("refuses a value out of range and names the field", () => {
    expect(parseSettingsForm(form({ ...valid, pawapay_percent: "25" }))).toEqual({ ok: false, field: "pawapay_percent" });
    expect(parseSettingsForm(form({ ...valid, hold_days: "61" }))).toEqual({ ok: false, field: "hold_days" });
    expect(parseSettingsForm(form({ ...valid, max_starts_per_hour: "0" }))).toEqual({ ok: false, field: "max_starts_per_hour" });
    expect(parseSettingsForm(form({ ...valid, fee_min_xaf: "" }))).toEqual({ ok: false, field: "fee_min_xaf" });
    const rate = rateField("MTN_MOMO_CMR", "payout", "percent");
    expect(parseSettingsForm(form({ ...valid, [rate]: "21" }))).toEqual({ ok: false, field: rate });
  });

  it("sends only what changed", () => {
    const current = parseSettings({ ...base, rates: ratesOf({ deposit: 0, payout: 0 }).map((r) => ({ provider: r.provider, operation: r.operation, mmo_percent: r.percent, mmo_fixed_xaf: r.fixed })) });
    const parsed = parseSettingsForm(form(valid));
    if (!parsed.ok) throw new Error("valid form");
    const changes = settingsChanges(current, parsed.value);
    expect(changes.settings).toEqual({ charge_semester_xaf: 700 });
    expect(changes.rates.map((r) => `${r.provider} ${r.operation} ${r.percent}`).sort()).toEqual([
      "MTN_MOMO_CMR deposit 0.75",
      "MTN_MOMO_CMR payout null",
      "MTN_MOMO_CMR refund null",
      "ORANGE_CMR deposit null",
      "ORANGE_CMR payout null",
      "ORANGE_CMR refund null",
    ]);
  });
});

describe("a school's payments", () => {
  const school = "00000000-0000-4000-8000-000000000001";

  it("reads the answer", () => {
    const parsed = parseSchoolPayments({
      terms: { enabled: true, charges_from: "2026-12-01", charge_semester_xaf: null, charge_month_xaf: 300 },
      fees_paid_by: "school",
      balance: { available_xaf: 10, on_hold_xaf: 5, owed_xaf: 0 },
      payout_account: { id: school, status: "proposed", provider: "ORANGE_CMR", phone_masked: "2376*****456" },
      collected_30d: 1000,
      open_issues: 2,
    });
    expect(parsed).toMatchObject({
      terms: { enabled: true, chargesFrom: "2026-12-01", chargeSemester: null, chargeMonth: 300 },
      feesPaidBy: "school",
      balance: { available: 10, onHold: 5, owed: 0 },
      payoutAccount: { status: "proposed", phoneMasked: "2376*****456" },
      collected30d: 1000,
      openIssues: 2,
    });
    expect(parseSchoolPayments(null)).toBeNull();
    expect(parseSchoolPayments({})?.terms).toBeNull();
  });

  it("reads the terms form", () => {
    const data = new FormData();
    data.set("school", school);
    data.set("enabled", "on");
    data.set("charges_from", "2026-12-01");
    data.set("charge_semester_xaf", "");
    data.set("charge_month_xaf", "300");
    expect(parseSchoolTerms(data)).toEqual({ ok: true, value: { school, enabled: true, chargesFrom: "2026-12-01", chargeSemester: null, chargeMonth: 300 } });
    data.set("charges_from", "2026-02-30");
    expect(parseSchoolTerms(data)).toEqual({ ok: false, error: "bad_date" });
    data.set("charges_from", "");
    data.set("charge_month_xaf", "-3");
    expect(parseSchoolTerms(data)).toEqual({ ok: false, error: "bad_charge" });
    data.set("school", "nope");
    expect(parseSchoolTerms(data)).toEqual({ ok: false, error: "not_found" });
  });
});

describe("infrastructure costs and the wallet", () => {
  it("groups costs by month with a total, newest first", () => {
    const groups = costsByMonth([
      { id: "a", month: "2026-10-01", label: "Supabase", amount: 15000, note: null },
      { id: "b", month: "2026-11-01", label: "Supabase", amount: 15000, note: null },
      { id: "c", month: "2026-11-01", label: "Vercel", amount: 12000, note: null },
    ]);
    expect(groups.map((g) => [g.month, g.total, g.costs.length])).toEqual([
      ["2026-11-01", 27000, 2],
      ["2026-10-01", 15000, 1],
    ]);
  });

  it("offers this month and the eleven before it", () => {
    const months = costMonths(new Date("2026-02-10T00:00:00Z"));
    expect(months).toHaveLength(12);
    expect(months[0]).toBe("2026-02-01");
    expect(months[2]).toBe("2025-12-01");
  });

  it("reads a cost and a wallet movement", () => {
    const cost = new FormData();
    cost.set("month", "2026-11-01");
    cost.set("label", "  Supabase   Pro ");
    cost.set("amount", "15 000");
    expect(parseInfraCost(cost)).toEqual({ ok: true, value: { month: "2026-11-01", label: "Supabase Pro", amount: 15000, note: null } });
    cost.set("amount", "0");
    expect(parseInfraCost(cost)).toEqual({ ok: false, error: "bad_amount" });
    cost.set("month", "2026-11-15");
    expect(parseInfraCost(cost)).toEqual({ ok: false, error: "bad_month" });

    const move = new FormData();
    move.set("kind", "withdrawal");
    move.set("amount", "250000");
    move.set("note", "To the bank");
    expect(parseWalletMovement(move)).toEqual({ ok: true, value: { kind: "withdrawal", amount: 250000, note: "To the bank" } });
    move.set("kind", "gift");
    expect(parseWalletMovement(move)).toEqual({ ok: false, error: "bad_kind" });
  });

  it("maps refusals to messages", () => {
    expect(platformPaymentErrorKey("42501", "Platform admins only")).toBe("not_allowed");
    expect(platformPaymentErrorKey("22023", "bad_cost")).toBe("bad_cost");
    expect(platformPaymentErrorKey("55000", "not_proposed")).toBe("not_proposed");
    expect(platformPaymentErrorKey("P0002", "something")).toBe("not_found");
    expect(platformPaymentErrorKey("XX000", "boom")).toBe("generic");
  });
});
