// pawaPay API v2 for mobile money payments (ADR 0029): numbers and operators, the requests BusIn sends, reading what
// pawaPay answers, and checking the signature of its callbacks (RFC 9421). Kept free of Deno APIs so Node can test it
// (node --test supabase/functions/_shared); the Edge Functions only wire it up. Network calls take an injected `fetch`.
//
// Rules from pawaPay's documentation (docs.pawapay.io/v2):
// - BusIn's payment id is pawaPay's depositId and its idempotency key: it is stored before pawaPay is called.
// - After a timeout or a 5xx, never assume a payment failed: ask its status. Only NOT_FOUND means it never started.
// - Statuses a payment goes through: ACCEPTED, PROCESSING, IN_RECONCILIATION, then COMPLETED or FAILED (final).
//   Initiating may also answer REJECTED (with a reason) or DUPLICATE_IGNORED (the id was already used).
// - Callbacks are retried up to 8 times over about 25 minutes and must be answered 200; the same one can come twice.
// - failureMessage is for BusIn's team, never for the payer: the apps show their own words for the failureCode.

export type Provider = "MTN_MOMO_CMR" | "ORANGE_CMR";
export const PROVIDERS: readonly Provider[] = ["MTN_MOMO_CMR", "ORANGE_CMR"];

export function isProvider(value: unknown): value is Provider {
  return typeof value === "string" && (PROVIDERS as readonly string[]).includes(value);
}

// ---------------------------------------------------------------- numbers and operators

/**
 * A Cameroonian mobile number in the form pawaPay takes (2376XXXXXXXX: country code, no plus, no spaces), from what a
 * person typed: "6 53 45 67 89", "+237 653456789", "00237653456789". Null when it is not one.
 */
export function normalizeCameroonPhone(input: unknown): string | null {
  if (typeof input !== "string") return null;
  let digits = input.replace(/[^0-9]/g, "");
  if (digits.startsWith("00")) digits = digits.slice(2);
  if (digits.length === 9) digits = `237${digits}`;
  return /^2376[0-9]{8}$/.test(digits) ? digits : null;
}

// Number ranges each operator was given (the national numbering plan). A first guess only, to show the logo while the number is typed:
// numbers move between operators, so the server asks pawaPay (predict-provider) before paying, and the payer can change it.
const MTN_PREFIXES = ["650", "651", "652", "653", "654", "67", "680", "681", "682", "683"];
const ORANGE_PREFIXES = ["655", "656", "657", "658", "659", "69"];

/** The operator a Cameroonian number most likely belongs to, or null when the range is not one of theirs. */
export function guessProvider(msisdn: string): Provider | null {
  const local = msisdn.startsWith("237") ? msisdn.slice(3) : msisdn;
  if (MTN_PREFIXES.some((p) => local.startsWith(p))) return "MTN_MOMO_CMR";
  if (ORANGE_PREFIXES.some((p) => local.startsWith(p))) return "ORANGE_CMR";
  return null;
}

// ---------------------------------------------------------------- what BusIn sends

/** What the payer's phone shows in the PIN prompt: 4 to 22 letters, digits and spaces. */
export const CUSTOMER_MESSAGE = "BusIn bus pass";

export type DepositInput = { id: string; phone: string; provider: Provider; totalXaf: number; reference?: string };

/** The body of POST /v2/deposits. XAF has no decimals: the amount is a whole number written as text. */
export function depositRequest(input: DepositInput) {
  if (!Number.isInteger(input.totalXaf) || input.totalXaf <= 0) throw new Error("amount must be a positive whole number");
  return {
    depositId: input.id,
    payer: { type: "MMO", accountDetails: { phoneNumber: input.phone, provider: input.provider } },
    amount: String(input.totalXaf),
    currency: "XAF",
    customerMessage: CUSTOMER_MESSAGE,
    ...(input.reference ? { clientReferenceId: input.reference } : {}),
  };
}

export type RefundInput = { id: string; depositId: string; amountXaf: number };

