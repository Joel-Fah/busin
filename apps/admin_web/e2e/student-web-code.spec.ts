import { createHmac, randomBytes } from "node:crypto";
import { execFileSync } from "node:child_process";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// The student web app's boarding code (ADR 0021, ADR 0014): made in the browser from a key it cannot read back.
const tag = randomBytes(3).toString("hex");
let rider: TestUser;
let waiting: TestUser;

test.use({ viewport: { width: 390, height: 844 } });

/** The student's secret, read from the database the way only the server can, to check the browser's code independently. */
function secretOf(studentId: string): Buffer {
  const out = execFileSync("docker", ["exec", "supabase_db_busin", "psql", "-U", "postgres", "-tAc", `select encode(secret, 'base64') from private.qr_secrets where student_id = '${studentId}'`]).toString().trim();
  return Buffer.from(out, "base64");
}

function expectedCode(secret: Buffer, studentId: string, window: number): string {
  const date = new Intl.DateTimeFormat("en-CA", { timeZone: "Africa/Douala" }).format(new Date(window * 30_000));
  const day = createHmac("sha256", secret).update(`busin-day:${date}`).digest();
  return `busin2.${studentId}.${window}.${createHmac("sha256", day).update(`${studentId}:${window}`).digest("hex").slice(0, 20)}`;
}

test.beforeAll(async () => {
  const db = serviceClient();
  rider = await createUser(`web-code-${tag}`, "student");
  waiting = await createUser(`web-nocode-${tag}`, "student");
  for (const [user, n] of [[rider, 5], [waiting, 6]] as const) {
    await db.from("profiles").update({ matricule: `QR${tag}${n}`, phone: `+23760000000${n}`, full_name: "Amara Ngono" }).eq("id", user.id);
  }
  const { error } = await db.from("subscriptions").insert({ school_id: SEED.schoolId, student_id: rider.id, semester_id: SEED.semesterId, stop_id: SEED.stopId, status: "approved" });
  if (error) throw new Error(error.message);
});

test.afterAll(async () => {
  for (const user of [rider, waiting]) if (user) await deleteUser(user);
});

test("shows a live code the server would accept, with the student's name and number", async ({ page, context }) => {
  await signInBrowser(context, rider);
  await page.goto("/app/code");
  const ticket = page.getByTestId("boarding-ticket");
  await expect(ticket).toContainText("Live code");
  await expect(ticket).toContainText("Amara Ngono");
  await expect(ticket).toContainText(`QR${tag}5`);
  const qr = page.getByTestId("boarding-qr");
  await expect(qr).toHaveAttribute("data-code", /^busin2\./);
  const code = (await qr.getAttribute("data-code"))!;
  const window = Number(code.split(".")[2]);
  expect(code).toBe(expectedCode(secretOf(rider.id), rider.id, window));
  await expect(page.getByRole("heading", { name: "How to board" })).toBeVisible();
});

test("keeps the key in the browser where it cannot be read, and forgets it on sign-out", async ({ page, context }) => {
  await signInBrowser(context, rider);
  await page.goto("/app/code");
  await expect(page.getByTestId("boarding-qr")).toHaveAttribute("data-code", /^busin2\./);
  const kept = () =>
    page.evaluate(
      () =>
        new Promise<{ extractable: boolean } | null>((resolve) => {
          const open = indexedDB.open("busin", 1);
          open.onsuccess = () => {
            const get = open.result.transaction("boarding-keys").objectStore("boarding-keys").getAll();
            get.onsuccess = () => resolve(get.result[0] ? { extractable: get.result[0].key.extractable } : null);
          };
        }),
    );
  expect(await kept()).toEqual({ extractable: false });
  await page.goto("/app/profile");
  await page.getByRole("button", { name: "Sign out" }).click();
  await expect(page).toHaveURL(/\/app\/sign-in$/);
  expect(await kept()).toBeNull();
});

test("a student without an approved subscription is sent to subscribe", async ({ page, context }) => {
  await signInBrowser(context, waiting);
  await page.goto("/app/code");
  await expect(page.getByText("No active subscription")).toBeVisible();
  await expect(page.getByRole("link", { name: "Go to subscription" })).toHaveAttribute("href", "/app/subscription");
});
