import assert from "node:assert/strict";
import { generateKeyPairSync, verify } from "node:crypto";
import { test } from "node:test";

import {
  asLocale,
  buildMessage,
  classify,
  createAssertion,
  isKind,
  processBatch,
  sameSecret,
  type Claimed,
  type Deps,
  type SendResult,
} from "./push.ts";

const token = (n: number) => `token-number-${n}-xxxxxxxxxxxxxxxx`;

function rig(answers: Record<string, SendResult | Error>) {
  const sent: string[] = [];
  const completed: [number, string | null][] = [];
  const dropped: string[] = [];
  const deps: Deps = {
    send: async (m) => {
      sent.push(m.message.token);
      const answer = answers[m.message.token] ?? { status: 200, body: {} };
      if (answer instanceof Error) throw answer;
      return answer;
    },
    completeNotification: async (id, error) => void completed.push([id, error]),
    dropToken: async (t) => void dropped.push(t),
  };
  return { deps, sent, completed, dropped };
}

const row = (id: number, tokens: string[], kind = "subscription_approved", locale = "en"): Claimed => ({
  id,
  kind,
  ref_id: "51000000-0000-4000-8000-000000000001",
  tokens: tokens.map((t) => ({ token: t, platform: "android", locale })),
});

test("a message carries wording in the phone's language and only ids as data", () => {
  const en = buildMessage(token(1), "subscription_approved", "ref-1", "en");
  assert.equal(en.message.token, token(1));
  assert.equal(en.message.notification.title, "You are subscribed");
  assert.deepEqual(en.message.data, { kind: "subscription_approved", ref_id: "ref-1" });

  const fr = buildMessage(token(1), "subscription_rejected", null, "fr");
  assert.equal(fr.message.notification.title, "Demande non approuvée");
  assert.deepEqual(fr.message.data, { kind: "subscription_rejected" });
});

test("no personal text is ever put in a notification", () => {
  for (const kind of ["subscription_approved", "subscription_rejected"] as const) {
    for (const locale of ["en", "fr"] as const) {
      const { title, body } = buildMessage(token(1), kind, "x", locale).message.notification;
      assert.ok(title.length > 0 && body.length > 0);
      assert.doesNotMatch(`${title} ${body}`, /@|matricule|reason:|motif :/i);
    }
  }
});

test("kinds and languages are checked, with English as the fallback", () => {
  assert.equal(isKind("subscription_approved"), true);
  assert.equal(isKind("anything_else"), false);
  assert.equal(asLocale("fr"), "fr");
  assert.equal(asLocale("de"), "en");
});

test("an FCM answer is sorted into sent, dead token, retry or fatal", () => {
  assert.equal(classify({ status: 200, body: { name: "projects/x/messages/1" } }), "sent");
  assert.equal(classify({ status: 404, body: { error: { status: "NOT_FOUND" } } }), "dead-token");
  assert.equal(classify({ status: 400, body: { error: { status: "INVALID_ARGUMENT", message: "The registration token is not a valid FCM registration token" } } }), "dead-token");
  assert.equal(classify({ status: 400, body: { error: { details: [{ errorCode: "UNREGISTERED" }] } } }), "dead-token");
  assert.equal(classify({ status: 429, body: {} }), "retry");
  assert.equal(classify({ status: 503, body: {} }), "retry");
  assert.equal(classify({ status: 0, body: "network error" }), "retry");
  assert.equal(classify({ status: 401, body: { error: { status: "UNAUTHENTICATED" } } }), "fatal");
  assert.equal(classify({ status: 400, body: { error: { status: "INVALID_ARGUMENT", message: "Invalid JSON payload" } } }), "fatal");
});

test("every phone is sent to, and a clean batch is completed without error", async () => {
  const { deps, sent, completed, dropped } = rig({});
  const report = await processBatch(deps, [row(1, [token(1), token(2)]), row(2, [token(3)], "subscription_rejected", "fr")]);
  assert.deepEqual(sent, [token(1), token(2), token(3)]);
  assert.deepEqual(completed, [[1, null], [2, null]]);
  assert.deepEqual(dropped, []);
  assert.deepEqual(report, { processed: 2, sent: 3, deadTokens: 0, failed: 0 });
});