/** The body of POST /v2/refunds: BusIn's refund id (its idempotency key), the payment refunded, a whole amount in XAF. */
export function refundRequest(input: RefundInput) {
  if (!Number.isInteger(input.amountXaf) || input.amountXaf <= 0) throw new Error("amount must be a positive whole number");
  return { refundId: input.id, depositId: input.depositId, amount: String(input.amountXaf), currency: "XAF" };
}

export type PayoutInput = { id: string; phone: string; provider: Provider; amountXaf: number };

/** The body of POST /v2/payouts: BusIn's payout id (its idempotency key), the school's number, a whole amount in XAF. */
export function payoutRequest(input: PayoutInput) {
  if (!Number.isInteger(input.amountXaf) || input.amountXaf <= 0) throw new Error("amount must be a positive whole number");
  return {
    payoutId: input.id,
    recipient: { type: "MMO", accountDetails: { phoneNumber: input.phone, provider: input.provider } },
    amount: String(input.amountXaf),
    currency: "XAF",
    customerMessage: "BusIn payout",
  };
}

// ---------------------------------------------------------------- what pawaPay answers

export type Initiation =
  | { kind: "accepted" }
  | { kind: "rejected"; failureCode: string; failureMessage: string | null }
  | { kind: "duplicate" }
  // A timeout, a network error, a 5xx or a body that cannot be read: the status must be asked.
  | { kind: "unknown" };

type Json = Record<string, unknown>;

function asObject(value: unknown): Json | null {
  return value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Json) : null;
}

function failureOf(body: Json | null): { failureCode: string; failureMessage: string | null } {
  const reason = asObject(body?.failureReason);
  const code = typeof reason?.failureCode === "string" && reason.failureCode ? reason.failureCode : "UNKNOWN_ERROR";
  const message = typeof reason?.failureMessage === "string" ? reason.failureMessage : null;
  return { failureCode: code, failureMessage: message };
}

/** Reads pawaPay's answer to POST /v2/deposits. `httpStatus` is 0 when no answer came. */
export function readInitiation(httpStatus: number, body: unknown): Initiation {
  const json = asObject(body);
  if (httpStatus >= 500 || httpStatus === 0 || !json) return { kind: "unknown" };
  if (json.status === "ACCEPTED") return { kind: "accepted" };
  if (json.status === "DUPLICATE_IGNORED") return { kind: "duplicate" };
  // 4xx with a reason: pawaPay refused it and will not process it (bad number, amount out of bounds, operator down...).
  if (json.status === "REJECTED" || (httpStatus >= 400 && httpStatus < 500)) return { kind: "rejected", ...failureOf(json) };
  return { kind: "unknown" };
}

export type DepositState =
  | { found: false }
  | {
      found: true;
      status: string;
      amount: string | null;
      currency: string | null;
      providerTransactionId: string | null;
      failureCode: string | null;
      failureMessage: string | null;
    };

/** A deposit's data, as GET /v2/deposits/{id} gives it under `data`, or as a callback's body. */
export function readDeposit(data: unknown): DepositState | null {
  const d = asObject(data);
  if (!d || typeof d.status !== "string") return null;
  const failure = d.failureReason ? failureOf(d) : { failureCode: null, failureMessage: null };
  return {
    found: true,
    status: d.status,
    amount: typeof d.amount === "string" || typeof d.amount === "number" ? String(d.amount) : null,
    currency: typeof d.currency === "string" ? d.currency : null,
    providerTransactionId: typeof d.providerTransactionId === "string" ? d.providerTransactionId : null,
    failureCode: failure.failureCode,
    failureMessage: failure.failureMessage,
  };
}

/** Reads GET /v2/deposits/{id}: found with its state, not found, or null when the answer cannot be read. */
export function readDepositStatus(httpStatus: number, body: unknown): DepositState | null {
  const json = asObject(body);
  if (httpStatus !== 200 || !json) return null;
  if (json.status === "NOT_FOUND") return { found: false };
  if (json.status === "FOUND") return readDeposit(json.data);
  return null;
}

/** The arguments of the database's settle_refund for a refund's state (see the refunds migration). */
export function settleRefundArgs(id: string, state: DepositState) {
  if (!state.found) return { p_id: id, p_status: "NOT_FOUND" };
  return {
    p_id: id,
    p_status: state.status,
    p_amount: state.amount,
    p_currency: state.currency,
    p_provider_txn: state.providerTransactionId,
    p_failure_code: state.failureCode,
  };
}

