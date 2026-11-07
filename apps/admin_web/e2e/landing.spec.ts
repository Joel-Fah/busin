import { expect, test } from "@playwright/test";

import { createUser, deleteUser, signInBrowser, type TestUser } from "./support";

test.describe("the landing page", () => {
  test("is the root address for a visitor who is not signed in, and says what BusIn is", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveURL(/\/$/);
    await expect(page).toHaveTitle(/BusIn: your campus ride, handled/);
    await expect(page.getByRole("heading", { level: 1 })).toContainText("Your bus. On time. On your side.");

    // Every section the nav points at exists, with its anchor.
    for (const id of ["day", "people", "private", "download", "schools", "faq"]) {
      await expect(page.locator(`#${id}`)).toHaveCount(1);
    }
    await expect(page.getByRole("navigation", { name: "Main" }).getByRole("link", { name: "Get the app" })).toHaveAttribute("href", "#download");
    // The scene under the headline is there, with its pictures.
    await expect(page.locator("[data-scene-bus]")).toHaveCount(1);
  });

  test("may be indexed, and the portal may not", async ({ page, request }) => {
    await page.goto("/");
    await expect(page.locator('meta[name="robots"]')).toHaveAttribute("content", /index/);
    await expect(page.locator('meta[name="robots"]')).not.toHaveAttribute("content", /noindex/);
    await expect(page.locator('link[rel="canonical"]')).toHaveAttribute("href", /^https?:\/\/[^/]+\/?$/);

    const robots = await (await request.get("/robots.txt")).text();
    expect(robots).toContain("Disallow: /login");
    expect(robots).toContain("Sitemap:");
    const sitemap = await (await request.get("/sitemap.xml")).text();
    expect(sitemap).toContain("<loc>");
  });

  test("speaks French when asked, and keeps the choice", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("navigation", { name: /Main|Principale/ }).getByRole("button", { name: "Français" }).click();
    await expect(page.getByRole("heading", { level: 1 })).toContainText("De votre côté.");
    await expect(page.locator("[data-landing]")).toHaveAttribute("lang", "fr");
    await page.reload();
    await expect(page.getByRole("heading", { level: 1 })).toContainText("De votre côté.");
  });

  test("shows everything at once for a visitor who asked for less motion", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.goto("/");
    await expect(page.locator("[data-scene-bus]")).toBeVisible();
    // No starting state was applied: the bus is fully opaque and not moved.
    const style = await page.locator("[data-scene-bus]").evaluate((el) => ({ opacity: getComputedStyle(el).opacity, transform: getComputedStyle(el).transform }));
    expect(style.opacity).toBe("1");
    expect(["none", "matrix(1, 0, 0, 1, 0, 0)"]).toContain(style.transform);
  });

  test("the navigation sits under the headline, then stays at the top as the page scrolls", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto("/");
    const nav = page.getByRole("navigation", { name: "Main" });
    const h1 = page.getByRole("heading", { level: 1 });
    const h1Bottom = (await h1.boundingBox())!.y + (await h1.boundingBox())!.height;
    expect((await nav.boundingBox())!.y).toBeGreaterThanOrEqual(h1Bottom - 4);
    await expect(nav).toHaveAttribute("data-stuck", "false");

    await page.mouse.wheel(0, 1400);
    await expect(nav).toHaveAttribute("data-stuck", "true");
    expect(Math.abs((await nav.boundingBox())!.y)).toBeLessThanOrEqual(1);
  });

  test("the choices are icons and language codes, with names for assistive technology", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto("/");
    const nav = page.getByRole("navigation", { name: "Main" });
    await expect(nav.getByRole("button", { name: "Dark" })).toHaveText("");
    await expect(nav.getByRole("button", { name: "Français" })).toHaveText("FR");
    await expect(nav.getByRole("button", { name: "English" })).toHaveText("EN");
  });

  test("has nothing wider than the screen on a phone", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    await page.getByRole("heading", { level: 1 }).waitFor();
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBeLessThanOrEqual(0);
  });

  test("the menu opens on a phone without any script", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    await page.locator("summary[aria-label='Menu']").click();
    await expect(page.getByRole("link", { name: "A day with BusIn" })).toBeVisible();
  });
});

test.describe("signed in", () => {
  let admin: TestUser;
  test.beforeAll(async () => {
    admin = await createUser("landing-admin", "admin");
  });
  test.afterAll(async () => {
    if (admin) await deleteUser(admin);
  });

  test("the root address is still the overview, not the landing page", async ({ context, page }) => {
    await signInBrowser(context, admin);
    await page.goto("/");
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { level: 1 }).filter({ hasText: "On your side." })).toHaveCount(0);
    await expect(page.getByRole("navigation").getByRole("link", { name: "Subscriptions" })).toBeVisible();
  });
});
