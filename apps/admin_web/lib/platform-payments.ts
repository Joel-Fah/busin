/**
 * The platform console's payments (ADR 0027 and 0029): reading what the `platform_*` payment functions return, the
 * check of pawaPay's wallet against the books, the fee a student pays (the same formula as `private.service_fee`, for an
 * estimate on the settings page), and reading the console's payment forms. Pure, so each rule is a unit test. The
 * database checks everything again; this is for clear figures and early messages.
 */
import { isUuid } from "./ids";
import { MAX_AMOUNT, PROVIDERS, isProvider, type Provider } from "./payments";

export { PROVIDERS, isProvider, type Provider };

/** What a console payments action answers: done (with what happened) or the problem, as a message key. */
export type PlatformPaymentState = { ok: true; done: string } | { ok: false; error: string } | null;

const num = (value: unknown): number => {
  const n = typeof value === "number" ? value : typeof value === "string" && value.trim() !== "" ? Number(value) : NaN;
  return Number.isFinite(n) ? n : 0;
};
const int = (value: unknown): number => Math.round(num(value));
const str = (value: unknown): string | null => (typeof value === "string" && value !== "" ? value : null);
const obj = (value: unknown): Record<string, unknown> | null => (value && typeof value === "object" && !Array.isArray(value) ? (value as Record<string, unknown>) : null);
const list = (value: unknown): Record<string, unknown>[] => (Array.isArray(value) ? value.map(obj).filter((v): v is Record<string, unknown> => v !== null) : []);

// ---------------------------------------------------------------- the overview

export type PlatformMonth = {
  month: string;
  volume: number;
  schoolsShare: number;
  payments: number;
  fees: number;
  charges: number;
  transferCosts: number;
  costsFromSchools: number;
  refunds: number;
  payouts: number;
  invoicesPaid: number;
  infra: number;
  margin: number;
};

export type WalletReading = { balance: number; book: number; takenAt: string };

export type OperatorFigures = { provider: string; completed: number; failed: number; failureRate: number | null; topFailure: string | null };

export type PlatformPayments = {
  months: PlatformMonth[];
  heldForSchools: number;
  owedBySchools: number;
  bookBalance: number;
  wallet: WalletReading | null;
  topSchools: { id: string; name: string; volume: number; payments: number }[];
  operators: OperatorFigures[];
  attention: { payments: number; refunds: number; payoutsFailed: number; payoutAccountsWaiting: number };
};

/** Reads `platform_payments_overview`'s answer defensively: anything missing is zero or nothing. Months oldest first. */
export function parsePlatformPayments(json: unknown): PlatformPayments {
  const root = obj(json) ?? {};
  const wallet = obj(root.wallet);
  const attention = obj(root.attention) ?? {};
  return {
    months: list(root.months).flatMap((m) => {
      const month = str(m.month);
      if (!month) return [];
      return [
        {
          month: month.slice(0, 10),
          volume: int(m.volume),
          schoolsShare: int(m.schools_share),
          payments: int(m.payments),
          fees: int(m.fees),
          charges: int(m.charges),
          transferCosts: int(m.transfer_costs),
          costsFromSchools: int(m.costs_from_schools),
          refunds: int(m.refunds),
          payouts: int(m.payouts),
          invoicesPaid: int(m.invoices_paid),
          infra: int(m.infra),
          margin: int(m.margin),
        },
      ];
    }),
    heldForSchools: int(root.held_for_schools),
    owedBySchools: int(root.owed_by_schools),
    bookBalance: int(root.book_balance),
    wallet: wallet && str(wallet.taken_at) ? { balance: int(wallet.balance_xaf), book: int(wallet.book_xaf), takenAt: String(wallet.taken_at) } : null,
    topSchools: list(root.top_schools).flatMap((s) =>
      isUuid(s.id) ? [{ id: s.id, name: str(s.name) ?? "", volume: int(s.volume), payments: int(s.payments) }] : [],
    ),
    operators: list(root.operators).flatMap((o) => {
      const provider = str(o.provider);
      if (!provider) return [];
      return [{ provider, completed: int(o.completed), failed: int(o.failed), failureRate: o.failure_rate === null || o.failure_rate === undefined ? null : num(o.failure_rate), topFailure: str(o.top_failure) }];
    }),
    attention: {
      payments: int(attention.payments),
      refunds: int(attention.refunds),
      payoutsFailed: int(attention.payouts_failed),
      payoutAccountsWaiting: int(attention.payout_accounts_waiting),
    },
  };
}

