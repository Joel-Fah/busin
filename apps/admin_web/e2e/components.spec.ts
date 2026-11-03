import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");
let admin: TestUser;

test.beforeAll(async () => {
  admin = await createUser(`comp-${tag}`, "admin");
});

test.afterAll(async () => {
  await deleteUser(admin);
});

test.use({ viewport: { width: 1280, height: 800 } });

test.beforeEach(async ({ context, page }) => {
  await signInBrowser(context, admin);
  await page.goto("/styleguide");
});

test.describe("side sheet", () => {
  test("floats with a margin on every side and rounded corners", async ({ page }) => {
    await page.getByRole("button", { name: "Open the side sheet" }).click();
    const sheet = page.getByRole("dialog", { name: "A floating side sheet" });
    await expect(sheet).toBeVisible();
    await expect.poll(async () => (await sheet.boundingBox())!.x + (await sheet.boundingBox())!.width).toBeLessThanOrEqual(1280 - 12);
    const box = (await sheet.boundingBox())!;
    expect(box.y).toBeGreaterThanOrEqual(12);
    expect(box.y + box.height).toBeLessThanOrEqual(800 - 12);
    expect(await sheet.evaluate((el) => parseFloat(getComputedStyle(el).borderTopLeftRadius))).toBeGreaterThanOrEqual(28);
    expect(await sheet.evaluate((el) => parseFloat(getComputedStyle(el).borderBottomRightRadius))).toBeGreaterThanOrEqual(28);
  });

  test("closes with Escape, with its button and with a click outside", async ({ page }) => {
    const sheet = page.getByRole("dialog", { name: "A floating side sheet" });
    const open = page.getByRole("button", { name: "Open the side sheet" });

    await open.click();
    await expect(sheet).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(sheet).toBeHidden();

    await open.click();
    await sheet.getByRole("button", { name: "Close" }).click();
    await expect(sheet).toBeHidden();

    await open.click();
    await expect(sheet).toBeVisible();
    await page.mouse.click(20, 400);
    await expect(sheet).toBeHidden();
  });

  test("the title carries the rough marker highlight", async ({ page }) => {
    await page.getByRole("button", { name: "Open the side sheet" }).click();
    const sheet = page.getByRole("dialog", { name: "A floating side sheet" });
    await expect(sheet.locator(".texture-rough")).toHaveCount(1);
  });
});

test.describe("modal", () => {
  test("asks before a destructive choice and can be dismissed", async ({ page }) => {
    await page.getByRole("button", { name: "Delete a stop" }).click();
    const modal = page.getByRole("dialog", { name: "Delete this stop?" });
    await expect(modal).toBeVisible();
    await modal.getByRole("button", { name: "Keep it" }).click();
    await expect(modal).toBeHidden();
    await expect(page.getByText(/Confirmed/)).toHaveCount(0);

    await page.getByRole("button", { name: "Delete a stop" }).click();
    await modal.getByRole("button", { name: "Delete", exact: true }).click();
    await expect(modal).toBeHidden();
    await expect(page.getByText(/Confirmed/)).toBeVisible();
  });

  test("closes with Escape", async ({ page }) => {
    await page.getByRole("button", { name: "Delete a stop" }).click();
    const modal = page.getByRole("dialog", { name: "Delete this stop?" });
    await page.keyboard.press("Escape");
    await expect(modal).toBeHidden();
  });
});

test.describe("tabs with counters", () => {
  test("shows counters and marks the current tab", async ({ page }) => {
    const tabs = page.getByRole("navigation", { name: "Filter by status" });
    await expect(tabs.getByRole("link", { name: /To review/ })).toContainText("12");
    await expect(tabs.getByRole("link", { name: /To review/ })).toHaveAttribute("aria-current", "page");
    await tabs.getByRole("link", { name: /Approved/ }).click();
    await expect(tabs.getByRole("link", { name: /Approved/ })).toHaveAttribute("aria-current", "page");
    await expect(page.getByTestId("tabs-demo-state")).toHaveText("Showing: approved");
  });

  test("the track hugs its tabs instead of filling the row", async ({ page }) => {
    const tabs = page.getByRole("navigation", { name: "Filter by status" });
    const last = (await tabs.getByRole("link", { name: /Expired/ }).boundingBox())!;
    const track = (await tabs.boundingBox())!;
    expect(track.x + track.width - (last.x + last.width)).toBeLessThan(16);
  });

  test("unselected tabs have no background and the highlight follows the current one", async ({ page }) => {
    const tabs = page.getByRole("navigation", { name: "Filter by status" });
    await expect(tabs.getByRole("link", { name: /Rejected/ })).toHaveCSS("background-color", "rgba(0, 0, 0, 0)");
    await tabs.getByRole("link", { name: /Rejected/ }).click();
    const target = (await tabs.getByRole("link", { name: /Rejected/ }).boundingBox())!;
    const bar = tabs.locator("span[aria-hidden]").first();
    await expect.poll(async () => Math.abs((await bar.boundingBox())!.x - target.x)).toBeLessThan(3);
  });
});

