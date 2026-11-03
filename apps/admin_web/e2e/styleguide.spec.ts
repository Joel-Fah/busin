import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");

let admin: TestUser;
let staff: TestUser;
let student: TestUser;

test.beforeAll(async () => {
  admin = await createUser(`sg-admin-${tag}`, "admin");
  staff = await createUser(`sg-staff-${tag}`, "staff");
  student = await createUser(`sg-student-${tag}`, "student");
});

test.afterAll(async () => {
  await Promise.all([deleteUser(admin), deleteUser(staff), deleteUser(student)]);
});

test.describe("administrator reading the styleguide", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("documents the system section by section", async ({ page }) => {
    await page.goto("/styleguide");
    await expect(page.getByRole("heading", { name: "Styleguide", level: 1 })).toBeVisible();
    for (const title of ["Voice and tone", "Colour", "Typography", "Shape", "Contour", "Icons", "Components"]) {
      await expect(page.getByRole("heading", { name: title, level: 2 })).toBeVisible();
    }
  });

  test("lists contrast results and none fail", async ({ page }) => {
    await page.goto("/styleguide");
    await expect(page.getByText(/ : 1 AA/).first()).toBeVisible();
    await expect(page.getByText(/ : 1 fails/)).toHaveCount(0);
  });

  test("the theme toggle forces a theme and remembers it", async ({ page }) => {
    await page.goto("/styleguide");
    await page.getByRole("button", { name: "Dark" }).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");

    await page.reload();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    await expect(page.getByRole("button", { name: "Dark" })).toHaveAttribute("aria-pressed", "true");

    await page.getByRole("button", { name: "System" }).click();
    await expect(page.locator("html")).not.toHaveAttribute("data-theme", /.+/);
  });

  test("the contour is a stitched thread", async ({ page }) => {
    await page.goto("/styleguide");
    await expect(page.locator("#contour .contour-thread").first()).toHaveCSS("stroke-dasharray", /\d+px,? \d+px/);
  });

  test("the thread on an empty state slides forward on hover and back on leave", async ({ page }) => {
    await page.goto("/styleguide");
    const empty = page.locator("#contour").getByText("Nothing to review right now");
    const thread = empty.locator("xpath=ancestor::div[1]").locator(".contour-thread");
    const offset = () => thread.evaluate((el) => parseFloat(getComputedStyle(el).strokeDashoffset));

    expect(await offset()).toBe(0);
    await empty.hover();
    await expect.poll(offset).toBeLessThan(-30);
    await page.mouse.move(0, 0);
    await expect.poll(offset).toBe(0);
  });

  test("the thread on a card stays still, and a button thread keeps its colour on hover", async ({ page }) => {
    await page.goto("/styleguide");
    const cardThread = page.locator("#contour .contour-thread").first();
    await page.locator("#contour").getByText("A card", { exact: true }).hover();
    await page.waitForTimeout(1000);
    expect(await cardThread.evaluate((el) => getComputedStyle(el).strokeDashoffset)).toBe("0px");

    const button = page.locator("#components").getByRole("button", { name: "Save stop" });
    const thread = button.locator(".contour-thread");
    const colour = () => thread.evaluate((el) => getComputedStyle(el).stroke);
    const before = await colour();
    await button.hover();
    await page.waitForTimeout(1000);
    expect(await colour()).toBe(before);
    expect(await thread.evaluate((el) => parseFloat(getComputedStyle(el).strokeDashoffset))).toBeLessThan(-20);
  });

  test("the section rail follows the reading position and jumps on click", async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto("/styleguide");
    const rail = page.getByRole("navigation", { name: "Sections" });
    await expect(rail).toBeVisible();
    await rail.getByRole("link", { name: "Colour" }).click();
    await expect(rail.getByRole("link", { name: "Colour" })).toHaveAttribute("aria-current", "location");
    await expect(page.getByRole("heading", { name: "Colour", level: 2 })).toBeInViewport();
  });

  test("unselected theme choices have no background of their own", async ({ page }) => {
    await page.goto("/styleguide");
    await expect(page.getByRole("button", { name: "Light" })).toHaveCSS("background-color", "rgba(0, 0, 0, 0)");
  });

  test("shows the banner photo, the 3D objects and the photographs", async ({ page }) => {
    await page.goto("/styleguide");
    await expect(page.getByRole("img", { name: /brand strategy board/ })).toBeVisible();
    await expect(page.getByRole("img", { name: /yellow school bus turning/ })).toBeVisible();
    await expect(page.locator("#imagery img[src*='3d%2Fbus.webp'], #imagery img[src*='/3d/bus.webp']").first()).toBeVisible();
  });

  test("the portal has a themed icon", async ({ page }) => {
    await page.goto("/styleguide");
    await expect(page.locator('link[rel="icon"][href*="icon.svg"]')).toHaveCount(1);
    const response = await page.request.get("/icon.svg");
    expect(response.ok()).toBe(true);
    expect(await response.text()).toContain("prefers-color-scheme:dark");
  });

  // The old sidebar navigation is 746px wide and stretches every page on a phone. The floating
  // navigation bar replaces it in the shell PR; turn this test on there.
  test.fixme("the page does not scroll sideways on a phone", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/styleguide");
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBe(0);
  });

  test("is not linked from the navigation", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("link", { name: /styleguide/i })).toHaveCount(0);
  });
});

for (const [label, who] of [
  ["a student", () => student],
  ["a staff member", () => staff],
] as const) {
  test(`${label} cannot open the styleguide`, async ({ page, context }) => {
    await signInBrowser(context, who());
    await page.goto("/styleguide");
    await expect(page).toHaveURL(/\/no-access$/);
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/styleguide");
  await expect(page).toHaveURL(/\/login$/);
});