/** The month (YYYY-MM-01) of a moment, in UTC as the overview groups them. */
export function monthOf(date: Date): string {
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, "0")}-01`;
}

/** This month's and last month's figures, when the overview has them. */
export function currentMonths(months: readonly PlatformMonth[], now: Date): { current: PlatformMonth | null; previous: PlatformMonth | null } {
  const thisMonth = monthOf(now);
  const last = monthOf(new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1)));
  return { current: months.find((m) => m.month === thisMonth) ?? null, previous: months.find((m) => m.month === last) ?? null };
}

export const MONTH_COLUMNS = ["volume", "fees", "charges", "transferCosts", "infra", "margin"] as const;
export type MonthColumn = (typeof MONTH_COLUMNS)[number];

// ---------------------------------------------------------------- the wallet against the books

/** A gap is flagged when it is above 1% of the books or above this many francs. */
export const WALLET_GAP_XAF = 5000;
export const WALLET_GAP_SHARE = 0.01;

/**
 * pawaPay's wallet as last read against what the books said at that moment. The gap is what the wallet holds more (or,
 * negative, less) than the books; it is flagged above 1% of the books or above 5,000 XAF, either way.
 */
export function walletGap(reading: { balance: number; book: number }): { gap: number; flagged: boolean } {
  const gap = reading.balance - reading.book;
  const size = Math.abs(gap);
  return { gap, flagged: size > WALLET_GAP_XAF || size > Math.abs(reading.book) * WALLET_GAP_SHARE };
}

// ---------------------------------------------------------------- alerts

export const ALERT_KINDS = ["payment", "refund", "payout", "payout_account"] as const;
export type AlertKind = (typeof ALERT_KINDS)[number];

export type PaymentAlert = { kind: AlertKind; id: string; schoolId: string; schoolName: string; amount: number | null; status: string; code: string | null; at: string };

/** Reads `platform_payment_alerts`' rows, known kinds only. */
export function parseAlerts(rows: unknown): PaymentAlert[] {
  return list(rows).flatMap((r) => {
    const kind = r.kind;
    if (typeof kind !== "string" || !(ALERT_KINDS as readonly string[]).includes(kind) || !isUuid(r.id) || !isUuid(r.school_id)) return [];
    return [
      {
        kind: kind as AlertKind,
        id: r.id,
        schoolId: r.school_id,
        schoolName: str(r.school_name) ?? "",
        amount: r.amount_xaf === null || r.amount_xaf === undefined ? null : int(r.amount_xaf),
        status: str(r.status) ?? "",
        code: str(r.code),
        at: str(r.at) ?? "",
      },
    ];
  });
}

// ---------------------------------------------------------------- settings

export type ProviderOperation = "deposit" | "payout" | "refund";
export const OPERATIONS: readonly ProviderOperation[] = ["deposit", "payout", "refund"];

export type ProviderRate = { provider: Provider; operation: ProviderOperation; percent: number | null; fixed: number };

export type PaymentSettings = {
  pawapay_percent: number;
  pawapay_vat_percent: number;
  fee_buffer_percent: number;
  fee_min_xaf: number;
  student_fee_allowed: boolean;
  hold_days: number;
  payout_min_xaf: number;
  charge_semester_xaf: number;
  charge_month_xaf: number;
  max_starts_per_hour: number;
};

export type SettingKey = keyof PaymentSettings;

/** Each setting the console may change, with its kind and range (the table's checks, `private.payment_settings`). */
export const SETTING_RULES: Record<SettingKey, { kind: "percent" | "xaf" | "count" | "flag"; min: number; max: number }> = {
  pawapay_percent: { kind: "percent", min: 0, max: 20 },
  pawapay_vat_percent: { kind: "percent", min: 0, max: 50 },
  fee_buffer_percent: { kind: "percent", min: 0, max: 5 },
  fee_min_xaf: { kind: "xaf", min: 0, max: MAX_AMOUNT },
  student_fee_allowed: { kind: "flag", min: 0, max: 1 },
  hold_days: { kind: "count", min: 0, max: 60 },
  payout_min_xaf: { kind: "xaf", min: 0, max: MAX_AMOUNT },
  charge_semester_xaf: { kind: "xaf", min: 0, max: MAX_AMOUNT },
  charge_month_xaf: { kind: "xaf", min: 0, max: MAX_AMOUNT },
  max_starts_per_hour: { kind: "count", min: 1, max: 60 },
};
export const SETTING_KEYS = Object.keys(SETTING_RULES) as SettingKey[];

/** An operator's percent: like pawaPay's, 0 to 20 (`private.provider_rates`). */
export const RATE_MAX_PERCENT = 20;

export type SettingsSnapshot = { settings: PaymentSettings; rates: ProviderRate[]; updatedAt: string | null };

const DEFAULTS: PaymentSettings = {
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

/** Reads `platform_payment_settings`' answer; a rate missing from it reads as not set. */
export function parseSettings(json: unknown): SettingsSnapshot {
  const root = obj(json) ?? {};
  const settings = { ...DEFAULTS };
  for (const key of SETTING_KEYS) {
    const value = root[key];
    if (key === "student_fee_allowed") settings.student_fee_allowed = typeof value === "boolean" ? value : DEFAULTS.student_fee_allowed;
    else if (value !== undefined && value !== null) (settings[key] as number) = num(value);
  }
  const given = list(root.rates);
  const rates: ProviderRate[] = PROVIDERS.flatMap((provider) =>
    OPERATIONS.map((operation) => {
      const row = given.find((r) => r.provider === provider && r.operation === operation);
      return { provider, operation, percent: row && row.mmo_percent !== null && row.mmo_percent !== undefined ? num(row.mmo_percent) : null, fixed: row ? int(row.mmo_fixed_xaf) : 0 };
    }),
  );
  return { settings, rates, updatedAt: str(root.updated_at) };
}

/** A decimal typed in English or French ("1.5", "1,5", "0,75 %"), with at most two decimals; null when it is not one. */
export function parseDecimal(raw: unknown): number | null {
  if (typeof raw !== "string") return null;
  const text = raw.replace(/[\s%  ]/g, "").replace(",", ".");
  if (!/^\d{1,3}(\.\d{1,2})?$/.test(text)) return null;
  return Number(text);
}

/** A whole number of francs or days ("20 000", "20,000", "20.000"); null when it is not one. */
export function parseWhole(raw: unknown): number | null {
  if (typeof raw !== "string") return null;
  const text = raw.trim();
  // Plain digits, or digits grouped by threes: "1.5" is not 15.
  if (!/^\d{1,9}$/.test(text) && !/^\d{1,3}([ ,.'  ]\d{3}){1,2}$/.test(text)) return null;
  return Number(text.replace(/\D/g, ""));
}

export type SettingsForm = { settings: PaymentSettings; rates: ProviderRate[] };
export type SettingsFormError = { field: string };

/** The form field of an operator's rate. */
export const rateField = (provider: string, operation: string, part: "percent" | "fixed") => `rate_${provider}_${operation}_${part}`;

/**
 * Reads the settings form: every setting in range, every operator's rate a percent (empty: not set, which stops that
 * operator for that kind of transaction) and a fixed part in francs. Answers the first field that is wrong.
 */
export function parseSettingsForm(formData: FormData): { ok: true; value: SettingsForm } | { ok: false; field: string } {
  const settings = { ...DEFAULTS };
  for (const key of SETTING_KEYS) {
    const rule = SETTING_RULES[key];
    if (rule.kind === "flag") {
      const value = formData.get(key);
      settings.student_fee_allowed = value === "on" || value === "true";
      continue;
    }
    const value = rule.kind === "percent" ? parseDecimal(formData.get(key)) : parseWhole(formData.get(key));
    if (value === null || value < rule.min || value > rule.max) return { ok: false, field: key };
    (settings[key] as number) = value;
  }
  const rates: ProviderRate[] = [];
  for (const provider of PROVIDERS) {
    for (const operation of OPERATIONS) {
      const percentField = rateField(provider, operation, "percent");
      const rawPercent = formData.get(percentField);
      const empty = typeof rawPercent !== "string" || rawPercent.trim() === "";
      const percent = empty ? null : parseDecimal(rawPercent);
      if (!empty && (percent === null || percent > RATE_MAX_PERCENT)) return { ok: false, field: percentField };
      const fixedField = rateField(provider, operation, "fixed");
      const rawFixed = formData.get(fixedField);
      const fixed = typeof rawFixed !== "string" || rawFixed.trim() === "" ? 0 : parseWhole(rawFixed);
      if (fixed === null || fixed > MAX_AMOUNT) return { ok: false, field: fixedField };
      rates.push({ provider, operation, percent, fixed });
    }
  }
  return { ok: true, value: { settings, rates } };
}

/** What a saved form changes: only the settings and rates that differ from the current ones, so the audit names them. */
export function settingsChanges(current: SettingsSnapshot, next: SettingsForm): { settings: Partial<PaymentSettings>; rates: ProviderRate[] } {
  const settings: Partial<PaymentSettings> = {};
  for (const key of SETTING_KEYS) {
    if (current.settings[key] !== next.settings[key]) (settings as Record<string, unknown>)[key] = next.settings[key];
  }
  const rates = next.rates.filter((rate) => {
    const before = current.rates.find((r) => r.provider === rate.provider && r.operation === rate.operation);
    return !before || before.percent !== rate.percent || before.fixed !== rate.fixed;
  });
  return { settings, rates };
}

// ---------------------------------------------------------------- the fee, as private.service_fee works it out

/**
 * Exact arithmetic, as Postgres' numeric does it: percents have at most two decimals, so they are whole hundredths, and
 * every rate becomes a whole number over one denominator. Floating point would turn 21160.000 into 21160.0000001 and
 * round a franc up that the database does not.
 */
const SCALE = BigInt(100_000_000);
const hundredths = (percent: number) => BigInt(Math.round(percent * 100));
/** pawaPay's share with its VAT, over SCALE (a fraction of one). */
const pawapayShare = (s: Pick<PaymentSettings, "pawapay_percent" | "pawapay_vat_percent">) => hundredths(s.pawapay_percent) * (BigInt(10000) + hundredths(s.pawapay_vat_percent));
/** A percent over SCALE. */
const share = (percent: number) => hundredths(percent) * BigInt(10000);
const ceilDiv = (n: bigint, d: bigint) => (n <= BigInt(0) ? -(-n / d) : (n + d - BigInt(1)) / d);

type Rates = Pick<PaymentSettings, "pawapay_percent" | "pawapay_vat_percent">;
type OperatorRates = { deposit: { percent: number | null; fixed: number }; payout: { percent: number | null; fixed: number } };

/** What moving an amount costs with an operator (`private.transfer_cost`); null while its rate is not set. */
export function transferCost(settings: Rates, rate: { percent: number | null; fixed: number }, amount: number): number | null {
  if (rate.percent === null) return null;
  const n = BigInt(Math.round(amount)) * (pawapayShare(settings) + share(rate.percent)) + BigInt(Math.round(rate.fixed)) * SCALE;
  return Number(ceilDiv(n, SCALE));
}

/**
 * The service fee the payer adds so that, once pawaPay and the operator have taken their share of the payment and of the
 * payout, the school receives the whole amount (plus the margin for rounding): `private.service_fee`. Without a payout
 * (BusIn's invoice), the payment's cost only. Null while the operator's rates are not set.
 */
export function serviceFee(settings: Rates & Pick<PaymentSettings, "fee_buffer_percent" | "fee_min_xaf">, operator: OperatorRates, amount: number, withPayout = true): number | null {
  const { deposit, payout } = operator;
  if (deposit.percent === null || payout.percent === null) return null;
  const pawa = pawapayShare(settings);
  const whole = BigInt(Math.round(amount));
  const extra = withPayout ? pawa + share(payout.percent) + share(settings.fee_buffer_percent) : BigInt(0);
  const numerator = whole * (SCALE + extra) + BigInt(Math.round(deposit.fixed)) * SCALE;
  const denominator = SCALE - pawa - share(deposit.percent);
  if (denominator <= BigInt(0)) return null;
  return Math.max(settings.fee_min_xaf, Number(ceilDiv(numerator, denominator)) - amount);
}

export type FeeEstimate = { provider: Provider; studentPays: number; fee: number; transferCost: number; schoolBears: number } | { provider: Provider; stopped: true };

/**
 * What a student pays by mobile money for a price, per operator, as `price_breakdown` works it out for a school whose
 * students pay the fees: BusIn's charge in the price, then the fee on top when the platform allows it. Without the fee on
 * top, the school bears the transfer costs. An estimate: the database's figures are the ones charged.
 */
export function feeEstimate(settings: PaymentSettings, rates: readonly ProviderRate[], price: number, charge: number): { receipt: number; operators: FeeEstimate[] } {
  const amount = price + charge;
  const rateOf = (provider: Provider, operation: ProviderOperation) => {
    const r = rates.find((x) => x.provider === provider && x.operation === operation);
    return { percent: r?.percent ?? null, fixed: r?.fixed ?? 0 };
  };
  return {
    receipt: amount,
    operators: PROVIDERS.map((provider): FeeEstimate => {
      const operator = { deposit: rateOf(provider, "deposit"), payout: rateOf(provider, "payout") };
      const full = serviceFee(settings, operator, amount, true);
      if (full === null) return { provider, stopped: true };
      const fee = settings.student_fee_allowed ? full : 0;
      const cost = (transferCost(settings, operator.deposit, amount + fee) ?? 0) + (transferCost(settings, operator.payout, amount) ?? 0);
      return { provider, studentPays: amount + fee, fee, transferCost: cost, schoolBears: settings.student_fee_allowed ? 0 : cost };
    }),
  };
}

// ---------------------------------------------------------------- one school

export type SchoolPayments = {
  terms: { enabled: boolean; chargesFrom: string | null; chargeSemester: number | null; chargeMonth: number | null; updatedAt: string | null } | null;
  feesPaidBy: "student" | "school";
  balance: { available: number; onHold: number; owed: number };
  payoutAccount: { id: string; status: "active" | "proposed"; provider: string; phoneMasked: string; accountName: string | null; usableFrom: string | null } | null;
  collected30d: number;
  openIssues: number;
};

const intOrNull = (value: unknown): number | null => (value === null || value === undefined ? null : int(value));

/** Reads `platform_school_payments`' answer; null for a school that does not exist. */
export function parseSchoolPayments(json: unknown): SchoolPayments | null {
  const root = obj(json);
  if (!root) return null;
  const terms = obj(root.terms);
  const balance = obj(root.balance) ?? {};
  const account = obj(root.payout_account);
  return {
    terms: terms
      ? {
          enabled: terms.enabled === true,
          chargesFrom: str(terms.charges_from)?.slice(0, 10) ?? null,
          chargeSemester: intOrNull(terms.charge_semester_xaf),
          chargeMonth: intOrNull(terms.charge_month_xaf),
          updatedAt: str(terms.updated_at),
        }
      : null,
    feesPaidBy: root.fees_paid_by === "school" ? "school" : "student",
    balance: { available: int(balance.available_xaf), onHold: int(balance.on_hold_xaf), owed: int(balance.owed_xaf) },
    payoutAccount:
      account && isUuid(account.id) && (account.status === "active" || account.status === "proposed")
        ? {
            id: account.id,
            status: account.status,
            provider: str(account.provider) ?? "",
            phoneMasked: str(account.phone_masked) ?? "",
            accountName: str(account.account_name),
            usableFrom: str(account.usable_from),
          }
        : null,
    collected30d: int(root.collected_30d),
    openIssues: int(root.open_issues),
  };
}

export type SchoolTerms = { school: string; enabled: boolean; chargesFrom: string | null; chargeSemester: number | null; chargeMonth: number | null };

const isIsoDate = (value: string) => /^\d{4}-\d{2}-\d{2}$/.test(value) && !Number.isNaN(Date.parse(`${value}T00:00:00Z`)) && new Date(`${value}T00:00:00Z`).toISOString().startsWith(value);

/** Reads a school's payment terms form: the switch, the day charges start (empty: none yet), its own charges (empty: the platform's). */
export function parseSchoolTerms(formData: FormData): { ok: true; value: SchoolTerms } | { ok: false; error: string } {
  const school = formData.get("school");
  if (!isUuid(school)) return { ok: false, error: "not_found" };
  const enabled = formData.get("enabled");
  const rawFrom = formData.get("charges_from");
  const from = typeof rawFrom === "string" ? rawFrom.trim() : "";
  if (from !== "" && !isIsoDate(from)) return { ok: false, error: "bad_date" };
  const charge = (name: string): number | null | false => {
    const raw = formData.get(name);
    if (typeof raw !== "string" || raw.trim() === "") return null;
    const value = parseWhole(raw);
    return value === null || value > MAX_AMOUNT ? false : value;
  };
  const semester = charge("charge_semester_xaf");
  const month = charge("charge_month_xaf");
  if (semester === false || month === false) return { ok: false, error: "bad_charge" };
  return { ok: true, value: { school, enabled: enabled === "on" || enabled === "true", chargesFrom: from || null, chargeSemester: semester, chargeMonth: month } };
}

// ---------------------------------------------------------------- infrastructure costs and the wallet

export type InfraCost = { id: string; month: string; label: string; amount: number; note: string | null };

/** Costs by month, newest month first, each with its total. */
export function costsByMonth(costs: readonly InfraCost[]): { month: string; total: number; costs: InfraCost[] }[] {
  const groups = new Map<string, InfraCost[]>();
  for (const cost of costs) groups.set(cost.month, [...(groups.get(cost.month) ?? []), cost]);
  return [...groups.entries()]
    .sort(([a], [b]) => (a < b ? 1 : a > b ? -1 : 0))
    .map(([month, items]) => ({ month, total: items.reduce((sum, c) => sum + c.amount, 0), costs: items }));
}

/** The months a cost can be entered for: this month and the eleven before it (YYYY-MM-01), newest first. */
export function costMonths(now: Date, count = 12): string[] {
  return Array.from({ length: count }, (_, i) => monthOf(new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - i, 1))));
}

export const MAX_COST_NOTE = 300;

/** Reads the infrastructure cost form: a month, a label of 2 to 80 characters, an amount above zero, a short note. */
export function parseInfraCost(formData: FormData): { ok: true; value: { month: string; label: string; amount: number; note: string | null } } | { ok: false; error: string } {
  const month = formData.get("month");
  if (typeof month !== "string" || !/^\d{4}-\d{2}-01$/.test(month) || !isIsoDate(month)) return { ok: false, error: "bad_month" };
  const rawLabel = formData.get("label");
  const label = typeof rawLabel === "string" ? rawLabel.replace(/\s+/g, " ").trim() : "";
  if (label.length < 2 || label.length > 80) return { ok: false, error: "bad_label" };
  const amount = parseWhole(formData.get("amount"));
  if (amount === null || amount <= 0 || amount > MAX_AMOUNT) return { ok: false, error: "bad_amount" };
  const rawNote = formData.get("note");
  const note = typeof rawNote === "string" ? rawNote.trim() : "";
  if (note.length > MAX_COST_NOTE) return { ok: false, error: "bad_note" };
  return { ok: true, value: { month, label, amount, note: note || null } };
}

export const WALLET_KINDS = ["withdrawal", "top_up"] as const;
export type WalletKind = (typeof WALLET_KINDS)[number];

/** Reads the wallet movement form: what kind, how much, an optional note. */
export function parseWalletMovement(formData: FormData): { ok: true; value: { kind: WalletKind; amount: number; note: string | null } } | { ok: false; error: string } {
  const kind = formData.get("kind");
  if (typeof kind !== "string" || !(WALLET_KINDS as readonly string[]).includes(kind)) return { ok: false, error: "bad_kind" };
  const amount = parseWhole(formData.get("amount"));
  if (amount === null || amount <= 0 || amount > 100_000_000) return { ok: false, error: "bad_amount" };
  const rawNote = formData.get("note");
  const note = typeof rawNote === "string" ? rawNote.trim() : "";
  if (note.length > MAX_COST_NOTE) return { ok: false, error: "bad_note" };
  return { ok: true, value: { kind: kind as WalletKind, amount, note: note || null } };
}

// ---------------------------------------------------------------- refusals

export const PAYMENT_ERRORS = ["not_allowed", "bad_setting", "bad_cost", "bad_movement", "not_found", "not_proposed", "no_school", "generic"] as const;
export type PlatformPaymentError = (typeof PAYMENT_ERRORS)[number];

/** Maps a database refusal of a console payments function to a message key. */
export function platformPaymentErrorKey(code: string | undefined, message: string | undefined): PlatformPaymentError {
  if (code === "42501") return "not_allowed";
  if (message && (PAYMENT_ERRORS as readonly string[]).includes(message)) return message as PlatformPaymentError;
  if (code === "P0002") return "not_found";
  return "generic";
}
