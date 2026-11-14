import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// The country and phone field (ADR 0024), on the school profile: pick a country by search, type the number its way,
// paste a full number, and the stored form is E.164.
const tag = randomBytes(3).toString("hex");
let admin: TestUser;
let before: string | null = null;

test.beforeAll(async () => {
  admin = await createUser(`phone-admin-${tag}`, "admin");
  before = (await serviceClient().from("schools").select("phone").eq("id", SEED.schoolId).single()).data?.phone ?? null;
});

test.afterAll(async () => {
  await serviceClient().from("schools").update({ phone: before }).eq("id", SEED.schoolId);
  if (admin) await deleteUser(admin);
});

test("a country is found by search, the number is written its way, and saved as E.164", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/school");
  const field = page.getByTestId("phone-field");
  await field.getByRole("button", { name: /^Country:/ }).click();
  await page.getByRole("searchbox", { name: "Search a country" }).fill("fran");
  await page.getByRole("option", { name: /France/ }).click();
  await expect(field.getByRole("button", { name: "Country: France" })).toContainText("+33");

  await page.getByLabel("Phone", { exact: true }).fill("612345678");
  await expect(page.getByLabel("Phone", { exact: true })).toHaveValue("6 12 34 56 78");
  await page.getByRole("button", { name: /^Save/ }).first().click();
  await expect.poll(async () => (await serviceClient().from("schools").select("phone").eq("id", SEED.schoolId).single()).data?.phone).toBe("+33612345678");
});

test("a number pasted with its code picks its country", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/school");
  await page.getByLabel("Phone", { exact: true }).fill("+44 7400 123456");
  await expect(page.getByTestId("phone-field").getByRole("button", { name: "Country: United Kingdom" })).toBeVisible();
  await expect(page.getByLabel("Phone", { exact: true })).toHaveValue("7400 123456");
});

test("the country and the number stay on one row on a small phone", async ({ page, context }) => {
  await page.setViewportSize({ width: 320, height: 700 });
  await signInBrowser(context, admin);
  await page.goto("/school");
  const field = page.getByTestId("phone-field");
  const country = await field.getByRole("button", { name: /^Country:/ }).boundingBox();
  const number = await page.getByLabel("Phone", { exact: true }).boundingBox();
  expect(Math.abs((country?.y ?? 0) - (number?.y ?? 1))).toBeLessThan(2);
});
