import { strict as assert } from "node:assert";
import { createSign, generateKeyPairSync } from "node:crypto";
import { test } from "node:test";

import {
  callbackSubject,
  depositRequest,
  derToP1363,
  guessProvider,
  normalizeCameroonPhone,
  pawaPay,
  readDeposit,
  readDepositStatus,
  readInitiation,
  settleArgs,
  signatureBase,
  verifyCallback,
  type Fetch,
} from "./pawapay.ts";

test("numbers are read the way people type them", () => {
  for (const typed of ["653456789", "6 53 45 67 89", "+237 653 456 789", "00237653456789", "237653456789"]) {
    assert.equal(normalizeCameroonPhone(typed), "237653456789", typed);
  }
  for (const bad of ["", "53456789", "233653456789", "2376534567890", "237253456789", null, 653456789]) {
    assert.equal(normalizeCameroonPhone(bad), null, String(bad));
  }
});

test("the operator is guessed from the number's range, and unknown ranges are left to pawaPay", () => {
  assert.equal(guessProvider("237653456789"), "MTN_MOMO_CMR");
  assert.equal(guessProvider("237677000000"), "MTN_MOMO_CMR");
  assert.equal(guessProvider("237693456789"), "ORANGE_CMR");
  assert.equal(guessProvider("237655000000"), "ORANGE_CMR");
  assert.equal(guessProvider("237660000000"), null);
});

test("a deposit request carries a whole amount as text, in XAF, with BusIn's message", () => {
  const body = depositRequest({ id: "8917c345-4791-4285-a416-62f24b6982db", phone: "237653456789", provider: "MTN_MOMO_CMR", totalXaf: 20662 });
  assert.deepEqual(body, {
    depositId: "8917c345-4791-4285-a416-62f24b6982db",
    payer: { type: "MMO", accountDetails: { phoneNumber: "237653456789", provider: "MTN_MOMO_CMR" } },
    amount: "20662",
    currency: "XAF",
    customerMessage: "BusIn bus pass",
  });
  assert.match(body.customerMessage, /^[a-zA-Z0-9 ]{4,22}$/);
  assert.throws(() => depositRequest({ id: "x", phone: "237653456789", provider: "ORANGE_CMR", totalXaf: 10.5 }));
});

test("an initiation is accepted, refused with its reason, a duplicate, or unknown (then the status is asked)", () => {
  assert.deepEqual(readInitiation(200, { status: "ACCEPTED" }), { kind: "accepted" });
  assert.deepEqual(readInitiation(200, { status: "DUPLICATE_IGNORED" }), { kind: "duplicate" });
  assert.deepEqual(
    readInitiation(200, { status: "REJECTED", failureReason: { failureCode: "AMOUNT_OUT_OF_BOUNDS", failureMessage: "Too much" } }),
    { kind: "rejected", failureCode: "AMOUNT_OUT_OF_BOUNDS", failureMessage: "Too much" },
  );
  assert.deepEqual(readInitiation(400, { status: "REJECTED" }), { kind: "rejected", failureCode: "UNKNOWN_ERROR", failureMessage: null });
  // Never failed on a 500 or a timeout: pawaPay may have taken it.
  assert.deepEqual(readInitiation(500, { failureReason: { failureCode: "UNKNOWN_ERROR" } }), { kind: "unknown" });
  assert.deepEqual(readInitiation(0, null), { kind: "unknown" });
  assert.deepEqual(readInitiation(200, "not json"), { kind: "unknown" });
});

test("a status is found with its details, not found, or unreadable", () => {
  const found = readDepositStatus(200, {
    status: "FOUND",
    data: { depositId: "x", status: "COMPLETED", amount: "20662.00", currency: "XAF", providerTransactionId: "MP1" },
  });
  assert.deepEqual(found, { found: true, status: "COMPLETED", amount: "20662.00", currency: "XAF", providerTransactionId: "MP1", failureCode: null, failureMessage: null });
  assert.deepEqual(readDepositStatus(200, { status: "NOT_FOUND" }), { found: false });
  assert.equal(readDepositStatus(500, null), null);
  assert.equal(readDepositStatus(200, { status: "FOUND" }), null);
  const failed = readDeposit({ status: "FAILED", failureReason: { failureCode: "PAYMENT_NOT_APPROVED", failureMessage: "No PIN" } });
  assert.equal(failed?.found && failed.failureCode, "PAYMENT_NOT_APPROVED");
});