test("a student with no phone is finished, not retried forever", async () => {
  const { deps, sent, completed } = rig({});
  const report = await processBatch(deps, [row(1, [])]);
  assert.deepEqual(sent, []);
  assert.deepEqual(completed, [[1, null]]);
  assert.equal(report.failed, 0);
});

test("a dead token is forgotten and the notification still counts as delivered to the rest", async () => {
  const { deps, completed, dropped } = rig({ [token(1)]: { status: 404, body: { error: { status: "NOT_FOUND" } } } });
  const report = await processBatch(deps, [row(1, [token(1), token(2)])]);
  assert.deepEqual(dropped, [token(1)]);
  assert.deepEqual(completed, [[1, null]]);
  assert.deepEqual(report, { processed: 1, sent: 1, deadTokens: 1, failed: 0 });
});

test("a retryable failure on one phone keeps the notification queued but still tries the others", async () => {
  const { deps, sent, completed } = rig({ [token(1)]: { status: 503, body: {} } });
  const report = await processBatch(deps, [row(1, [token(1), token(2)])]);
  assert.deepEqual(sent, [token(1), token(2)]);
  assert.deepEqual(completed, [[1, "retry: 503"]]);
  assert.equal(report.failed, 1);
  assert.equal(report.sent, 1);
});

test("a network error is a retry, not a crash", async () => {
  const { deps, completed } = rig({ [token(1)]: new Error("connection reset") });
  await processBatch(deps, [row(1, [token(1)])]);
  assert.deepEqual(completed, [[1, "retry: 0"]]);
});

test("a fatal answer is reported with its status and does not abort the batch", async () => {
  const { deps, completed } = rig({ [token(1)]: { status: 401, body: { error: { status: "UNAUTHENTICATED" } } } });
  await processBatch(deps, [row(1, [token(1)]), row(2, [token(2)])]);
  assert.deepEqual(completed, [[1, "fatal: 401"], [2, null]]);
});

test("an unknown kind is reported once and not sent", async () => {
  const { deps, sent, completed } = rig({});
  const report = await processBatch(deps, [row(1, [token(1)], "something_new")]);
  assert.deepEqual(sent, []);
  assert.equal(completed[0][0], 1);
  assert.match(completed[0][1] ?? "", /unknown kind something_new/);
  assert.equal(report.failed, 1);
});

test("the service account assertion is a valid RS256 JWT for the messaging scope", async () => {
  const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
  const account = { client_email: "push@busin-test.iam.gserviceaccount.com", private_key: pem, token_uri: "https://oauth2.googleapis.com/token", project_id: "busin-test" };

  const jwt = await createAssertion(account, 1_800_000_000);
  const [header, claims, signature] = jwt.split(".");
  const decode = (s: string) => JSON.parse(Buffer.from(s, "base64url").toString("utf8"));
  assert.deepEqual(decode(header), { alg: "RS256", typ: "JWT" });
  assert.deepEqual(decode(claims), {
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: account.token_uri,
    iat: 1_800_000_000,
    exp: 1_800_003_600,
  });
  const ok = verify("RSA-SHA256", Buffer.from(`${header}.${claims}`), publicKey, Buffer.from(signature, "base64url"));
  assert.equal(ok, true, "the signature verifies with the matching public key");
  assert.doesNotMatch(jwt, /PRIVATE KEY/);
});

test("secrets are compared in full, whatever their length", () => {
  assert.equal(sameSecret("correct-horse", "correct-horse"), true);
  assert.equal(sameSecret("correct-horse", "correct-horsf"), false);
  assert.equal(sameSecret("short", "a-much-longer-value"), false);
  assert.equal(sameSecret("", "x"), false);
});