/** The arguments of the database's settle_payment for a deposit's state (see the payments migration). */
export function settleArgs(id: string, state: DepositState) {
  if (!state.found) return { p_id: id, p_status: "NOT_FOUND" };
  return {
    p_id: id,
    p_status: state.status,
    p_amount: state.amount,
    p_currency: state.currency,
    p_provider_txn: state.providerTransactionId,
    p_failure_code: state.failureCode,
    p_failure_message: state.failureMessage,
  };
}

/**
 * The XAF balance of BusIn's Cameroon wallets from GET /v2/wallet-balances, in whole francs (a wallet per operator, or
 * one shared, are added up). Null when the answer cannot be read.
 */
export function readWalletXaf(httpStatus: number, body: unknown): number | null {
  const json = asObject(body);
  if (httpStatus !== 200 || !json || !Array.isArray(json.balances)) return null;
  let total = 0;
  for (const raw of json.balances) {
    const w = asObject(raw);
    if (!w || w.currency !== "XAF" || (w.country !== undefined && w.country !== "CMR")) continue;
    const value = Number(w.balance);
    if (!Number.isFinite(value)) return null;
    total += value;
  }
  return Math.floor(total);
}

// ---------------------------------------------------------------- calling pawaPay

export type Fetch = (url: string, init: RequestInit) => Promise<Response>;

export type PawaPayClient = {
  initiateDeposit(input: DepositInput): Promise<Initiation>;
  depositStatus(id: string): Promise<DepositState | null>;
  initiateRefund(input: RefundInput): Promise<Initiation>;
  refundStatus(id: string): Promise<DepositState | null>;
  initiatePayout(input: PayoutInput): Promise<Initiation>;
  payoutStatus(id: string): Promise<DepositState | null>;
  walletXaf(): Promise<number | null>;
  predictProvider(phone: string): Promise<{ provider: string; phoneNumber: string } | null>;
  publicKeys(): Promise<{ id: string; key: string }[]>;
};

/** A client for one pawaPay environment. Every call has a timeout; none throws on pawaPay's answers. */
export function pawaPay(options: { baseUrl: string; token: string; fetch: Fetch; timeoutMs?: number }): PawaPayClient {
  const base = options.baseUrl.replace(/\/+$/, "");
  const timeout = options.timeoutMs ?? 15000;

  async function call(method: string, path: string, body?: unknown): Promise<{ status: number; json: unknown }> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeout);
    try {
      const response = await options.fetch(`${base}${path}`, {
        method,
        headers: { authorization: `Bearer ${options.token}`, "content-type": "application/json" },
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: controller.signal,
      });
      let json: unknown = null;
      try {
        json = await response.json();
      } catch {
        json = null;
      }
      return { status: response.status, json };
    } catch {
      return { status: 0, json: null };
    } finally {
      clearTimeout(timer);
    }
  }

  return {
    async initiateDeposit(input) {
      const { status, json } = await call("POST", "/v2/deposits", depositRequest(input));
      return readInitiation(status, json);
    },
    async depositStatus(id) {
      const { status, json } = await call("GET", `/v2/deposits/${encodeURIComponent(id)}`);
      return readDepositStatus(status, json);
    },
    async initiateRefund(input) {
      const { status, json } = await call("POST", "/v2/refunds", refundRequest(input));
      return readInitiation(status, json);
    },
    async refundStatus(id) {
      const { status, json } = await call("GET", `/v2/refunds/${encodeURIComponent(id)}`);
      return readDepositStatus(status, json);
    },
    async initiatePayout(input) {
      const { status, json } = await call("POST", "/v2/payouts", payoutRequest(input));
      return readInitiation(status, json);
    },
    async payoutStatus(id) {
      const { status, json } = await call("GET", `/v2/payouts/${encodeURIComponent(id)}`);
      return readDepositStatus(status, json);
    },
    async walletXaf() {
      const { status, json } = await call("GET", "/v2/wallet-balances?country=CMR");
      return readWalletXaf(status, json);
    },
    async predictProvider(phone) {
      const { status, json } = await call("POST", "/v2/predict-provider", { phoneNumber: phone });
      const body = asObject(json);
      if (status !== 200 || !body || typeof body.provider !== "string" || typeof body.phoneNumber !== "string") return null;
      return { provider: body.provider, phoneNumber: body.phoneNumber };
    },
    async publicKeys() {
      const { status, json } = await call("GET", "/v2/public-key/http");
      if (status !== 200 || !Array.isArray(json)) return [];
      return json
        .map(asObject)
        .filter((k): k is Json => !!k && typeof k.id === "string" && typeof k.key === "string")
        .map((k) => ({ id: k.id as string, key: k.key as string }));
    },
  };
}

