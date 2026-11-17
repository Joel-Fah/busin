/**
 * The school's payments in the portal (ADR 0029): where each payment and refund stands, the summary the database
 * returns, whether the school can be paid out on Monday, the ledger as CSV, and reading the payment forms. Pure, so each
 * rule is a unit test. The database decides everything again; this is for clear words and early messages.
 */
import type { ChipTone } from "@/components/ui/Chip";

import { isUuid } from "./ids";
import { first, parsePageSize, sizeParam } from "./pagination";
import { checkReason, type ReasonProblem } from "./reasons";
import { isProvider, normalizeCameroonPhone, type Provider } from "./student/mobile-money";

export { PROVIDERS, guessOperator, isProvider, normalizeCameroonPhone, type Provider } from "./student/mobile-money";

/** The longest reason or note the database keeps (`private.clean_reason`). */
export const MAX_NOTE = 500;
/** The highest amount a form accepts, as the billing price. */
export const MAX_AMOUNT = 10_000_000;
/** The platform's defaults, used only when the summary does not carry its own (`payment_settings`). */
export const PAYOUT_MIN_XAF = 5000;
export const HOLD_DAYS = 7;

/** What a payments form's server action answers: done (with what happened) or the problem, as a message key. */
export type PaymentActionState = { ok: true; done: string } | { ok: false; error: string } | null;

// ---------------------------------------------------------------- payments and refunds

/** A payment pawaPay may still finish, or one set aside for the platform to look at. */
export const OPEN_PAYMENT_STATUSES = ["initiated", "accepted", "processing", "in_reconciliation", "needs_attention"] as const;

export function isOpenPayment(status: string): boolean {
  return (OPEN_PAYMENT_STATUSES as readonly string[]).includes(status);
}

/** A refund that took money back from the school (sent, being sent or done): not asked, declined or failed. */
export const TAKEN_REFUND_STATUSES = ["queued", "accepted", "processing", "in_reconciliation", "completed", "needs_attention"] as const;

export const PAYMENT_FILTERS = ["all", "paid", "waiting", "failed", "refunded"] as const;
export type PaymentFilter = (typeof PAYMENT_FILTERS)[number];
export type PaymentStage = Exclude<PaymentFilter, "all">;

export function parsePaymentFilter(value: string | string[] | undefined): PaymentFilter {
  const v = first(value);
  return (PAYMENT_FILTERS as readonly string[]).includes(v ?? "") ? (v as PaymentFilter) : "all";
}

/**
 * Where a payment stands for the school: paid, still waiting (on the payer's phone, or with BusIn), failed, or refunded
 * (BusIn could not use it, or the school sent money back). Each payment is in exactly one group.
 */
export function paymentStage(payment: { status: string; outcome: string | null }, refunds: readonly { status: string }[] = []): PaymentStage {
  if (payment.status === "failed") return "failed";
  if (payment.status !== "completed") return "waiting";
  if (payment.outcome === "refunded" || refunds.some((r) => (TAKEN_REFUND_STATUSES as readonly string[]).includes(r.status))) return "refunded";
  return "paid";
}

export function stageTone(stage: PaymentStage): ChipTone {
  return stage === "paid" ? "ok" : stage === "waiting" ? "warn" : stage === "failed" ? "bad" : "info";
}

export type RefundGroup = "requested" | "declined" | "sending" | "refunded" | "failed";

/** A refund's status in the words the school reads. */
export function refundGroup(status: string): RefundGroup {
  if (status === "requested") return "requested";
  if (status === "declined") return "declined";
  if (status === "completed") return "refunded";
  if (status === "failed") return "failed";
  return "sending";
}

export function refundTone(group: RefundGroup): ChipTone {
  return group === "requested" ? "warn" : group === "refunded" ? "ok" : group === "failed" ? "bad" : group === "sending" ? "info" : "neutral";
}

/** Whether the school can refund a payment itself, as `private.refundable` decides: applied, not an invoice, no live refund. */
export function canRefund(payment: { status: string; outcome: string | null; purpose: string }, refunds: readonly { status: string }[]): boolean {
  return (
    payment.status === "completed" &&
    payment.outcome === "applied" &&
    payment.purpose !== "invoice" &&
    !refunds.some((r) => r.status !== "declined" && r.status !== "failed")
  );
}

/** A payout's status in words. */
export function payoutGroup(status: string): "sent" | "sending" | "failed" {
  if (status === "completed") return "sent";
  if (status === "failed") return "failed";
  return "sending";
}

export type PaymentsQuery = { status: PaymentFilter; size?: number };

