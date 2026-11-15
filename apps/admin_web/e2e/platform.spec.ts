import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, setLanguage, setPlatformAdmin, signInBrowser, type TestUser } from "./support";

// The platform console (ADR 0027): only listed accounts open it; everyone else gets "not found".
const tag = randomBytes(3).toString("hex");
let owner: TestUser;
let schoolAdmin: TestUser;
let student: TestUser;

test.beforeAll(async () => {
  owner = await createUser(`platform-owner-${tag}`, "admin");
  schoolAdmin = await createUser(`platform-admin-${tag}`, "admin");
  student = await createUser(`platform-student-${tag}`, "student");
  setPlatformAdmin(owner.id, true);
  setPlatformAdmin(student.id, true);
});

test.afterAll(async () => {
  setPlatformAdmin(owner.id, false);
  setPlatformAdmin(student.id, false);
  await deleteUser(owner);
  await deleteUser(schoolAdmin);
  await deleteUser(student);
});

test.use({ viewport: { width: 1280, height: 800 } });

test("a platform admin sees the totals and every school, and moves between the console and their school", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform");
  await expect(page.getByRole("heading", { name: "Platform", exact: true, level: 1 })).toBeVisible();
  await expect(page.getByTestId("platform-schools")).toContainText(/\d+ active/);
  const table = page.getByRole("table");
  await expect(table.getByRole("row").filter({ hasText: "ICT University" })).toContainText(/\d+ students, \d+ staff, \d+ admins/);

  const nav = page.getByRole("navigation", { name: "Main navigation" });
  await expect(nav.getByRole("link", { name: "Console", exact: true })).toHaveAttribute("aria-current", "page");
  // No school tabs in the console.
  await expect(nav.getByRole("link", { name: "Subscriptions", exact: true })).toHaveCount(0);

  await nav.getByRole("link", { name: "Profile", exact: true }).click();
  await expect(page).toHaveURL(/\/platform\/account$/);
  await expect(page.getByText("Platform admin", { exact: true })).toBeVisible();
  await page.getByRole("link", { name: "Open my school's portal" }).click();
  await expect(page).toHaveURL(/\/$/);

  // And back from the school portal's profile.
  await page.goto("/profile");
  await page.getByRole("link", { name: "Open the console" }).click();
  await expect(page).toHaveURL(/\/platform$/);
});

test("the console does not depend on the role inside a school", async ({ context, page }) => {
  await signInBrowser(context, student);
  await page.goto("/platform");
  await expect(page.getByRole("heading", { name: "Platform", exact: true, level: 1 })).toBeVisible();
  await page.goto("/platform/account");
  // A student has no school portal to go back to.
  await expect(page.getByRole("link", { name: "Open my school's portal" })).toHaveCount(0);
});

test("a school admin who is not listed gets not found, and no way in", async ({ context, page }) => {
  await signInBrowser(context, schoolAdmin);
  for (const path of ["/platform", "/platform/account"]) {
    // The page streams, so the status is sent before the check: the content is what says "not found" (as in the portal).
    await page.goto(path);
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
    await expect(page.getByRole("navigation", { name: "Main navigation" })).toHaveCount(0);
  }
  await page.goto("/profile");
  await expect(page.getByRole("heading", { name: "Your profile" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Open the console" })).toHaveCount(0);
});

test("a visitor who is not signed in goes to the sign-in page", async ({ page }) => {
  await page.goto("/platform");
  await expect(page).toHaveURL(/\/login$/);
});

test("the console in French", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await setLanguage(page, "fr");
  try {
    await page.goto("/platform");
    await expect(page.getByRole("heading", { name: "Plateforme", exact: true, level: 1 })).toBeVisible();
    await expect(page.getByTestId("platform-schools")).toContainText(/\d+ actives/);
  } finally {
    await setLanguage(page, "en");
  }
});