// ---------------------------------------------------------------- signed callbacks (RFC 9421)

export type CallbackRequest = {
  method: string;
  // The address pawaPay was given (its authority and path are signed), not the one the function sees internally.
  url: string;
  headers: { get(name: string): string | null };
  body: string;
};

export type Verdict = { ok: true } | { ok: false; reason: string };

const enc = new TextEncoder();

function fromBase64(value: string): Uint8Array {
  const bin = atob(value);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function toBase64(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}

/** Splits "label=value" structured-field dictionary members, ignoring commas inside quotes and parentheses. */
function dictionary(header: string): Map<string, string> {
  const out = new Map<string, string>();
  let depth = 0;
  let quoted = false;
  let start = 0;
  const push = (part: string) => {
    const eq = part.indexOf("=");
    if (eq > 0) out.set(part.slice(0, eq).trim(), part.slice(eq + 1).trim());
  };
  for (let i = 0; i < header.length; i++) {
    const c = header[i];
    if (c === '"' && header[i - 1] !== "\\") quoted = !quoted;
    else if (!quoted && c === "(") depth++;
    else if (!quoted && c === ")") depth--;
    else if (!quoted && depth === 0 && c === ",") {
      push(header.slice(start, i));
      start = i + 1;
    }
  }
  push(header.slice(start));
  return out;
}

type SignatureInput = { components: string[]; params: Record<string, string>; raw: string };

function parseSignatureInput(value: string): SignatureInput | null {
  const match = /^\(([^)]*)\)(.*)$/.exec(value.trim());
  if (!match) return null;
  const components = [...match[1].matchAll(/"([^"]+)"/g)].map((m) => m[1]);
  const params: Record<string, string> = {};
  for (const part of match[2].split(";").slice(1)) {
    const eq = part.indexOf("=");
    if (eq > 0) params[part.slice(0, eq).trim()] = part.slice(eq + 1).trim().replace(/^"|"$/g, "");
  }
  return { components, params, raw: value.trim() };
}

/** The signature base RFC 9421 signs: one line per covered component, then the signature parameters. */
export function signatureBase(request: CallbackRequest, input: SignatureInput): string | null {
  const url = new URL(request.url);
  const lines: string[] = [];
  for (const name of input.components) {
    let value: string | null;
    if (name === "@method") value = request.method.toUpperCase();
    else if (name === "@authority") value = url.host.toLowerCase();
    else if (name === "@path") value = url.pathname;
    else if (name === "@target-uri") value = url.href;
    else if (name === "@query") value = url.search || "?";
    else if (name.startsWith("@")) return null;
    else value = request.headers.get(name);
    if (value === null) return null;
    lines.push(`"${name}": ${value.trim()}`);
  }
  lines.push(`"@signature-params": ${input.raw}`);
  return lines.join("\n");
}

/** An ECDSA signature in DER (as pawaPay sends it) turned into the fixed r||s form WebCrypto checks. */
export function derToP1363(der: Uint8Array, size: number): Uint8Array | null {
  if (der.length === size * 2) return der;
  if (der[0] !== 0x30) return null;
  let offset = 2;
  if (der[1] & 0x80) offset = 2 + (der[1] & 0x7f);
  const out = new Uint8Array(size * 2);
  for (let part = 0; part < 2; part++) {
    if (der[offset] !== 0x02) return null;
    const length = der[offset + 1];
    let value = der.subarray(offset + 2, offset + 2 + length);
    while (value.length > size && value[0] === 0) value = value.subarray(1);
    if (value.length > size) return null;
    out.set(value, part * size + (size - value.length));
    offset += 2 + length;
  }
  return out;
}