/** The Payments page with a list filter, page and size; anchored on the list so a change lands on it. */
export function paymentsHref(query: PaymentsQuery, page = 1): string {
  const params = new URLSearchParams();
  if (query.status !== "all") params.set("status", query.status);
  if (page > 1) params.set("page", String(page));
  const size = sizeParam(query.size);
  if (size) params.set("size", String(size));
  const search = params.toString();
  return `/payments${search ? `?${search}` : ""}#payments-list`;
}

export function parsePaymentsQuery(query: { status?: string | string[]; size?: string | string[] }): PaymentsQuery {
  const size = parsePageSize(query.size);
  return { status: parsePaymentFilter(query.status), size };
}

// ---------------------------------------------------------------- the summary

export type MonthFigures = { month: string; mobile_money: number; receipts: number; refunds: number; charges: number; payouts: number; transfer_costs: number };

export type PaymentSummary = {
  balance: { available: number; onHold: number; owed: number };
  feesPaidBy: "student" | "school";
  mobileMoney: boolean;
  months: MonthFigures[];
  payoutAccount: { provider: string; phoneMasked: string; accountName: string | null; usableFrom: string | null } | null;
  refundsWaiting: number;
  openInvoice: { id: string; number: string; amount: number; dueDate: string } | null;
  /** The platform's rules, as the summary gives them: the hold, the smallest payout, the next payouts (an ISO time). */
  holdDays: number;
  payoutMin: number;
  nextPayoutAt: string | null;
};

const num = (value: unknown): number => {
  const n = typeof value === "number" ? value : typeof value === "string" ? Number(value) : NaN;
  return Number.isFinite(n) ? Math.round(n) : 0;
};
const str = (value: unknown): string | null => (typeof value === "string" && value !== "" ? value : null);
const obj = (value: unknown): Record<string, unknown> | null => (value && typeof value === "object" && !Array.isArray(value) ? (value as Record<string, unknown>) : null);

/** Reads `admin_payment_summary`'s answer defensively: anything missing is zero or nothing. */
export function parseSummary(json: unknown): PaymentSummary {
  const root = obj(json) ?? {};
  const balance = obj(root.balance) ?? {};
  const account = obj(root.payout_account);
  const invoice = obj(root.open_invoice);
  const months = Array.isArray(root.months) ? root.months : [];
  return {
    balance: { available: num(balance.available_xaf), onHold: num(balance.on_hold_xaf), owed: num(balance.owed_xaf) },
    feesPaidBy: root.fees_paid_by === "school" ? "school" : "student",
    holdDays: typeof root.hold_days === "number" ? root.hold_days : HOLD_DAYS,
    payoutMin: typeof root.payout_min_xaf === "number" ? root.payout_min_xaf : PAYOUT_MIN_XAF,
    nextPayoutAt: str(root.next_payout_at),
    mobileMoney: root.mobile_money === true,
    months: months.flatMap((m) => {
      const row = obj(m);
      const month = str(row?.month);
      if (!row || !month) return [];
      return [
        {
          month: month.slice(0, 10),
          mobile_money: num(row.mobile_money),
          receipts: num(row.receipts),
          refunds: num(row.refunds),
          charges: num(row.charges),
          payouts: num(row.payouts),
          transfer_costs: num(row.transfer_costs),
        },
      ];
    }),
    payoutAccount:
      account && str(account.provider)
        ? { provider: String(account.provider), phoneMasked: str(account.phone_masked) ?? "", accountName: str(account.account_name), usableFrom: str(account.usable_from) }
        : null,
    refundsWaiting: num(root.refunds_waiting),
    openInvoice:
      invoice && str(invoice.id)
        ? { id: String(invoice.id), number: str(invoice.number) ?? "", amount: num(invoice.amount_xaf), dueDate: (str(invoice.due_date) ?? "").slice(0, 10) }
        : null,
  };
}

export const MONTH_COLUMNS = ["mobile_money", "receipts", "refunds", "charges", "payouts", "transfer_costs"] as const;
export type MonthColumn = (typeof MONTH_COLUMNS)[number];

/** The columns worth showing: transfer costs only when the school bears them or some were taken. */
export function monthColumns(months: readonly MonthFigures[], feesPaidBy: "student" | "school"): MonthColumn[] {
  const anyCosts = months.some((m) => m.transfer_costs !== 0);
  return MONTH_COLUMNS.filter((c) => c !== "transfer_costs" || feesPaidBy === "school" || anyCosts);
}

/** A bar's length in percent of the largest figure (at least a sliver for anything above zero). */
export function barPercent(value: number, max: number): number {
  if (value <= 0 || max <= 0) return 0;
  return Math.max(2, Math.round((value / max) * 1000) / 10);
}

