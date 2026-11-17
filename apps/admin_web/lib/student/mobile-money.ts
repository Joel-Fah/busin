/**
 * Paying by mobile money in the student web app (ADR 0029): the number and its operator, what the payments function and
 * pawaPay answer, and where a payment stands. Pure, so each rule is a unit test. The number rules mirror the server's
 * (supabase/functions/_shared/pawapay.ts and start_payment): keep them in step.
 */
export type Provider = "MTN_MOMO_CMR" | "ORANGE_CMR";
export const PROVIDERS: readonly Provider[] = ["MTN_MOMO_CMR", "ORANGE_CMR"];

export function isProvider(value: unknown): value is Provider {
  return typeof value === "string" && (PROVIDERS as readonly string[]).includes(value);
}

/** Digits only, without a leading 00. */
function digitsOf(input: string): string {
  const digits = input.replace(/[^0-9]/g, "");
  return digits.startsWith("00") ? digits.slice(2) : digits;
}

/**
 * A Cameroonian mobile number as pawaPay takes it (2376XXXXXXXX), from what was typed ("6 77 12 34 56",
 * "+237 677123456", "00237677123456"); null when it is not one.
 */
export function normalizeCameroonPhone(input: string): string | null {
  let digits = digitsOf(input);
  if (digits.length === 9) digits = `237${digits}`;
  return /^2376[0-9]{8}$/.test(digits) ? digits : null;
}

/** The local digits typed so far (the 237 country code dropped), for guessing the operator while typing. */
export function localDigits(input: string): string {
  const digits = digitsOf(input);
  // A Cameroonian mobile number starts with 6, never 2: a leading 237 is the country code.
  return digits.startsWith("237") ? digits.slice(3) : digits;
}

const MTN_PREFIXES = ["650", "651", "652", "653", "654", "67", "680", "681", "682", "683"];
const ORANGE_PREFIXES = ["655", "656", "657", "658", "659", "69"];

/**
 * The operator a number most likely belongs to, from its first local digits, as it is typed; null while it cannot be
 * told (too few digits, or a range of neither). A guess only: numbers move between operators, so the server asks
 * pawaPay, and the student may change it.
 */
export function guessOperator(input: string): Provider | null {
  const local = localDigits(input);
  if (MTN_PREFIXES.some((p) => local.startsWith(p))) return "MTN_MOMO_CMR";
  if (ORANGE_PREFIXES.some((p) => local.startsWith(p))) return "ORANGE_CMR";
  return null;
}

/** What the number field says under it: nothing while typing, or that it is not a Cameroonian mobile number. */
export function phoneProblem(input: string): "empty" | "invalid" | null {
  if (!input.trim()) return "empty";
  return normalizeCameroonPhone(input) ? null : "invalid";
}

/** The profile's number (E.164) to fill the field with, written the local way, when it is a Cameroonian mobile one. */
export function prefillPhone(profilePhone: string | null | undefined): string {
  // Only a number saved with its country code 237: a 9-digit number of another country is not one.
  if (!profilePhone || !profilePhone.replace(/[^0-9]/g, "").startsWith("237")) return "";
  const msisdn = normalizeCameroonPhone(profilePhone);
  if (!msisdn) return "";
  const local = msisdn.slice(3);
  return `${local.slice(0, 1)} ${local.slice(1, 3)} ${local.slice(3, 5)} ${local.slice(5, 7)} ${local.slice(7, 9)}`;
}

/** The masked number the server keeps ("2376*****456"), with its plus. */
export function maskedDisplay(masked: string | null | undefined): string {
  if (!masked) return "";
  return masked.startsWith("+") ? masked : `+${masked}`;
}

// ---------------------------------------------------------------- where a payment stands

export type PaymentStatus = "initiated" | "accepted" | "processing" | "in_reconciliation" | "completed" | "failed" | "needs_attention";

/** A payment as the student reads it (never failure_message, which is for staff). */
export type PaymentRow = {
  id: string;
  purpose: string;
  subscription_id: string | null;
  installment_id: string | null;
  amount_xaf: number;
  fee_xaf: number;
  total_xaf: number;
  currency: string;
  provider: string;
  payer_masked: string;
  status: string;
  failure_code: string | null;
  provider_txn: string | null;
  receipt_no: string | null;
  outcome: string | null;
  created_at: string;
  completed_at: string | null;
};

/** The columns the student app selects from `payments`. */
export const PAYMENT_COLUMNS = "id, purpose, subscription_id, installment_id, amount_xaf, fee_xaf, total_xaf, currency, provider, payer_masked, status, failure_code, provider_txn, receipt_no, outcome, created_at, completed_at";

const OPEN: readonly string[] = ["initiated", "accepted", "processing", "in_reconciliation"];

/** pawaPay may still finish it: the student is waiting on their phone. */
export function isOpen(status: string): boolean {
  return OPEN.includes(status);
}

export type PaymentStage = "waiting" | "checking" | "paid" | "refunded" | "failed";

/**
 * What the student is shown for a payment: waiting for their PIN, being checked by BusIn (nothing to do), paid, paid
 * and being refunded (the request could no longer take it), or failed.
 */
export function stageOfPayment(payment: Pick<PaymentRow, "status" | "outcome">): PaymentStage {
  if (payment.status === "completed") return payment.outcome === "refunded" ? "refunded" : "paid";
  if (payment.status === "failed") return "failed";
  if (payment.status === "needs_attention") return "checking";
  return "waiting";
}

