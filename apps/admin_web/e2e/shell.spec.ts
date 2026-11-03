import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");
let admin: TestUser;

test.beforeAll(async () => {
  admin = await createUser(`shell-${tag}`, "admin");
});

test.afterAll(async () => {
  await deleteUser(admin);
});

const TABS = ["Overview", "Subscriptions", "People", "Stops", "Trips", "Boardings", "Semesters", "Buses"];

test.describe("floating navigation on a wide screen", () => {
  test.use({ viewport: { width: 1280, height: 800 } });

  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("shows every tab with its label and marks the current one", async ({ page }) => {
    await page.goto("/trips");
    const nav = page.getByRole("navigation", { name: "Main navigation" });
    for (const name of TABS) await expect(nav.getByRole("link", { name, exact: true })).toBeVisible();
    await expect(nav.getByRole("link", { name: "Trips", exact: true })).toHaveAttribute("aria-current", "page");
    await expect(nav.getByRole("link", { name: "Buses", exact: true })).not.toHaveAttribute("aria-current", "page");
  });

  test("the profile tab has a label like the others", async ({ page }) => {
    await page.goto("/");
    const profile = page.getByRole("navigation", { name: "Main navigation" }).getByRole("link", { name: "Profile", exact: true });
    await expect(profile).toBeVisible();
    await expect(profile).toContainText("Profile");
  });

  test("tabs have room between them", async ({ page }) => {
    await page.goto("/");
    const nav = page.getByRole("navigation", { name: "Main navigation" });
    const a = await nav.getByRole("link", { name: "Overview", exact: true }).boundingBox();
    const b = await nav.getByRole("link", { name: "Subscriptions", exact: true }).boundingBox();
    expect(b!.x - (a!.x + a!.width)).toBeGreaterThanOrEqual(6);
  });

  test("the indicator sits behind the current tab and follows it to the next page", async ({ page }) => {
    await page.goto("/trips");
    const nav = page.getByRole("navigation", { name: "Main navigation" });
    const indicator = nav.getByTestId("nav-indicator");
    const near = async (name: string) => {
      const tab = (await nav.getByRole("link", { name, exact: true }).boundingBox())!;
      await expect
        .poll(async () => {
          const box = (await indicator.boundingBox())!;
          return Math.abs(box.x - tab.x) + Math.abs(box.width - tab.width) + Math.abs(box.y - tab.y);
        })
        .toBeLessThan(3);
    };
    await expect(indicator).toHaveCSS("opacity", "1");
    await near("Trips");
    await nav.getByRole("link", { name: "Buses", exact: true }).click();
    await near("Buses");
    await nav.getByRole("link", { name: "Profile", exact: true }).click();
    await near("Profile");
  });

  test("moves between pages and keeps its place", async ({ page }) => {
    await page.goto("/");
    const nav = page.getByRole("navigation", { name: "Main navigation" });
    await nav.getByRole("link", { name: "Semesters", exact: true }).click();
    await expect(page).toHaveURL(/\/semesters$/);
    await expect(nav.getByRole("link", { name: "Semesters", exact: true })).toHaveAttribute("aria-current", "page");
  });

  test("stays at the bottom of the screen while the page scrolls", async ({ page }) => {
    // A short window makes the profile page taller than the screen, so it scrolls.
    await page.setViewportSize({ width: 1280, height: 420 });
    await page.goto("/profile");
    const nav = page.getByRole("navigation", { name: "Main navigation" });
    const before = await nav.boundingBox();
    await page.mouse.wheel(0, 3000);
    await page.waitForTimeout(300);
    expect(await page.evaluate(() => window.scrollY)).toBeGreaterThan(100);
    const after = await nav.boundingBox();
    expect(after?.y).toBe(before?.y);
    expect((after?.y ?? 0) + (after?.height ?? 0)).toBeLessThanOrEqual(420);
  });

  test("reaches the profile from the picture at the end of the bar", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("link", { name: "Profile", exact: true }).click();
    await expect(page).toHaveURL(/\/profile$/);
    await expect(page.getByRole("heading", { name: "Your profile", level: 1 })).toBeVisible();
  });

  test("the logo goes back to the overview", async ({ page }) => {
    await page.goto("/people");
    await page.getByRole("link", { name: "Go to the overview" }).click();
    await expect(page).toHaveURL(/\/$/);
  });

  test("sign out is styled as a danger action", async ({ page }) => {
    await page.goto("/profile");
    const matches = await page.getByRole("button", { name: "Sign out" }).evaluate((el) => {
      const probe = document.createElement("span");
      probe.style.background = "var(--bad-bg)";
      probe.style.color = "var(--bad)";
      document.body.append(probe);
      const want = getComputedStyle(probe);
      const got = getComputedStyle(el);
      const result = got.backgroundColor === want.backgroundColor && got.color === want.color;
      probe.remove();
      return result;
    });
    expect(matches).toBe(true);
  });

  test("the profile page holds theme, language and sign out", async ({ page }) => {
    await page.goto("/profile");
    await expect(page.getByRole("button", { name: "Dark" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Français" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Sign out" })).toBeVisible();
    await page.getByRole("button", { name: "Dark" }).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    await page.getByRole("button", { name: "System" }).click();
  });

  test("the overview help opens a side sheet with examples and closes with Escape", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Help" }).click();
    const sheet = page.getByRole("dialog", { name: "How the overview works" });
    await expect(sheet).toBeVisible();
    await expect(sheet.getByText("A student paid and is waiting")).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(sheet).toBeHidden();
  });

  test("the help sheet closes with its button", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Help" }).click();
    const sheet = page.getByRole("dialog", { name: "How the overview works" });
    await sheet.getByRole("button", { name: "Close" }).click();
    await expect(sheet).toBeHidden();
  });
});