function pemBody(pem: string): Uint8Array {
  return fromBase64(pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, ""));
}

const ALGORITHMS: Record<string, { curve: string; hash: string; size: number }> = {
  "ecdsa-p256-sha256": { curve: "P-256", hash: "SHA-256", size: 32 },
  "ecdsa-p384-sha384": { curve: "P-384", hash: "SHA-384", size: 48 },
};

async function digestMatches(header: string | null, body: string): Promise<boolean> {
  if (!header) return false;
  const members = dictionary(header);
  for (const [name, algorithm] of [["sha-512", "SHA-512"], ["sha-256", "SHA-256"]] as const) {
    const value = members.get(name);
    if (!value) continue;
    const expected = value.replace(/^:|:$/g, "");
    const actual = toBase64(new Uint8Array(await crypto.subtle.digest(algorithm, enc.encode(body))));
    return actual === expected;
  }
  return false;
}

/**
 * Checks a callback pawaPay signed: the body matches its Content-Digest, the signature is fresh, and it verifies with one
 * of pawaPay's public keys (GET /v2/public-key/http) over the covered components. `nowSeconds` is the current Unix time.
 */
export async function verifyCallback(
  request: CallbackRequest,
  keys: { id: string; key: string }[],
  nowSeconds: number,
): Promise<Verdict> {
  const inputs = dictionary(request.headers.get("signature-input") ?? "");
  const signatures = dictionary(request.headers.get("signature") ?? "");
  const label = [...inputs.keys()].find((l) => signatures.has(l));
  if (!label) return { ok: false, reason: "unsigned" };
  const input = parseSignatureInput(inputs.get(label)!);
  if (!input) return { ok: false, reason: "bad_signature_input" };
  for (const required of ["@method", "@authority", "@path", "content-digest"]) {
    if (!input.components.includes(required)) return { ok: false, reason: "too_little_signed" };
  }
  const algorithm = ALGORITHMS[input.params.alg ?? ""];
  if (!algorithm) return { ok: false, reason: "unsupported_algorithm" };
  const created = Number(input.params.created);
  const expires = Number(input.params.expires);
  if (Number.isFinite(expires) && expires + 60 < nowSeconds) return { ok: false, reason: "expired" };
  if (Number.isFinite(created) && created - 300 > nowSeconds) return { ok: false, reason: "from_the_future" };
  if (!(await digestMatches(request.headers.get("content-digest"), request.body))) return { ok: false, reason: "digest_mismatch" };

  const base = signatureBase(request, input);
  if (!base) return { ok: false, reason: "missing_component" };
  const der = fromBase64(signatures.get(label)!.replace(/^:|:$/g, ""));
  const signature = derToP1363(der, algorithm.size);
  if (!signature) return { ok: false, reason: "bad_signature" };

  // The key named by keyid first, then any other (key ids have not always matched in pawaPay's examples).
  const ordered = [...keys].sort((a, b) => Number(b.id === input.params.keyid) - Number(a.id === input.params.keyid));
  for (const { key } of ordered) {
    try {
      const publicKey = await crypto.subtle.importKey("spki", pemBody(key), { name: "ECDSA", namedCurve: algorithm.curve }, false, ["verify"]);
      if (await crypto.subtle.verify({ name: "ECDSA", hash: algorithm.hash }, publicKey, signature, enc.encode(base))) return { ok: true };
    } catch {
      // Not a key of this kind: try the next one.
    }
  }
  return { ok: false, reason: "bad_signature" };
}

/** What a callback is about: a deposit (a payment), a payout or a refund, with its id. */
export function callbackSubject(body: unknown): { kind: "deposit" | "payout" | "refund"; id: string } | null {
  const json = asObject(body);
  if (!json) return null;
  for (const [field, kind] of [["depositId", "deposit"], ["payoutId", "payout"], ["refundId", "refund"]] as const) {
    const id = json[field];
    if (typeof id === "string" && /^[0-9a-f-]{36}$/i.test(id)) return { kind, id: id.toLowerCase() };
  }
  return null;
}
