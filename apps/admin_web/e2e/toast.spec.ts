import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");
let admin: TestUser;

test.beforeAll(async () => {
  admin = await createUser(`toast-admin-${tag}`, "admin");
});

test.afterAll(async () => {
  if (admin) await deleteUser(admin);
});

test("a toast leaves by itself, waits while the pointer is on it, then carries on", async ({ page }) => {
  await page.goto("/dev/login");
  await page.getByLabel("Email").fill(admin.email);
  await page.getByLabel("Password").fill(admin.password);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL(/\/$/);
  await page.goto("/styleguide");

  const toast = page.locator(".toast-in, .toast-out").filter({ hasText: "Stop saved." });

  // Left alone, a success goes after about 2.8 s.
  await page.getByRole("button", { name: /Success/ }).click();
  await expect(toast).toBeVisible();
  await expect(toast).toBeHidden({ timeout: 6000 });

  // With the pointer on it, it stays well past that.
  await page.getByRole("button", { name: /Success/ }).click();
  await expect(toast).toBeVisible();
  await toast.hover();
  await page.waitForTimeout(4500);
  await expect(toast).toBeVisible();
  await expect(toast.locator(".toast-ring")).toHaveCSS("animation-play-state", "paused");

  // Moving away lets the rest of the time run out.
  await page.mouse.move(5, 600);
  await expect(toast).toBeHidden({ timeout: 6000 });
});
