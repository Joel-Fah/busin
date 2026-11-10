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
    // The scene under the headline is there, with its small messages.
    await expect(page.locator("[data-scene-chip]")).toHaveCount(4);
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
    await page.getByRole("button", { name: "Français", exact: true }).click();
    await expect(page.getByRole("heading", { level: 1 })).toContainText("De votre côté.");
    await expect(page.locator("[data-landing]")).toHaveAttribute("lang", "fr");
    await page.reload();
    await expect(page.getByRole("heading", { level: 1 })).toContainText("De votre côté.");
  });

  test("shows everything at once for a visitor who asked for less motion", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.goto("/");
    await expect(page.locator("[data-scene-chip]").first()).toBeVisible();
    // No starting state was applied: the message is fully opaque and not moved.
    const style = await page.locator("[data-scene-chip]").first().evaluate((el) => ({ opacity: getComputedStyle(el).opacity, transform: getComputedStyle(el).transform }));
    expect(style.opacity).toBe("1");
    expect(["none", "matrix(1, 0, 0, 1, 0, 0)"]).toContain(style.transform);
  });

  test("the navigation sits under the headline with only the tabs and the main button, then floats at the top with the rest", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto("/");
    const nav = page.getByRole("navigation", { name: "Main" });
    const h1 = page.getByRole("heading", { level: 1 });
    const h1Box = (await h1.boundingBox())!;
    expect((await nav.boundingBox())!.y).toBeGreaterThanOrEqual(h1Box.y + h1Box.height - 4);
    await expect(nav).toHaveAttribute("data-stuck", "false");
    await expect(nav.getByRole("link", { name: "Get the app" })).toBeVisible();
    // The wordmark, the two choices and the phone's menu button are folded away (and cannot be tabbed to) until the bar
    // floats; the phone's menu panel stays inert while it is closed.
    await expect(nav.locator("[inert]")).toHaveCount(4);

    await page.waitForLoadState("networkidle");
    await page.mouse.wheel(0, 1400);
    await expect(nav).toHaveAttribute("data-stuck", "true");
    const box = (await nav.boundingBox())!;
    expect(box.y).toBeGreaterThanOrEqual(0);
    expect(box.y).toBeLessThanOrEqual(16);
    await expect(nav.locator("[inert]")).toHaveCount(1);
    await expect(nav.locator("[data-nav-menu]")).toHaveAttribute("inert", "");
    await expect(nav.getByRole("link", { name: "BusIn", exact: true })).toBeVisible();
    await expect(nav.getByRole("button", { name: /^Theme/ })).toBeVisible();
    await expect(nav.getByRole("button", { name: /^Language/ })).toBeVisible();
  });

  test("when floating, one button changes the language and one cycles the theme", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto("/");
    const nav = page.getByRole("navigation", { name: "Main" });
    // The page must be running its scripts before a scroll can be noticed.
    await page.waitForLoadState("networkidle");
    await page.mouse.wheel(0, 1400);
    await expect(nav).toHaveAttribute("data-stuck", "true");

    // Language: shows the current code; a press switches to the other language.
    await expect(nav.getByRole("button", { name: /^Language/ })).toHaveText("EN");
    await nav.getByRole("button", { name: /^Language/ }).click();
    await page.mouse.wheel(0, -2000);
    await expect(page.getByRole("heading", { level: 1 })).toContainText("De votre côté.");
    await page.mouse.wheel(0, 1400);
    const frenchNav = page.getByRole("navigation", { name: /Main|Principale/ });
    await expect(frenchNav.getByRole("button", { name: /^Langue/ })).toHaveText("FR");

    // Theme: one press moves to the next choice and the page follows.
    const theme = frenchNav.getByRole("button", { name: /^Thème/ });
    await theme.click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
    await theme.click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  });

  test("has nothing wider than the screen on a phone", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    await page.getByRole("heading", { level: 1 }).waitFor();
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBeLessThanOrEqual(0);
  });

  test("a day with BusIn: on a wide screen the phone shows the step in the middle of the window", async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto("/");
    const story = page.locator(".day-story");
    await expect(story).toHaveAttribute("data-step", "0");
    await page.getByRole("heading", { name: "See it coming" }).scrollIntoViewIfNeeded();
    await page.evaluate(() => window.scrollBy(0, 1));
    await expect(story).toHaveAttribute("data-step", "2");
    await expect(page.getByRole("heading", { level: 3 })).toContainText(["Subscribe once", "Your pass, even offline", "See it coming", "Show, scan, sit"]);
  });

  test("who it helps and the privacy facts are all readable on a phone, in French too", async ({ page, context }) => {
    await context.addCookies([{ name: "locale", value: "fr", url: "http://127.0.0.1:3000" }]);
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    for (const role of ["Étudiants", "Chauffeurs", "Personnel à la porte", "Bureau de l'école", "Personne ne suit votre téléphone"]) {
      await page.getByRole("heading", { name: role, exact: true }).scrollIntoViewIfNeeded();
      await expect(page.getByRole("heading", { name: role, exact: true })).toBeVisible();
    }
  });

  test("on a phone the tabs are a row to swipe, and once the bar floats they open inside it", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    await page.waitForLoadState("networkidle");
    const nav = page.getByRole("navigation", { name: "Main" });
    const menu = nav.getByRole("button", { name: "Menu" });
    await expect(nav.locator("[data-nav-strip]").getByRole("link", { name: "A day with BusIn" })).toBeVisible();
    await expect(menu).toBeHidden();

    await page.mouse.wheel(0, 1600);
    await expect(nav).toHaveAttribute("data-stuck", "true");
    await expect(nav.locator("[data-nav-strip]")).toBeHidden();
    await menu.click();
    await expect(menu).toHaveAttribute("aria-expanded", "true");
    const panel = nav.locator("[data-nav-menu]");
    await panel.getByRole("link", { name: "Questions" }).click();
    await expect(menu).toHaveAttribute("aria-expanded", "false");
    await expect(panel.getByRole("link", { name: "Questions" })).toBeHidden();

    await menu.click();
    await page.keyboard.press("Escape");
    await expect(menu).toHaveAttribute("aria-expanded", "false");
  });
});

test.describe("the credits page", () => {
  test("is public, linked from the footer, and names what the site uses", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("navigation", { name: "Legal and credits" }).getByRole("link", { name: "Credits" }).click();
    await expect(page).toHaveURL(/\/credits$/);
    await expect(page.getByRole("heading", { level: 1, name: "Credits" })).toBeVisible();
    for (const name of ["Thiings", "Pexels", "Hugeicons", "Plus Jakarta Sans", "GSAP"]) {
      await expect(page.getByRole("link", { name })).toHaveAttribute("rel", "noopener noreferrer");
    }
    await expect(page.getByRole("link", { name: "A bus stop seen from above" })).toHaveAttribute("href", /pexels\.com\/photo\/21576182/);
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
