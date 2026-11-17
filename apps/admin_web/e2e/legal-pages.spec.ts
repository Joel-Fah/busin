import { expect, test } from "@playwright/test";

// The public legal pages (the links the app stores ask for): the same texts as the apps, readable signed out.
test("the privacy policy is public, and says how to delete an account", async ({ page }) => {
  const response = await page.goto("/privacy");
  expect(response?.ok()).toBe(true);
  await expect(page).toHaveURL(/\/legal\/privacy$/);
  await expect(page.getByRole("heading", { name: "Privacy policy", level: 1 })).toBeVisible();
  await expect(page.getByRole("heading", { name: "In short" })).toBeVisible();
  await expect(page.getByText("delete your account yourself there")).toBeVisible();
  await expect(page.getByRole("link", { name: "Terms of use" }).first()).toHaveAttribute("href", "/legal/terms");
});

test("the terms and the acceptable use are public too, and an unknown page is not found", async ({ page }) => {
  await page.goto("/terms");
  await expect(page).toHaveURL(/\/legal\/terms$/);
  await expect(page.getByRole("heading", { name: "Terms of use", level: 1 })).toBeVisible();
  await page.goto("/legal/acceptable-use");
  await expect(page.getByRole("heading", { name: "Acceptable use", level: 1 })).toBeVisible();
  const missing = await page.goto("/legal/cookies");
  expect(missing?.status()).toBe(404);
});

test("the landing footer links to them", async ({ page }) => {
  await page.goto("/");
  const legal = page.getByRole("navigation", { name: "Legal and credits" });
  await expect(legal.getByRole("link", { name: "Privacy" })).toHaveAttribute("href", "/legal/privacy");
  await expect(legal.getByRole("link", { name: "Terms of use" })).toHaveAttribute("href", "/legal/terms");
});

test("the payments and refunds policy is public, and linked from the footer", async ({ page }) => {
  const response = await page.goto("/legal/payments");
  expect(response?.ok()).toBe(true);
  await expect(page.getByRole("heading", { name: "Payments and refunds", level: 1 })).toBeVisible();
  await expect(page.getByText("A payment that does not go through takes nothing.")).toBeVisible();
  await expect(page.getByText("The mobile money fee is not refunded", { exact: false })).toBeVisible();
  await page.goto("/");
  const legal = page.getByRole("navigation", { name: "Legal and credits" });
  await expect(legal.getByRole("link", { name: "Payments and refunds" })).toHaveAttribute("href", "/legal/payments");
});
