import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// School billing and installments in the portal (ADR 0022). The seed school is billed per semester at 30,000 XAF with
// the 40-30-30 plan; every test puts that back.
const tag = randomBytes(3).toString("hex");
let admin: TestUser;
let student: TestUser;
let subscriptionId = "";

const SEEDED = { billing_period: "semester", price_xaf: 30000, installment_plan: "40-30-30" };

test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  admin = await createUser(`bill-admin-${tag}`, "admin");
  student = await createUser(`bill-student-${tag}`, "student");
  const { data, error } = await serviceClient()
    .from("subscriptions")
    .insert({
      school_id: SEED.schoolId,
      student_id: student.id,
      semester_id: SEED.semesterId,
      stop_id: SEED.stopId,
      proof_path: `${SEED.schoolId}/${student.id}/e2e-proof.jpg`,
      payment_mode: "installments",
    })
    .select("id")
    .single();
  if (error || !data) throw new Error(`could not create a subscription: ${error?.message}`);
  subscriptionId = data.id;
});

test.afterEach(async () => {
  await serviceClient().from("schools").update(SEEDED).eq("id", SEED.schoolId);
});

test.afterAll(async () => {
  if (subscriptionId) await serviceClient().from("subscriptions").delete().eq("id", subscriptionId);
  for (const user of [admin, student]) if (user) await deleteUser(user);
});

test("while billing is not set, the overview asks for it first, and the Billing page sets it", async ({ page, context }) => {
  await serviceClient().from("schools").update({ billing_period: null, price_xaf: null, installment_plan: null }).eq("id", SEED.schoolId);
  await signInBrowser(context, admin);
  await page.goto("/");
  await expect(page.getByRole("link", { name: "Set up billing" }).first()).toBeVisible();

  await page.getByRole("link", { name: "Set up billing" }).first().click();
  await expect(page).toHaveURL(/\/billing$/);
  await expect(page.getByText("Billing is not set yet")).toBeVisible();

  await page.getByLabel("Per month").check();
  await expect(page.getByText("Installments are for semester billing")).toBeVisible();
  await expect(page.getByRole("radio", { name: /In installments: 40%/ })).toBeDisabled();
  await page.getByLabel("Price of one period, in XAF").fill("5 000");
  await expect(page.getByTestId("billing-preview")).toHaveText("Students pay 5,000 XAF with their request.");
  await page.getByRole("button", { name: "Save billing" }).click();
  // The toast says it, then takes "done" off the address.
  await expect(page.getByText("Billing saved.")).toBeVisible();
  await expect(page.getByText("Billing is not set yet")).toHaveCount(0);

  const { data } = await serviceClient().from("schools").select("billing_period, price_xaf, installment_plan").eq("id", SEED.schoolId).single();
  expect(data).toEqual({ billing_period: "month", price_xaf: 5000, installment_plan: null });

  await page.goto("/");
  await expect(page.getByRole("link", { name: "Set up billing" })).toHaveCount(0);
});

test("a semester price splits into the plan's parts as it is typed", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/billing");
  await expect(page.getByLabel("Per semester")).toBeChecked();
  await page.getByLabel("Price of one period, in XAF").fill("30001");
  await expect(page.getByTestId("billing-preview")).toHaveText("Students pay 12,000 XAF, 9,000 XAF, 9,001 XAF.");
});

test("a request in installments: approving settles part 1, and a later part is marked paid", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto(`/subscriptions/${subscriptionId}`);
  await expect(page.getByText("In installments (40-30-30)")).toBeVisible();
  await expect(page.getByTestId("part-1")).toContainText("Proof to check");

  await page.getByRole("button", { name: "Approve" }).click();
  await expect(page.getByText("Subscription approved.")).toBeVisible();
  await expect(page.getByTestId("part-1")).toContainText("Paid");
  await expect(page.getByTestId("part-2")).toContainText("Not paid yet");

  await page.getByTestId("part-2").getByRole("button", { name: "Mark paid" }).click();
  await expect(page.getByText("Part marked paid.")).toBeVisible();
  await expect(page.getByTestId("part-2")).toContainText("Paid");
  await expect(page.getByTestId("part-2").getByRole("button", { name: "Mark paid" })).toHaveCount(0);

  const { data } = await serviceClient().from("subscription_installments").select("seq, status").eq("subscription_id", subscriptionId).order("seq");
  expect(data).toEqual([
    { seq: 1, status: "paid" },
    { seq: 2, status: "paid" },
    { seq: 3, status: "due" },
  ]);
});