test("the database gets the state as settle_payment takes it", () => {
  assert.deepEqual(settleArgs("id1", { found: false }), { p_id: "id1", p_status: "NOT_FOUND" });
  assert.deepEqual(
    settleArgs("id1", { found: true, status: "FAILED", amount: "1", currency: "XAF", providerTransactionId: null, failureCode: "INSUFFICIENT_BALANCE", failureMessage: null }),
    { p_id: "id1", p_status: "FAILED", p_amount: "1", p_currency: "XAF", p_provider_txn: null, p_failure_code: "INSUFFICIENT_BALANCE", p_failure_message: null },
  );
});

test("the client calls pawaPay with the token, and a network failure is an unknown answer, not a refusal", async () => {
  const calls: { url: string; init: RequestInit }[] = [];
  const answers: (() => Promise<Response>)[] = [
    async () => new Response(JSON.stringify({ depositId: "a", status: "ACCEPTED" }), { status: 200 }),
    async () => {
      throw new Error("network down");
    },
    async () => new Response(JSON.stringify({ country: "CMR", provider: "ORANGE_CMR", phoneNumber: "237693456789" }), { status: 200 }),
  ];
  const fetch: Fetch = (url, init) => {
    calls.push({ url, init });
    return answers.shift()!();
  };
  const client = pawaPay({ baseUrl: "https://api.sandbox.pawapay.io/", token: "t0k", fetch });
  assert.deepEqual(await client.initiateDeposit({ id: "a", phone: "237653456789", provider: "MTN_MOMO_CMR", totalXaf: 100 }), { kind: "accepted" });
  assert.equal(calls[0].url, "https://api.sandbox.pawapay.io/v2/deposits");
  assert.equal((calls[0].init.headers as Record<string, string>).authorization, "Bearer t0k");
  assert.deepEqual(await client.initiateDeposit({ id: "b", phone: "237653456789", provider: "MTN_MOMO_CMR", totalXaf: 100 }), { kind: "unknown" });
  assert.deepEqual(await client.predictProvider("693456789"), { provider: "ORANGE_CMR", phoneNumber: "237693456789" });
});

test("callbacks name what they are about", () => {
  assert.deepEqual(callbackSubject({ depositId: "8917C345-4791-4285-A416-62F24B6982DB" }), { kind: "deposit", id: "8917c345-4791-4285-a416-62f24b6982db" });
  assert.deepEqual(callbackSubject({ refundId: "8917c345-4791-4285-a416-62f24b6982db" })?.kind, "refund");
  assert.equal(callbackSubject({ depositId: "x'; drop table" }), null);
  assert.equal(callbackSubject([]), null);
});

// ---------------------------------------------------------------- signatures
const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
const PEM = publicKey.export({ type: "spki", format: "pem" }).toString();
const CALLBACK_URL = "https://project.supabase.co/functions/v1/pawapay-callback";
const NOW = 1_800_000_000;

async function signed(body: string, opts: { tamperBody?: string; created?: number; expires?: number; raw?: boolean } = {}) {
  const digest = Buffer.from(await crypto.subtle.digest("SHA-512", new TextEncoder().encode(body))).toString("base64");
  const headers = new Map<string, string>([
    ["content-type", "application/json; charset=UTF-8"],
    ["content-digest", `sha-512=:${digest}:`],
    ["signature-date", "2027-01-15T08:00:00.000000Z"],
  ]);
  const created = opts.created ?? NOW - 5;
  const expires = opts.expires ?? NOW + 55;
  const params = `("@method" "@authority" "@path" "signature-date" "content-digest" "content-type");alg="ecdsa-p256-sha256";keyid="HTTP_EC_P256_KEY:1";created=${created};expires=${expires}`;
  headers.set("signature-input", `sig-pp=${params}`);
  const request = { method: "POST", url: CALLBACK_URL, headers: { get: (n: string) => headers.get(n.toLowerCase()) ?? null }, body };
  const base = signatureBase(request, { components: ["@method", "@authority", "@path", "signature-date", "content-digest", "content-type"], params: {}, raw: params })!;
  const signer = createSign("SHA256");
  signer.update(base);
  const sig = signer.sign({ key: privateKey, dsaEncoding: opts.raw ? "ieee-p1363" : "der" }).toString("base64");
  headers.set("signature", `sig-pp=:${sig}:`);
  return { ...request, body: opts.tamperBody ?? body };
}

