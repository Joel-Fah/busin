import { randomBytes } from "node:crypto";

import { expect, test, type Page } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// Billing in the student web app (ADR 0022): the price, how the student pays and the preference, the parts, and monthly
// billing. The seed school is billed per semester at 30,000 XAF with the 40-30-30 plan; the monthly test puts that back.
const tag = randomBytes(3).toString("hex");
let student: TestUser;
let monthly: TestUser;
const PNG = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==", "base64");
const SEEDED = { billing_period: "semester", price_xaf: 30000, installment_plan: "40-30-30" };

test.use({ viewport: { width: 390, height: 844 } });
test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  student = await createUser(`web-bill-${tag}`, "student");
  monthly = await createUser(`web-month-${tag}`, "student");
  for (const [user, n] of [
    [student, 51],
    [monthly, 52],
  ] as const) {
    await serviceClient().from("profiles").update({ matricule: `BIL${n}${tag}`, phone: `+2376000000${n}`, full_name: "Amara Ngono" }).eq("id", user.id);
  }
});

test.afterAll(async () => {
  const db = serviceClient();
  await db.from("schools").update(SEEDED).eq("id", SEED.schoolId);
  for (const user of [student, monthly]) {
    if (!user) continue;
    const { data } = await db.storage.from("proofs").list(`${SEED.schoolId}/${user.id}`);
    if (data?.length) await db.storage.from("proofs").remove(data.map((f) => `${SEED.schoolId}/${user.id}/${f.name}`));
    await deleteUser(user);
  }
});

async function fill(page: Page) {
  const { data } = await serviceClient().from("stops").select("name").eq("id", SEED.stopId).single();
  await page.getByRole("button", { name: /Your stop/ }).click();
  await page.getByRole("dialog").getByLabel("Search stops").fill(data!.name.slice(0, 5));
  await page.getByRole("dialog").getByRole("button", { name: data!.name }).click();
  await page.getByTestId("proof-input").setInputFiles({ name: "receipt.png", mimeType: "image/png", buffer: PNG });
  await expect(page.getByText("Photo added")).toBeVisible();
}

test("pays in installments without a preference, keeps it, and sends the proof of part 2", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/subscription");
  await expect(page.getByText("30,000 XAF for the semester")).toBeVisible();
  await fill(page);
  await page.getByRole("button", { name: "Send request" }).click();
  await expect(page.getByText("Choose how you pay.")).toBeVisible();

  await page.getByRole("radio", { name: "In installments" }).click();
  await expect(page.getByTestId("payment-note")).toContainText("12,000 XAF, 9,000 XAF, 9,000 XAF");
  await page.getByRole("button", { name: "Send request" }).click();
  await page.getByTestId("preference-sheet").getByRole("button", { name: "Save as my preference" }).click();
  await expect(page.getByTestId("status-card")).toContainText("Request sent");
  await expect(page.getByTestId("part-1")).toContainText("Proof sent, waiting for the school");

  const db = serviceClient();
  const { data: me } = await db.from("profiles").select("payment_preference").eq("id", student.id).single();
  expect(me?.payment_preference).toBe("installments");
  const { data: sub } = await db.from("subscriptions").select("id, payment_mode, amount_xaf, installment_plan").eq("student_id", student.id).single();
  expect(sub).toMatchObject({ payment_mode: "installments", amount_xaf: 30000, installment_plan: "40-30-30" });

  // The school approves: part 1 is paid, and part 2 takes a proof.
  await db.from("subscriptions").update({ status: "approved", reviewed_at: new Date().toISOString() }).eq("id", sub!.id);
  await page.reload();
  await expect(page.getByTestId("part-1")).toContainText("Paid");
  await page.getByTestId("part-2").getByRole("button", { name: "Send proof of payment" }).click();
  await page.getByTestId("part-proof-input").setInputFiles({ name: "part2.png", mimeType: "image/png", buffer: PNG });
  await expect(page.getByText("Proof sent. Your school will check it.")).toBeVisible();
  await expect(page.getByTestId("part-2")).toContainText("Proof sent, waiting for the school");
  const { data: part } = await db.from("subscription_installments").select("status, proof_path").eq("subscription_id", sub!.id).eq("seq", 2).single();
  expect(part?.status).toBe("submitted");
});

test("the profile keeps how the student prefers to pay", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/profile");
  await page.getByRole("link", { name: /How you prefer to pay/ }).click();
  await expect(page).toHaveURL(/\/app\/settings\/payment$/);
  await expect(page.getByRole("radio", { name: "In installments" })).toHaveAttribute("aria-checked", "true");
  await page.getByRole("radio", { name: "In full" }).click();
  await expect(page.getByText("Saved as how you prefer to pay.")).toBeVisible();
  const { data } = await serviceClient().from("profiles").select("payment_preference").eq("id", student.id).single();
  expect(data?.payment_preference).toBe("full");
});

test("with monthly billing, the student asks for a month", async ({ page, context }) => {
  await serviceClient().from("schools").update({ billing_period: "month", price_xaf: 5000, installment_plan: null }).eq("id", SEED.schoolId);
  await signInBrowser(context, monthly);
  await page.goto("/app/subscription");
  await expect(page.getByText("5,000 XAF a month")).toBeVisible();
  await expect(page.getByRole("radio", { name: "In installments" })).toHaveCount(0);
  const months = page.getByRole("radiogroup", { name: "Month" }).getByRole("radio");
  const count = await months.count();
  expect(count).toBeGreaterThanOrEqual(1);
  await months.nth(count - 1).click();
  await fill(page);
  await page.getByRole("button", { name: "Send request" }).click();
  await expect(page.getByTestId("status-card")).toContainText("Request sent");
  const { data } = await serviceClient().from("subscriptions").select("billing_period, amount_xaf, period_start, period_end").eq("student_id", monthly.id).single();
  expect(data).toMatchObject({ billing_period: "month", amount_xaf: 5000 });
  expect(data?.period_start).toMatch(/^\d{4}-\d{2}-(01|\d{2})$/);
});