test.describe("form controls", () => {
  test("dropdown, date and time fields hold their values", async ({ page }) => {
    await page.getByLabel("Bus", { exact: true }).selectOption({ label: "LT 456 CD" });
    await expect(page.getByLabel("Bus", { exact: true })).toHaveValue("2");
    await page.getByLabel("First day").fill("2027-01-15");
    await expect(page.getByLabel("First day")).toHaveValue("2027-01-15");
    await page.getByLabel("Departure").fill("06:45");
    await expect(page.getByLabel("Departure")).toHaveValue("06:45");
    await page.getByLabel("Start time").fill("2026-11-02T07:30");
    await expect(page.getByLabel("Start time")).toHaveValue("2026-11-02T07:30");
  });

  test("checkboxes toggle and a disabled one does not", async ({ page }) => {
    const remember = page.getByRole("checkbox", { name: "Remember me" });
    await expect(remember).not.toBeChecked();
    await page.getByText("Remember me", { exact: true }).click();
    await expect(remember).toBeChecked();
    await page.getByText("Remember me", { exact: true }).click();
    await expect(remember).not.toBeChecked();
    await expect(page.getByRole("checkbox", { name: "Not available" })).toBeDisabled();
  });

  test("radio choices are exclusive and keyboard reachable", async ({ page }) => {
    const mobile = page.getByRole("radio", { name: "Mobile money" });
    const cash = page.getByRole("radio", { name: "Cash at the office" });
    await expect(mobile).toBeChecked();
    await page.getByText("Cash at the office", { exact: true }).click();
    await expect(cash).toBeChecked();
    await expect(mobile).not.toBeChecked();
    await cash.focus();
    await page.keyboard.press("ArrowUp");
    await expect(mobile).toBeChecked();
  });

  test("switches toggle by click and by keyboard", async ({ page }) => {
    const service = page.getByRole("switch", { name: "In service" });
    await expect(service).not.toBeChecked();
    await page.getByText("In service", { exact: true }).click();
    await expect(service).toBeChecked();
    await service.focus();
    await page.keyboard.press("Space");
    await expect(service).not.toBeChecked();
  });

  test("a focused control shows a visible focus ring", async ({ page }) => {
    await page.getByRole("checkbox", { name: "Remember me" }).focus();
    await page.keyboard.press("Shift+Tab");
    await page.keyboard.press("Tab");
    const face = page.locator("label", { hasText: "Remember me" }).locator("span[aria-hidden]");
    expect(await face.evaluate((el) => getComputedStyle(el).outlineStyle)).not.toBe("none");
  });
});

test.describe("menu", () => {
  test("opens, moves with the arrow keys, acts, and closes with Escape", async ({ page }) => {
    const button = page.getByRole("button", { name: "More actions" });
    await button.click();
    const menu = page.getByRole("menu", { name: "More actions" });
    await expect(menu).toBeVisible();

    await page.keyboard.press("ArrowDown");
    await expect(menu.getByRole("menuitem", { name: "Edit" })).toBeFocused();
    await page.keyboard.press("ArrowDown");
    await expect(menu.getByRole("menuitem", { name: "Duplicate" })).toBeFocused();
    await page.keyboard.press("ArrowUp");
    await page.keyboard.press("ArrowUp");
    await expect(menu.getByRole("menuitem", { name: "Delete" })).toBeFocused();

    await page.keyboard.press("Escape");
    await expect(menu).toBeHidden();
    await expect(button).toBeFocused();

    await button.click();
    await page.getByRole("menuitem", { name: "Duplicate" }).click();
    await expect(page.getByTestId("menu-demo-state")).toHaveText("Last action: Duplicate");
    await expect(menu).toBeHidden();
  });

  test("opens toward free space and stays on screen", async ({ page }) => {
    await page.getByRole("button", { name: "More actions" }).click();
    const box = (await page.getByRole("menu", { name: "More actions" }).boundingBox())!;
    expect(box.x).toBeGreaterThanOrEqual(0);
    expect(box.x + box.width).toBeLessThanOrEqual(1280);
  });

  test("the delete choice is styled as danger and a click outside closes the menu", async ({ page }) => {
    await page.getByRole("button", { name: "More actions" }).click();
    const del = page.getByRole("menuitem", { name: "Delete" });
    const danger = await del.evaluate((el) => {
      const probe = document.createElement("span");
      probe.style.color = "var(--bad)";
      document.body.append(probe);
      const ok = getComputedStyle(el).color === getComputedStyle(probe).color;
      probe.remove();
      return ok;
    });
    expect(danger).toBe(true);
    await page.mouse.click(5, 400);
    await expect(page.getByRole("menu", { name: "More actions" })).toBeHidden();
  });
});
