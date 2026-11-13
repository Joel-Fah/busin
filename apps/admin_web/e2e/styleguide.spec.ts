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
    const width = () => thread.evaluate((el) => parseFloat(getComputedStyle(el).strokeWidth));

    expect(await offset()).toBe(0);
    expect(await width()).toBeCloseTo(1.5, 1);
    await empty.hover();
    await expect.poll(offset).toBeLessThan(-30);
    // It thickens a little, not a lot, and settles at the hover width.
    await expect.poll(width).toBeGreaterThan(2.2);
    expect(await width()).toBeLessThanOrEqual(2.3);
    await page.mouse.move(0, 0);
    await expect.poll(offset).toBe(0);
    await expect.poll(width).toBeCloseTo(1.5, 1);
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
    await page.setViewportSize({ width: 1600, height: 900 });
    await page.goto("/styleguide");
    const rail = page.getByRole("navigation", { name: "Sections" });
    await expect(rail).toBeVisible();

    // It sits to the right of the content, in the margin, and takes none of its width.
    const railBox = await rail.boundingBox();
    const contentBox = await page.getByRole("heading", { name: "Styleguide", level: 1 }).boundingBox();
    expect(railBox!.x).toBeGreaterThan(contentBox!.x + 1000);
    expect(await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)).toBe(0);
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
    for (const name of [/blue and white city bus/, /warm evening light/, /people waiting together/, /white school bus parked/]) {
      await expect(page.getByRole("img", { name })).toBeVisible();
    }
    await expect(page.locator("#imagery img[src*='illustrations%2Fbus.webp'], #imagery img[src*='/illustrations/bus.webp']").first()).toBeVisible();
  });

  test("documents texture and draws the grain from an inline SVG, not an image file", async ({ page }) => {
    await page.goto("/styleguide");
    await expect(page.getByRole("heading", { name: "Texture", level: 2 })).toBeVisible();
    const grain = page.locator("#texture .texture-grain").first();
    expect(await grain.evaluate((el) => getComputedStyle(el, "::before").backgroundImage)).toContain("data:image/svg+xml");
    expect(await grain.evaluate((el) => getComputedStyle(el, "::before").mixBlendMode)).toBe("soft-light");
    // The rough filter is defined once on the page.
    await expect(page.locator("filter#busin-rough")).toHaveCount(1);
  });

  test("the banner carries grain and stays readable", async ({ page }) => {
    await page.goto("/styleguide");
    const banner = page.locator("header.texture-grain");
    await expect(banner).toBeVisible();
    await expect(banner.getByRole("heading", { name: "Styleguide", level: 1 })).toBeVisible();
  });

  test("documents tables, pagination, notices, empty and loading states, the sticky toolbar and column filters", async ({ page }) => {
    await page.goto("/styleguide");
    for (const title of ["Table", "Pagination", "Notices", "Empty and loading states", "Sticky toolbar", "Column filters"]) {
      await expect(page.getByRole("heading", { name: title, level: 3 })).toBeVisible();
    }

    // The table example is a real table with column headings.
    const table = page.locator("#components").getByRole("table").first();
    await expect(table.getByRole("columnheader")).toHaveCount(4);
    await expect(table.getByRole("row")).toHaveCount(4);

    // The pager shows the range and both steps.
    const pager = page.getByRole("navigation", { name: "Pages" });
    await expect(pager.getByRole("link", { name: "Previous" })).toBeVisible();
    await expect(pager.getByRole("link", { name: "Next" })).toBeVisible();
    await expect(page.getByText("Showing 21 to 40 of 87")).toBeVisible();

    // Notices: failures are alerts, the others are polite statuses.
    await expect(page.getByRole("alert").filter({ hasText: "could not be saved" })).toBeVisible();
    await expect(page.getByRole("status").filter({ hasText: "Stop saved." })).toBeVisible();

    // The column filter example opens a panel of choices from its heading, and the chips can be removed.
    const filters = page.locator("#components");
    await filters.getByRole("button", { name: /^Stop/ }).first().click();
    await expect(page.getByRole("dialog", { name: "Stop" }).getByRole("link", { name: "Olezoa" })).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(filters.getByRole("group", { name: "Active filters" }).getByRole("link", { name: /Remove filter: Stop/ })).toBeVisible();
  });

  test("the portal has a themed icon", async ({ page }) => {
    await page.goto("/styleguide");
    await expect(page.locator('link[rel="icon"][href*="icon.svg"]')).toHaveCount(1);
    const response = await page.request.get("/icon.svg");
    expect(response.ok()).toBe(true);
    expect(await response.text()).toContain("prefers-color-scheme:dark");
  });

  test("the page does not scroll sideways on a phone", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/styleguide");
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBe(0);
  });

  test("is shown without the portal navigation bar and links back to the portal", async ({ page }) => {
    await page.goto("/styleguide");
    await expect(page.getByRole("navigation", { name: "Main navigation" })).toHaveCount(0);
    await page.getByRole("link", { name: "Back to the portal" }).click();
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("navigation", { name: "Main navigation" })).toBeVisible();
  });

  test("exports the guide as Markdown for agents and as a PDF", async ({ page }) => {
    await page.goto("/styleguide");
    const exports = page.getByRole("group", { name: "Export the styleguide" });

    const [md] = await Promise.all([page.waitForEvent("download"), exports.getByRole("link", { name: "Markdown for agents" }).click()]);
    expect(md.suggestedFilename()).toBe("busin-design-system.md");
    const text = await (await import("node:fs/promises")).readFile((await md.path())!, "utf8");
    expect(text).toContain("## How to use this file");
    expect(text).toContain("## Hard rules");
    expect(text).toContain("```json");

    const [pdf] = await Promise.all([page.waitForEvent("download"), exports.getByRole("link", { name: "PDF" }).click()]);
    expect(pdf.suggestedFilename()).toBe("busin-design-system.pdf");
    const bytes = await (await import("node:fs/promises")).readFile((await pdf.path())!);
    expect(bytes.subarray(0, 5).toString()).toBe("%PDF-");
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

  test(`${label} cannot download its exports`, async ({ context }) => {
    await signInBrowser(context, who());
    for (const path of ["/styleguide/export/markdown", "/styleguide/export/pdf"]) {
      const response = await context.request.get(path, { maxRedirects: 0 });
      expect(response.status(), path).toBeGreaterThanOrEqual(300);
      expect(response.status(), path).toBeLessThan(400);
      expect(response.headers().location ?? "", path).toMatch(/\/no-access$/);
    }
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/styleguide");
  await expect(page).toHaveURL(/\/login$/);
});