const KEYS = [{ id: "HTTP_EC_P256_KEY:1", key: PEM }];
const BODY = JSON.stringify({ depositId: "8917c345-4791-4285-a416-62f24b6982db", status: "COMPLETED", amount: "20662", currency: "XAF" });

test("a callback signed by pawaPay is accepted, in DER (as pawaPay sends it) or raw form", async () => {
  assert.deepEqual(await verifyCallback(await signed(BODY), KEYS, NOW), { ok: true });
  assert.deepEqual(await verifyCallback(await signed(BODY, { raw: true }), KEYS, NOW), { ok: true });
});

test("the signature base follows RFC 9421, as in pawaPay's example", () => {
  const params = `("@method" "@authority" "@path");alg="ecdsa-p256-sha256";keyid="K";created=1;expires=2`;
  const base = signatureBase(
    { method: "post", url: "http://localhost:8080/callback", headers: { get: () => null }, body: "" },
    { components: ["@method", "@authority", "@path"], params: {}, raw: params },
  );
  assert.equal(base, `"@method": POST\n"@authority": localhost:8080\n"@path": /callback\n"@signature-params": ${params}`);
});

test("a changed body, a wrong key, an old signature or no signature are refused", async () => {
  assert.deepEqual(await verifyCallback(await signed(BODY, { tamperBody: BODY.replace("COMPLETED", "FAILED") }), KEYS, NOW), { ok: false, reason: "digest_mismatch" });
  const other = generateKeyPairSync("ec", { namedCurve: "P-256" }).publicKey.export({ type: "spki", format: "pem" }).toString();
  assert.deepEqual(await verifyCallback(await signed(BODY), [{ id: "HTTP_EC_P256_KEY:1", key: other }], NOW), { ok: false, reason: "bad_signature" });
  assert.deepEqual(await verifyCallback(await signed(BODY, { created: NOW - 4000, expires: NOW - 3000 }), KEYS, NOW), { ok: false, reason: "expired" });
  const unsigned = { method: "POST", url: CALLBACK_URL, headers: { get: () => null }, body: BODY };
  assert.deepEqual(await verifyCallback(unsigned, KEYS, NOW), { ok: false, reason: "unsigned" });
});

test("a DER signature with leading zeros becomes 64 bytes", () => {
  const r = new Uint8Array(33).fill(1);
  r[0] = 0;
  const s = new Uint8Array(32).fill(2);
  const der = new Uint8Array([0x30, 2 + 33 + 2 + 32, 0x02, 33, ...r, 0x02, 32, ...s]);
  const raw = derToP1363(der, 32)!;
  assert.equal(raw.length, 64);
  assert.equal(raw[0], 1);
  assert.equal(raw[63], 2);
});

test("database refusals keep their code and get a fitting status; anything else is a plain error", async () => {
  const { refusal } = await import("./payments-errors.ts");
  assert.deepEqual(refusal({ code: "55000", message: "payment_in_progress" }), { status: 409, code: "payment_in_progress" });
  assert.deepEqual(refusal({ code: "54000", message: "too_many_attempts" }), { status: 429, code: "too_many_attempts" });
  assert.deepEqual(refusal({ code: "P0002", message: "not_found" }), { status: 404, code: "not_found" });
  assert.deepEqual(refusal({ code: "XX000", message: "relation \"x\" does not exist" }), { status: 500, code: "payment_error" });
  assert.deepEqual(refusal(null), { status: 500, code: "payment_error" });
});