for (const [label, width, height] of [
  ["a phone", 390, 844],
  ["a tablet in portrait", 820, 1180],
] as const) {
  test.describe(`floating navigation on ${label}`, () => {
    test.use({ viewport: { width, height } });

    test.beforeEach(async ({ context }) => {
      await signInBrowser(context, admin);
    });

    test("shows the current page and opens the tabs from the menu button", async ({ page }) => {
      await page.goto("/trips");
      const nav = page.getByRole("navigation", { name: "Main navigation" });
      await expect(nav.locator("p", { hasText: "You are on Trips" })).toBeVisible();
      await expect(nav.getByRole("link", { name: "Buses", exact: true })).toBeHidden();

      await nav.getByRole("button", { name: "Menu" }).click();
      for (const name of TABS) await expect(nav.getByRole("link", { name, exact: true })).toBeVisible();

      await nav.getByRole("link", { name: "Buses", exact: true }).click();
      await expect(page).toHaveURL(/\/buses$/);
      await expect(nav.getByRole("link", { name: "Buses", exact: true })).toBeHidden();
    });

    test("closes the menu with Escape", async ({ page }) => {
      await page.goto("/");
      const nav = page.getByRole("navigation", { name: "Main navigation" });
      await nav.getByRole("button", { name: "Menu" }).click();
      await expect(nav.getByRole("link", { name: "People", exact: true })).toBeVisible();
      await page.keyboard.press("Escape");
      await expect(nav.getByRole("link", { name: "People", exact: true })).toBeHidden();
    });

    test("no page scrolls sideways", async ({ page }) => {
      for (const path of ["/", "/trips", "/stops", "/profile", "/semesters"]) {
        await page.goto(path);
        const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
        expect(overflow, path).toBe(0);
      }
    });
  });
}

test.describe("opening animation", () => {
  test.use({ reducedMotion: "no-preference", viewport: { width: 1280, height: 800 } });

  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("covers the first load with the logo, can be skipped, and then reveals the bar once", async ({ page }) => {
    await page.goto("/");
    const cover = page.locator(".brand-intro");
    await expect(cover).toBeVisible();

    await page.mouse.click(10, 10);
    await expect(cover).toBeHidden({ timeout: 8000 });
    await expect(page.locator("html")).not.toHaveAttribute("data-intro", /.*/);
    expect(await page.evaluate(() => sessionStorage.getItem("busin-intro"))).toBe("1");

    const nav = page.getByRole("navigation", { name: "Main navigation" });
    await expect(nav).toHaveCSS("opacity", "1", { timeout: 8000 });

    // Moving between pages does not replay anything.
    await nav.getByRole("link", { name: "People", exact: true }).click();
    await expect(page).toHaveURL(/\/people$/);
    await expect(cover).toBeHidden();
    await expect(nav).toHaveCSS("opacity", "1");
  });

  test("the indicator stretches while it travels between far tabs", async ({ page }) => {
    // Visit the target first so the dev server has compiled it and the slide starts right after the click.
    await page.goto("/buses");
    await page.goto("/");
    await page.mouse.click(10, 10);
    await expect(page.locator(".brand-intro")).toBeHidden({ timeout: 8000 });
    const nav = page.getByRole("navigation", { name: "Main navigation" });
    await expect(nav).toHaveCSS("opacity", "1", { timeout: 8000 });
    const indicator = nav.getByTestId("nav-indicator");
    const start = (await indicator.boundingBox())!;
    const target = (await nav.getByRole("link", { name: "Buses", exact: true }).boundingBox())!;

    await nav.getByRole("link", { name: "Buses", exact: true }).click();
    let widest = 0;
    for (let i = 0; i < 60; i++) {
      const box = await indicator.boundingBox();
      if (box) widest = Math.max(widest, box.width);
      await page.waitForTimeout(20);
    }
    expect(widest).toBeGreaterThan(Math.max(start.width, target.width) * 2);
    await expect.poll(async () => Math.abs((await indicator.boundingBox())!.x - target.x)).toBeLessThan(3);
  });

  test("does not show the logo again later in the same session", async ({ page }) => {
    await page.goto("/");
    await page.mouse.click(10, 10);
    await expect(page.locator(".brand-intro")).toBeHidden({ timeout: 8000 });
    await page.goto("/trips");
    await expect(page.locator(".brand-intro")).toBeHidden();
    await expect(page.getByRole("navigation", { name: "Main navigation" })).toHaveCSS("opacity", "1", { timeout: 8000 });
  });
});

test.describe("reduced motion", () => {
  test("skips the logo intro and shows the bar straight away", async ({ page, context }) => {
    await signInBrowser(context, admin);
    await page.goto("/");
    await expect(page.locator("html")).not.toHaveAttribute("data-intro", /.*/);
    await expect(page.locator("html")).not.toHaveAttribute("data-reveal", /.*/);
    await expect(page.locator(".brand-intro")).toBeHidden();
    await expect(page.getByRole("navigation", { name: "Main navigation" })).toBeVisible();
  });
});

test("signed-out visitors do not reach the profile", async ({ page }) => {
  await page.goto("/profile");
  await expect(page).toHaveURL(/\/login$/);
});