// ---------------------------------------------------------------- payouts

/** The day (YYYY-MM-DD, UTC) of the next weekly payout run: Monday 06:00 UTC, today when it is Monday before then. */
export function nextPayoutDay(now: Date): string {
  const day = now.getUTCDay();
  let add = (8 - day) % 7;
  if (add === 0 && now.getUTCHours() >= 6) add = 7;
  const next = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + add));
  return next.toISOString().slice(0, 10);
}

export type PayoutReadiness =
  | { kind: "off" }
  | { kind: "noNumber" }
  | { kind: "waitingConfirmation" }
  | { kind: "usableFrom"; date: string }
  | { kind: "belowMin"; available: number; min: number }
  | { kind: "ready"; day: string; amount: number; provider: string; phone: string };

/**
 * Whether Monday's payout will go out, and if not, what is missing: mobile money not switched on, no number, a number
 * waiting for a second administrator, a replacement number still in its 7 days, or a balance under the minimum.
 */
export function payoutReadiness(
  summary: Pick<PaymentSummary, "mobileMoney" | "payoutAccount" | "balance"> & Partial<Pick<PaymentSummary, "payoutMin" | "nextPayoutAt">>,
  proposalWaiting: boolean,
  now: Date,
  min = summary.payoutMin ?? PAYOUT_MIN_XAF,
): PayoutReadiness {
  if (!summary.mobileMoney) return { kind: "off" };
  const account = summary.payoutAccount;
  if (!account) return proposalWaiting ? { kind: "waitingConfirmation" } : { kind: "noNumber" };
  if (account.usableFrom && Date.parse(account.usableFrom) > now.getTime()) return { kind: "usableFrom", date: account.usableFrom };
  const floor = Math.max(min, 1);
  if (summary.balance.available < floor) return { kind: "belowMin", available: summary.balance.available, min: floor };
  // The server says when the payouts run; worked out here only for an older answer without it.
  const day = summary.nextPayoutAt ? new Date(summary.nextPayoutAt).toISOString().slice(0, 10) : nextPayoutDay(now);
  return { kind: "ready", day, amount: summary.balance.available, provider: account.provider, phone: account.phoneMasked };
}

/** A number as the server masks it: the first four digits, five stars, the last three ("2376*****456"), with its plus. */
export function maskPhone(phone: string | null | undefined): string {
  const digits = (phone ?? "").replace(/[^0-9]/g, "");
  if (digits.length < 8) return "";
  return `+${digits.slice(0, 4)}*****${digits.slice(-3)}`;
}

/** A masked number from the database, with its plus. */
export function showMasked(masked: string | null | undefined): string {
  if (!masked) return "";
  return masked.startsWith("+") ? masked : `+${masked}`;
}

// ---------------------------------------------------------------- forms

/** A whole amount in francs as typed ("5 000", "5,000"), or null when it is not one between 1 and the maximum. */
export function parseAmount(raw: unknown, max = MAX_AMOUNT): number | null {
  if (typeof raw !== "string" && typeof raw !== "number") return null;
  const text = String(raw).replace(/[\s,.  ]/g, "");
  if (!/^\d{1,9}$/.test(text)) return null;
  const n = Number(text);
  return n >= 1 && n <= max ? n : null;
}

export type FeesPaidBy = "student" | "school";

export function isFeesPaidBy(value: unknown): value is FeesPaidBy {
  return value === "student" || value === "school";
}

export type RefundDecision = { refund: string; approve: boolean; amount: number | null; note: string | null };
export type RefundFormError = "not_found" | "bad_amount" | "bad_decision" | ReasonProblem;

/** Reads the decision on a student's refund request: all of it, part of it (an amount), or declined (a reason). */
export function parseRefundDecision(formData: FormData): { ok: true; value: RefundDecision } | { ok: false; error: RefundFormError } {
  const refund = formData.get("refund");
  if (!isUuid(refund)) return { ok: false, error: "not_found" };
  const decision = formData.get("decision");
  if (decision === "all") return { ok: true, value: { refund, approve: true, amount: null, note: null } };
  if (decision === "part") {
    const amount = parseAmount(formData.get("amount"));
    if (amount === null) return { ok: false, error: "bad_amount" };
    return { ok: true, value: { refund, approve: true, amount, note: null } };
  }
  if (decision === "decline") {
    const checked = checkReason(formData.get("note"), { required: true, max: MAX_NOTE });
    if (!checked.ok) return { ok: false, error: checked.problem };
    return { ok: true, value: { refund, approve: false, amount: null, note: checked.value } };
  }
  return { ok: false, error: "bad_decision" };
}

