import { execFileSync, execSync } from "node:child_process";
import { randomBytes, randomUUID } from "node:crypto";
import path from "node:path";

import { createServerClient } from "@supabase/ssr";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { BrowserContext } from "@playwright/test";

import type { Database } from "../lib/database.types";

/** Seed data from supabase/seed.sql (local development only). */
export const SEED = {
  schoolId: "00000000-0000-4000-8000-000000000001",
  semesterId: "00000000-0000-4000-8000-000000000011",
  stopId: "00000000-0000-4000-8000-000000000021",
  domain: "ictuniversity.edu.cm",
};

export const BASE_URL = "http://127.0.0.1:3000";

type LocalKeys = { url: string; publishableKey: string; serviceKey: string };

let cachedKeys: LocalKeys | undefined;

/** Reads the local stack's keys at run time, so no key is stored in the repository. */
export function localKeys(): LocalKeys {
  if (cachedKeys) return cachedKeys;
  const repoRoot = path.resolve(__dirname, "../../..");
  const output = execSync("npx supabase status -o env", { cwd: repoRoot, encoding: "utf8" });
  const read = (name: string) => {
    const match = output.match(new RegExp(`^${name}="?([^"\\r\\n]+)"?`, "m"));
    if (!match) throw new Error(`Could not read ${name} from "supabase status". Is the local stack running?`);
    return match[1];
  };
  cachedKeys = {
    url: read("API_URL"),
    publishableKey: read("PUBLISHABLE_KEY"),
    serviceKey: read("SERVICE_ROLE_KEY"),
  };
  return cachedKeys;
}

/** A client that bypasses Row Level Security. For test setup and checks only. */
export function serviceClient(): SupabaseClient<Database> {
  const { url, serviceKey } = localKeys();
  return createClient<Database>(url, serviceKey, { auth: { persistSession: false } });
}

export type TestUser = { id: string; email: string; password: string };

/** Runs SQL in the local database container. Local development only. */
function sql(statement: string): void {
  execFileSync(
    "docker",
    ["exec", "-i", "supabase_db_busin", "psql", "-U", "postgres", "-v", "ON_ERROR_STOP=1", "-q", "-c", statement],
    { encoding: "utf8" },
  );
}

/**
 * Creates a user that looks like a Google sign-up. The Auth admin API marks every user it
 * creates as an email sign-up, which the sign-up trigger rightly refuses, so the row is
 * inserted directly. A password is set only so the test can open a real session.
 * All interpolated values are generated here and contain only hex digits, dashes and the seed domain.
 */
export async function createUser(
  label: string,
  role: "student" | "staff" | "admin",
  status: "verified" | "suspended" = "verified",
): Promise<TestUser> {
  const id = randomUUID();
  const email = `e2e-${label}-${randomBytes(4).toString("hex")}@${SEED.domain}`;
  const password = randomBytes(16).toString("hex");

  sql(`
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', '${id}', 'authenticated', 'authenticated',
      '${email}', extensions.crypt('${password}', extensions.gen_salt('bf')), now(),
      '{"provider":"google","providers":["google"]}',
      '{"full_name":"E2E ${label}"}', now(), now(), '', '', '', ''
    );
    insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
    values (gen_random_uuid(), '${id}', '${id}', 'google',
      '{"sub":"${id}","email":"${email}"}', now(), now(), now());
    update public.profiles set role = '${role}', status = '${status}' where id = '${id}';
  `);

  return { id, email, password };
}

/** Removes a user and anything the tests created for them. */
export async function deleteUser(user: TestUser): Promise<void> {
  const admin = serviceClient();
  await admin.from("subscriptions").delete().eq("student_id", user.id);
  await admin.auth.admin.deleteUser(user.id);
}

/** Opens a real session for the user and gives the browser the same cookies the app would set. */
export async function signInBrowser(context: BrowserContext, user: TestUser): Promise<void> {
  const { url, publishableKey } = localKeys();
  let captured: { name: string; value: string }[] = [];

  const supabase = createServerClient<Database>(url, publishableKey, {
    cookies: {
      getAll: () => [],
      setAll: (list) => {
        captured = list.map(({ name, value }) => ({ name, value }));
      },
    },
  });

  const { error } = await supabase.auth.signInWithPassword({ email: user.email, password: user.password });
  if (error) throw new Error(`sign-in failed: ${error.message}`);

  await context.addCookies(captured.map(({ name, value }) => ({ name, value, url: BASE_URL })));
}

/** Creates a subscription request for a student, as the app would (status starts as pending). */
export async function createSubscription(studentId: string): Promise<string> {
  const { data, error } = await serviceClient()
    .from("subscriptions")
    .insert({
      school_id: SEED.schoolId,
      student_id: studentId,
      semester_id: SEED.semesterId,
      stop_id: SEED.stopId,
    })
    .select("id")
    .single();
  if (error || !data) throw new Error(`could not create a subscription: ${error?.message}`);
  return data.id;
}
