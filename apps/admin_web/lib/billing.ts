/**
 * School billing in the portal (ADR 0022): what a school can choose, how a price splits into installments, and reading
 * the Billing form. The database checks everything again; this is for clear messages and the preview.
 */

export const BILLING_PERIODS = ["semester", "month"] as const;
export type BillingPeriod = (typeof BILLING_PERIODS)[number];

export const INSTALLMENT_PLANS = ["50-50", "40-30-30", "30-60-10"] as const;
export type InstallmentPlan = (typeof INSTALLMENT_PLANS)[number];

export const MAX_PRICE = 10_000_000;

export function isBillingPeriod(value: unknown): value is BillingPeriod {
  return typeof value === "string" && (BILLING_PERIODS as readonly string[]).includes(value);
}

export function isInstallmentPlan(value: unknown): value is InstallmentPlan {
  return typeof value === "string" && (INSTALLMENT_PLANS as readonly string[]).includes(value);
}

/** The shares of a plan, in percent, part by part. */
export function planPercents(plan: InstallmentPlan): number[] {
  return plan.split("-").map(Number);
}

/** Each part's amount: rounded down, the last taking what is left, so they add up exactly (as the database does). */
export function splitAmount(total: number, plan: InstallmentPlan): number[] {
  const percents = planPercents(plan);
  const parts = percents.slice(0, -1).map((percent) => Math.floor((total * percent) / 100));
  return [...parts, total - parts.reduce((sum, part) => sum + part, 0)];
}

/** An amount in whole units, as people write it in that language: "30,000 XAF", "30 000 XAF". */
export function formatAmount(amount: number, locale: string, currency = "XAF"): string {
  return `${new Intl.NumberFormat(locale, { maximumFractionDigits: 0 }).format(amount)} ${currency}`;
}

export type BillingForm = { period: BillingPeriod; price: number; plan: InstallmentPlan | null };
export type BillingField = "period" | "price" | "plan";

/** Reads the Billing form. "full" means no installments; a month is always paid in full. */
export function parseBillingForm(formData: FormData): { ok: true; value: BillingForm } | { ok: false; field: BillingField } {
  const period = formData.get("period");
  if (!isBillingPeriod(period)) return { ok: false, field: "period" };
  const rawPrice = String(formData.get("price") ?? "").replace(/[\s,.  ]/g, "");
  if (!/^\d+$/.test(rawPrice)) return { ok: false, field: "price" };
  const price = Number(rawPrice);
  if (price <= 0 || price > MAX_PRICE) return { ok: false, field: "price" };
  const payment = formData.get("payment");
  if (payment === "full" || payment === null) return { ok: true, value: { period, price, plan: null } };
  if (!isInstallmentPlan(payment)) return { ok: false, field: "plan" };
  if (period !== "semester") return { ok: false, field: "plan" };
  return { ok: true, value: { period, price, plan: payment } };
}

/** Maps the database's answer to `admin_set_billing` to a form field, or a general problem. */
export function billingSaveError(message: string | undefined): BillingField | "generic" {
  if (message === "invalid_period") return "period";
  if (message === "invalid_price") return "price";
  if (message === "invalid_plan") return "plan";
  return "generic";
}

/** The school's billing as stored, or null while it is not set. */
export type SchoolBilling = { period: BillingPeriod; price: number; plan: InstallmentPlan | null; currency: string };

export function schoolBilling(row: { billing_period: string | null; price_xaf: number | null; installment_plan: string | null; currency: string } | null): SchoolBilling | null {
  if (!row || !isBillingPeriod(row.billing_period) || row.price_xaf === null) return null;
  return { period: row.billing_period, price: row.price_xaf, plan: isInstallmentPlan(row.installment_plan) ? row.installment_plan : null, currency: row.currency };
}

export const INSTALLMENT_STATUSES = ["due", "submitted", "paid", "rejected"] as const;
export type InstallmentStatus = (typeof INSTALLMENT_STATUSES)[number];

export type InstallmentRow = { id: string; seq: number; percent: number; amount_xaf: number; due_date: string; status: string; proof_path: string | null; review_note: string | null };

/** What needs the school's eye on a subscription paid in parts: the first part waiting to be checked, else the first late one. */
export function partsAttention(parts: Pick<InstallmentRow, "seq" | "status" | "due_date">[], today: string): { seq: number; kind: "toCheck" | "overdue" } | null {
  const ordered = [...parts].sort((a, b) => a.seq - b.seq);
  const toCheck = ordered.find((p) => p.seq > 1 && p.status === "submitted");
  if (toCheck) return { seq: toCheck.seq, kind: "toCheck" };
  const late = ordered.find((p) => p.seq > 1 && (p.status === "due" || p.status === "rejected") && p.due_date <= today);
  return late ? { seq: late.seq, kind: "overdue" } : null;
}

/** Maps the database's answer to `admin_review_installment`. */
export function installmentErrorKey(code: string | undefined, message?: string): "not_open" | "not_found" | "generic" {
  if (code === "55000" && message === "installment_not_open") return "not_open";
  if (code === "P0002") return "not_found";
  return "generic";
}
