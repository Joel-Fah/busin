// Sends a real test push to the phones a local user has registered, straight to Firebase.
// For checking the Firebase setup on a device before anything is deployed. Local development only.
//
//   npm run dev:push -- path/to/firebase-service-account.json you@ictuniversity.edu.cm [approved|rejected] [en|fr]
//
// The service account key is a secret: keep the file outside the repository and never commit it. This script only
// reads it from the path you give and sends nothing anywhere but to Firebase.
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";

import { buildMessage, classify, createAssertion } from "../supabase/functions/_shared/push.ts";

const [keyPath, email, outcome = "approved", language = "en"] = process.argv.slice(2);
if (!keyPath || !email) {
  console.error("Usage: npm run dev:push -- <service-account.json> <email> [approved|rejected] [en|fr]");
  process.exit(1);
}
if (!/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+$/.test(email)) {
  console.error("That does not look like an email address.");
  process.exit(1);
}
if (!["approved", "rejected"].includes(outcome) || !["en", "fr"].includes(language)) {
  console.error("The outcome is approved or rejected, the language en or fr.");
  process.exit(1);
}

const account = JSON.parse(readFileSync(keyPath, "utf8"));
for (const field of ["client_email", "private_key", "token_uri", "project_id"]) {
  if (!account[field]) {
    console.error(`The key file has no ${field}. Is it a Firebase service account key?`);
    process.exit(1);
  }
}

const psql = (sql) =>
  execFileSync("docker", ["exec", "-i", "supabase_db_busin", "psql", "-U", "postgres", "-v", "ON_ERROR_STOP=1", "-tA", "-c", sql], { encoding: "utf8" }).trim();

const tokens = psql(
  `select t.token from public.device_tokens t join public.profiles p on p.id = t.user_id where p.email = '${email}' order by t.last_seen_at desc`,
)
  .split("\n")
  .filter(Boolean);
if (tokens.length === 0) {
  console.error(`${email} has no registered phone. Open the app signed in as that user, allow notifications (Subscription tab, with a pending request), and try again.`);
  process.exit(1);
}

const now = Math.floor(Date.now() / 1000);
const tokenResponse = await fetch(account.token_uri, {
  method: "POST",
  headers: { "content-type": "application/x-www-form-urlencoded" },
  body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: await createAssertion(account, now) }),
});
if (!tokenResponse.ok) {
  console.error(`Google refused the service account (${tokenResponse.status}). Is the key current and for this project?`);
  process.exit(1);
}
const { access_token } = await tokenResponse.json();

const endpoint = `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`;
for (const token of tokens) {
  const message = buildMessage(token, `subscription_${outcome}`, null, language);
  const response = await fetch(endpoint, {
    method: "POST",
    headers: { authorization: `Bearer ${access_token}`, "content-type": "application/json" },
    body: JSON.stringify(message),
  });
  const body = await response.json().catch(() => null);
  const verdict = classify({ status: response.status, body });
  console.log(`${token.slice(0, 12)}...  ${response.status}  ${verdict}${verdict === "sent" ? "" : "  " + JSON.stringify(body)}`);
}