test("a refund request names BusIn's refund id and the payment, with a whole amount", async () => {
  const { refundRequest, settleRefundArgs } = await import("./pawapay.ts");
  assert.deepEqual(refundRequest({ id: "r1", depositId: "p1", amountXaf: 15000 }), { refundId: "r1", depositId: "p1", amount: "15000", currency: "XAF" });
  assert.throws(() => refundRequest({ id: "r1", depositId: "p1", amountXaf: 0 }));
  assert.deepEqual(settleRefundArgs("r1", { found: false }), { p_id: "r1", p_status: "NOT_FOUND" });
  assert.equal(
    settleRefundArgs("r1", { found: true, status: "COMPLETED", amount: "15000", currency: "XAF", providerTransactionId: "T", failureCode: null, failureMessage: null })
      .p_status,
    "COMPLETED",
  );
});

test("a refund is sent to /v2/refunds and checked at /v2/refunds/{id}", async () => {
  const urls: string[] = [];
  const fetch: Fetch = async (url) => {
    urls.push(url);
    return url.endsWith("/v2/refunds")
      ? new Response(JSON.stringify({ refundId: "r1", status: "ACCEPTED" }), { status: 200 })
      : new Response(JSON.stringify({ status: "FOUND", data: { refundId: "r1", status: "COMPLETED", amount: "15000", currency: "XAF" } }), { status: 200 });
  };
  const client = pawaPay({ baseUrl: "https://api.sandbox.pawapay.io", token: "t", fetch });
  assert.deepEqual(await client.initiateRefund({ id: "r1", depositId: "p1", amountXaf: 15000 }), { kind: "accepted" });
  const state = await client.refundStatus("r1");
  assert.equal(state?.found && state.status, "COMPLETED");
  assert.deepEqual(urls, ["https://api.sandbox.pawapay.io/v2/refunds", "https://api.sandbox.pawapay.io/v2/refunds/r1"]);
});

test("a payout goes to the school's number with a whole amount, and is checked at /v2/payouts/{id}", async () => {
  const { payoutRequest } = await import("./pawapay.ts");
  assert.deepEqual(payoutRequest({ id: "o1", phone: "237677123456", provider: "MTN_MOMO_CMR", amountXaf: 30000 }), {
    payoutId: "o1",
    recipient: { type: "MMO", accountDetails: { phoneNumber: "237677123456", provider: "MTN_MOMO_CMR" } },
    amount: "30000",
    currency: "XAF",
    customerMessage: "BusIn payout",
  });
  const urls: string[] = [];
  const fetch: Fetch = async (url) => {
    urls.push(url);
    return url.endsWith("/v2/payouts")
      ? new Response(JSON.stringify({ payoutId: "o1", status: "ACCEPTED" }), { status: 200 })
      : new Response(JSON.stringify({ status: "FOUND", data: { payoutId: "o1", status: "ENQUEUED", amount: "30000", currency: "XAF" } }), { status: 200 });
  };
  const client = pawaPay({ baseUrl: "https://api.sandbox.pawapay.io", token: "t", fetch });
  assert.deepEqual(await client.initiatePayout({ id: "o1", phone: "237677123456", provider: "MTN_MOMO_CMR", amountXaf: 30000 }), { kind: "accepted" });
  const state = await client.payoutStatus("o1");
  assert.equal(state?.found && state.status, "ENQUEUED");
  assert.deepEqual(urls, ["https://api.sandbox.pawapay.io/v2/payouts", "https://api.sandbox.pawapay.io/v2/payouts/o1"]);
});

test("the wallet balance adds up BusIn's XAF wallets in Cameroon, in whole francs", async () => {
  const { readWalletXaf } = await import("./pawapay.ts");
  assert.equal(
    readWalletXaf(200, {
      balances: [
        { country: "CMR", balance: "150000.0", currency: "XAF", provider: "MTN_MOMO_CMR" },
        { country: "CMR", balance: "50500.5", currency: "XAF", provider: "ORANGE_CMR" },
        { country: "ZMB", balance: "999", currency: "ZMW", provider: "" },
      ],
    }),
    200500,
  );
  assert.equal(readWalletXaf(401, { failureReason: {} }), null);
  assert.equal(readWalletXaf(200, { balances: [{ country: "CMR", balance: "x", currency: "XAF" }] }), null);
});
