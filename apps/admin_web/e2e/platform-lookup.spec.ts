import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, serviceClient, setPlatformAdmin, signInBrowser, type TestUser } from "./support";

// Account lookup in the platform console (ADR 0027, slice 7).
const tag = randomBytes(3).toString("hex");
let owner: TestUser;
let student: TestUser;

test.beforeAll(async () => {
  owner = await createUser(`lookup-owner-${tag}`, "admin");
  student = await createUser(`lookup-student-${tag}`, "student", "pending");
  setPlatformAdmin(owner.id, true);
});

test.afterAll(async () => {
  setPlatformAdmin(owner.id, false);
  await deleteUser(student);
  await deleteUser(owner);
});

test.use({ viewport: { width: 1280, height: 900 } });

test("an account is found by its exact email, and the lookup is recorded", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform/lookup");
  await page.getByLabel("Exact email").fill(student.email.toUpperCase());
  await page.getByRole("button", { name: "Look up" }).click();

  const result = page.getByTestId("lookup-result");
  await expect(result).toContainText(student.email);
  await expect(result).toContainText("Student");
  await expect(result).toContainText("Pending");
  await expect(result.getByRole("link", { name: "ICT University" })).toHaveAttribute("href", /\/platform\/schools\//);
  // The email never goes into the address.
  expect(page.url()).not.toContain("@");

  const { data } = await serviceClient().from("platform_audit").select("action, target_id, details").eq("actor_id", owner.id).eq("action", "account.lookup");
  expect(data).toEqual([{ action: "account.lookup", target_id: student.id, details: { found: true } }]);
});

test("an unknown email finds nothing", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform/lookup");
  await page.getByLabel("Exact email").fill(`nobody-${tag}@example.org`);
  await page.getByRole("button", { name: "Look up" }).click();
  await expect(page.getByTestId("lookup-result")).toContainText("No account with this email.");
});

test("a school admin cannot open it", async ({ context, page }) => {
  const admin = await createUser(`lookup-admin-${tag}`, "admin");
  try {
    await signInBrowser(context, admin);
    await page.goto("/platform/lookup");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  } finally {
    await deleteUser(admin);
  }
});