/** The newest payment of each item (a request, or a part), from a list newest first. */
export function latestByItem(payments: PaymentRow[]): { subscription: Record<string, PaymentRow>; installment: Record<string, PaymentRow> } {
  const subscription: Record<string, PaymentRow> = {};
  const installment: Record<string, PaymentRow> = {};
  const sorted = [...payments].sort((a, b) => b.created_at.localeCompare(a.created_at) || b.id.localeCompare(a.id));
  for (const p of sorted) {
    if (p.purpose === "installment" && p.installment_id) installment[p.installment_id] ??= p;
    else if (p.purpose === "subscription" && p.subscription_id) subscription[p.subscription_id] ??= p;
  }
  return { subscription, installment };
}

/** The completed payments, as receipts, the latest first. */
export function receiptsOf(payments: PaymentRow[]): PaymentRow[] {
  return payments.filter((p) => p.status === "completed" && p.receipt_no).sort((a, b) => (b.completed_at ?? b.created_at).localeCompare(a.completed_at ?? a.created_at));
}

// ---------------------------------------------------------------- what went wrong, in the student's words

export type FailureReason = "notApproved" | "balance" | "payerNotFound" | "limit" | "inProgress" | "operatorDown" | "amount" | "invalidNumber" | "notReached" | "other";

/** pawaPay's failure code of a payment, as one of the reasons the app explains. */
export function failureReason(code: string | null | undefined): FailureReason {
  switch ((code ?? "").toUpperCase()) {
    case "PAYMENT_NOT_APPROVED":
      return "notApproved";
    case "INSUFFICIENT_BALANCE":
      return "balance";
    case "PAYER_NOT_FOUND":
      return "payerNotFound";
    case "PAYER_LIMIT_REACHED":
      return "limit";
    case "PAYMENT_IN_PROGRESS":
      return "inProgress";
    case "PROVIDER_TEMPORARILY_UNAVAILABLE":
      return "operatorDown";
    case "AMOUNT_OUT_OF_BOUNDS":
      return "amount";
    case "INVALID_PHONE_NUMBER":
      return "invalidNumber";
    case "NOT_FOUND":
      return "notReached";
    default:
      return "other";
  }
}

export const START_ERRORS = [
  "bad_phone",
  "unknown_provider",
  "payment_in_progress",
  "too_many_attempts",
  "not_payable",
  "period_ended",
  "mobile_money_off",
  "fees_not_set",
  "not_found",
  "not_allowed",
  "payments_unavailable",
  "offline",
  "payment_error",
] as const;
export type StartError = (typeof START_ERRORS)[number];

export function isStartError(value: unknown): value is StartError {
  return typeof value === "string" && (START_ERRORS as readonly string[]).includes(value);
}

/**
 * What the payments function's answer means, from its HTTP status and body. Its own refusal codes pass through; a
 * server error without a code of its own (the gateway, or the function down) means mobile money is not available now;
 * anything else is a generic error.
 */
export function startErrorOf(status: number, body: unknown): StartError {
  const code = body && typeof body === "object" && "error" in body ? (body as { error: unknown }).error : null;
  if (isStartError(code)) return code;
  if (code === "account_not_verified" || code === "unauthorized") return "not_allowed";
  if (code === "bad_provider") return "unknown_provider";
  if (status === 429) return "too_many_attempts";
  // No code of the function's own: the gateway, or the function down. Mobile money is not available right now.
  if (code === null && status >= 500) return "payments_unavailable";
  return "payment_error";
}

// ---------------------------------------------------------------- prices

export type BreakdownRow = { method: string; student_pays: number };
export type QuoteRow = { provider: string; amount_xaf: number; fee_xaf: number | null; total_xaf: number | null; currency: string };
export type PriceLines = { amount: number; fee: number; total: number };

/** The operators the school takes payments with, from its price breakdown (none: mobile money is not offered). */
export function offeredOperators(breakdown: BreakdownRow[] | null | undefined): Provider[] {
  return PROVIDERS.filter((p) => (breakdown ?? []).some((r) => r.method === p));
}

/** What paying the whole price with an operator comes to, from the breakdown: the price, the fee on top, the total. */
export function linesFromBreakdown(breakdown: BreakdownRow[] | null | undefined, provider: Provider): PriceLines | null {
  const receipt = (breakdown ?? []).find((r) => r.method === "receipt");
  const row = (breakdown ?? []).find((r) => r.method === provider);
  if (!receipt || !row) return null;
  return { amount: receipt.student_pays, fee: Math.max(row.student_pays - receipt.student_pays, 0), total: row.student_pays };
}

/** What the quote says paying an item with an operator comes to; null when that operator is not available. */
export function linesFromQuote(quote: QuoteRow[] | null | undefined, provider: Provider): PriceLines | null {
  const row = (quote ?? []).find((r) => r.provider === provider);
  if (!row || row.fee_xaf === null || row.total_xaf === null) return null;
  return { amount: row.amount_xaf, fee: row.fee_xaf, total: row.total_xaf };
}

/** The price everyone pays by receipt (the school's price, with BusIn's charge when it is passed on). */
export function receiptPrice(breakdown: BreakdownRow[] | null | undefined): number | null {
  return (breakdown ?? []).find((r) => r.method === "receipt")?.student_pays ?? null;
}