/** Reads a refund the school starts itself: the payment, how much, and why (the student reads it). */
export function parseSchoolRefund(formData: FormData): { ok: true; value: { payment: string; amount: number; reason: string } } | { ok: false; error: RefundFormError } {
  const payment = formData.get("payment");
  if (!isUuid(payment)) return { ok: false, error: "not_found" };
  const amount = parseAmount(formData.get("amount"));
  if (amount === null) return { ok: false, error: "bad_amount" };
  const checked = checkReason(formData.get("note"), { required: true, max: MAX_NOTE });
  if (!checked.ok) return { ok: false, error: checked.problem };
  return { ok: true, value: { payment, amount, reason: checked.value ?? "" } };
}

/** Maps the database's refusal of a refund decision or a school refund to a message key. */
export function refundErrorKey(code: string | undefined, message: string | undefined): RefundFormError | "not_requested" | "not_refundable" | "generic" {
  if (message === "not_requested" || message === "not_refundable" || message === "bad_amount") return message;
  if (message === "reason_required" || message === "reason_too_short" || message === "reason_too_long") return message;
  if (code === "P0002") return "not_found";
  return "generic";
}

export type PayoutProposal = { provider: Provider; phone: string; name: string };
export type PayoutFormError = "bad_provider" | "bad_phone" | "bad_name";

/** Reads a proposed payout number: the operator, a Cameroonian mobile number and the name the operator holds for it. */
export function parsePayoutProposal(formData: FormData): { ok: true; value: PayoutProposal } | { ok: false; error: PayoutFormError } {
  const provider = formData.get("provider");
  if (!isProvider(provider)) return { ok: false, error: "bad_provider" };
  const rawPhone = formData.get("phone");
  const phone = typeof rawPhone === "string" && rawPhone.length <= 40 ? normalizeCameroonPhone(rawPhone) : null;
  if (!phone) return { ok: false, error: "bad_phone" };
  const rawName = formData.get("name");
  const name = typeof rawName === "string" ? rawName.replace(/\s+/g, " ").trim() : "";
  if (name.length < 2 || name.length > 120) return { ok: false, error: "bad_name" };
  return { ok: true, value: { provider, phone, name } };
}

/** Maps the database's refusal of a payout number change to a message key. */
export function payoutErrorKey(code: string | undefined, message: string | undefined): PayoutFormError | "same_admin" | "not_proposed" | "not_found" | "generic" {
  if (message === "bad_provider" || message === "bad_phone" || message === "bad_name" || message === "same_admin" || message === "not_proposed") return message;
  if (code === "P0002") return "not_found";
  return "generic";
}

// ---------------------------------------------------------------- the ledger as CSV

/** Written first so Excel reads the file as UTF-8 (accents in names and notes). */
export const CSV_BOM = "﻿";

/**
 * One CSV cell. Text that starts like a formula (= + - @, or a tab or carriage return) gets a leading apostrophe so a
 * spreadsheet shows it instead of running it; a cell with a quote, a comma or a line break is quoted, quotes doubled.
 * Numbers are written as they are: a number cannot be a formula, and -5000 must stay a number.
 */
export function csvCell(value: string | number | null | undefined): string {
  if (value === null || value === undefined) return "";
  if (typeof value === "number") return Number.isFinite(value) ? String(value) : "";
  let text = value;
  if (/^[=+\-@\t\r]/.test(text)) text = `'${text}`;
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

/** A CSV line, ended the way spreadsheets expect. */
export function csvRow(cells: readonly (string | number | null | undefined)[]): string {
  return `${cells.map(csvCell).join(",")}\r\n`;
}

/** The export's file name: the school's name in plain letters and the day, e.g. busin-ledger-ict-university-2026-11-17.csv. */
export function ledgerFileName(schoolName: string, day: string): string {
  const slug =
    schoolName
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 60)
      .replace(/-+$/g, "") || "school";
  return `busin-ledger-${slug}-${day}.csv`;
}

export const LEDGER_KINDS = [
  "payment",
  "transaction_fee",
  "refund",
  "refund_fee",
  "refund_reversal",
  "charge",
  "payout",
  "payout_reversal",
  "invoice_payment",
  "reversal",
  "adjustment",
] as const;
export type LedgerKind = (typeof LEDGER_KINDS)[number];

export function isLedgerKind(value: unknown): value is LedgerKind {
  return typeof value === "string" && (LEDGER_KINDS as readonly string[]).includes(value);
}
