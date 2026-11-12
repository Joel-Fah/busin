import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");

let admin: TestUser;
let student: TestUser;

test.beforeAll(async () => {
  admin = await createUser(`dev-admin-${tag}`, "admin");
  student = await createUser(`dev-student-${tag}`, "student");
});

test.afterAll(async () => {
  for (const user of [admin, student]) {
    if (user) await deleteUser(user);
  }
});

async function signInThroughForm(page: import("@playwright/test").Page, user: { email: string; password: string }) {
  await page.goto("/dev/login");
  await page.getByLabel("Email").fill(user.email);
  await page.getByLabel("Password").fill(user.password);
  await page.getByRole("button", { name: "Sign in" }).click();
}

test.describe("development sign-in (local development only)", () => {
  test("the login page links to it", async ({ page }) => {
    await page.goto("/login");
    await page.getByRole("link", { name: "Local development sign-in" }).click();
    await expect(page).toHaveURL(/\/dev\/login$/);
    await expect(page.getByRole("heading", { name: "Local development sign-in" })).toBeVisible();
    await expect(page.getByRole("note")).toContainText("Development only");
  });

  test("an administrator signs in and reaches the overview", async ({ page }) => {
    await signInThroughForm(page, admin);
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Overview", level: 1 })).toBeVisible();
  });

  test("a wrong password is refused with a clear message", async ({ page }) => {
    await signInThroughForm(page, { email: admin.email, password: "definitely-wrong" });
    await expect(page).toHaveURL(/\/dev\/login\?error=invalid$/);
    await expect(page.getByRole("alert").filter({ hasText: "Wrong email or password" })).toBeVisible();
  });

  test("signing in does not make anyone an administrator", async ({ page }) => {
    await signInThroughForm(page, student);
    await expect(page).toHaveURL(/\/no-access$/);
    await expect(page.getByRole("heading", { name: "No access" })).toBeVisible();
  });
});
