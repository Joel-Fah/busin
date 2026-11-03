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

test.describe("scroll lock", () => {
  async function scrolledPage(page: import("@playwright/test").Page) {
    await page.getByRole("heading", { name: "Side sheet and modal" }).scrollIntoViewIfNeeded();
    await page.evaluate(() => window.scrollBy(0, 200));
    return page.evaluate(() => window.scrollY);
  }

  test("the page cannot scroll behind an open side sheet, and can again after it closes", async ({ page }) => {
    const before = await scrolledPage(page);
    await page.getByRole("button", { name: "Open the side sheet" }).click();
    const sheet = page.getByRole("dialog", { name: "A floating side sheet" });
    await expect(sheet).toBeVisible();
    await expect(page.locator("html")).toHaveClass(/scroll-locked/);
    await page.mouse.move(30, 300);
    await page.mouse.wheel(0, 600);
    await page.waitForTimeout(300);
    expect(await page.evaluate(() => window.scrollY)).toBe(before);

    await page.keyboard.press("Escape");
    await expect(sheet).toBeHidden();
    await expect(page.locator("html")).not.toHaveClass(/scroll-locked/);
    await page.mouse.wheel(0, 400);
    await expect.poll(() => page.evaluate(() => window.scrollY)).toBeGreaterThan(before);
  });

  test("the page cannot scroll behind an open modal", async ({ page }) => {
    const before = await scrolledPage(page);
    await page.getByRole("button", { name: "Delete a stop" }).click();
    await expect(page.getByRole("dialog", { name: "Delete this stop?" })).toBeVisible();
    await page.mouse.move(30, 300);
    await page.mouse.wheel(0, 600);
    await page.waitForTimeout(300);
    expect(await page.evaluate(() => window.scrollY)).toBe(before);
    await page.keyboard.press("Escape");
    await expect(page.locator("html")).not.toHaveClass(/scroll-locked/);
  });

  test("the modal title carries the rough marker like the sheet", async ({ page }) => {
    await page.getByRole("button", { name: "Delete a stop" }).click();
    await expect(page.getByRole("dialog", { name: "Delete this stop?" }).locator(".texture-rough")).toHaveCount(1);
  });
});

test.describe("dropdown", () => {
  test("opens a list drawn in the design system and picks with the mouse", async ({ page }) => {
    const bus = page.getByRole("combobox", { name: "Bus" });
    await bus.scrollIntoViewIfNeeded();
    await expect(bus).toContainText("Choose a bus");
    await bus.click();
    const list = page.getByRole("listbox", { name: "Bus" });
    await expect(list).toBeVisible();
    await expect(list.getByRole("option")).toHaveCount(3);
    await list.getByRole("option", { name: "LT 456 CD" }).click();
    await expect(list).toBeHidden();
    await expect(bus).toContainText("LT 456 CD");
  });

  test("works with the keyboard, skips disabled options and jumps by typing", async ({ page }) => {
    const bus = page.getByRole("combobox", { name: "Bus" });
    await bus.focus();
    await page.keyboard.press("ArrowDown");
    const list = page.getByRole("listbox", { name: "Bus" });
    await expect(list).toBeVisible();
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("ArrowDown");
    // The third option is disabled, so the highlight wraps to the first.
    await expect(bus).toHaveAttribute("aria-activedescendant", /option-0$/);
    await page.keyboard.press("Enter");
    await expect(bus).toContainText("LT 123 AB");

    const direction = page.getByRole("combobox", { name: "Direction" });
    await direction.focus();
    await page.keyboard.press("Space");
    // Sent in one go inside the page, so a slow machine cannot spread the letters past the typing window.
    await direction.evaluate((el) => {
      for (const key of "going h") el.dispatchEvent(new KeyboardEvent("keydown", { key, bubbles: true }));
    });
    await page.keyboard.press("Enter");
    await expect(direction).toContainText("Going home");

    await direction.focus();
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("Escape");
    await expect(page.getByRole("listbox", { name: "Direction" })).toBeHidden();
  });

  test("opens upward when there is no room below", async ({ page }) => {
    const bus = page.getByRole("combobox", { name: "Bus" });
    await bus.evaluate((el) => el.scrollIntoView({ block: "end" }));
    await bus.click();
    const panel = page.getByRole("listbox", { name: "Bus" }).locator("xpath=..");
    await expect(panel).toHaveAttribute("data-side", "top");
    const box = (await panel.boundingBox())!;
    const trigger = (await bus.boundingBox())!;
    expect(box.y + box.height).toBeLessThanOrEqual(trigger.y);
  });

  test("opens downward when there is room", async ({ page }) => {
    const bus = page.getByRole("combobox", { name: "Bus" });
    await bus.evaluate((el) => el.scrollIntoView({ block: "start" }));
    await bus.click();
    await expect(page.getByRole("listbox", { name: "Bus" }).locator("xpath=..")).toHaveAttribute("data-side", "bottom");
  });
});

test.describe("date picker", () => {
  test("shows the chosen date, opens a calendar and picks a day", async ({ page }) => {
    const field = page.getByRole("button", { name: "First day" });
    await field.scrollIntoViewIfNeeded();
    await expect(field).toContainText("September 7, 2026");
    await field.click();
    const calendar = page.getByRole("dialog", { name: "First day" });
    await expect(calendar).toBeVisible();
    await expect(calendar.getByText("September 2026")).toBeVisible();
    await calendar.getByRole("gridcell", { name: "September 15, 2026" }).click();
    await expect(calendar).toBeHidden();
    await expect(field).toContainText("September 15, 2026");
  });

  test("moves between months and with the keyboard", async ({ page }) => {
    const field = page.getByRole("button", { name: "First day" });
    await field.click();
    const calendar = page.getByRole("dialog", { name: "First day" });
    await calendar.getByRole("button", { name: "Next month" }).click();
    await expect(calendar.getByText("October 2026")).toBeVisible();
    await calendar.getByRole("button", { name: "Previous month" }).click();
    await expect(calendar.getByText("September 2026")).toBeVisible();

    // The focus starts on the chosen day: 7 September. Right is the 8th, down is the 15th.
    await expect(calendar.getByRole("gridcell", { name: "September 7, 2026" })).toBeFocused();
    await page.keyboard.press("ArrowRight");
    await page.keyboard.press("ArrowDown");
    await expect(calendar.getByRole("gridcell", { name: "September 15, 2026" })).toBeFocused();
    await page.keyboard.press("PageDown");
    await expect(calendar.getByText("October 2026")).toBeVisible();
    await expect(calendar.getByRole("gridcell", { name: "October 15, 2026" })).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(field).toContainText("October 15, 2026");
    await expect(field).toBeFocused();
  });

  test("Escape closes without changing the date", async ({ page }) => {
    const field = page.getByRole("button", { name: "First day" });
    await field.click();
    await page.keyboard.press("Escape");
    await expect(page.getByRole("dialog", { name: "First day" })).toBeHidden();
    await expect(field).toContainText("September 7, 2026");
  });

  test("marks today", async ({ page }) => {
    await page.getByRole("button", { name: "First day" }).click();
    const calendar = page.getByRole("dialog", { name: "First day" });
    // Today only appears in the visible month, so jump there with the Today button.
    await calendar.getByRole("button", { name: "Today" }).click();
    await page.getByRole("button", { name: "First day" }).click();
    await expect(page.getByRole("dialog", { name: "First day" }).locator('[aria-current="date"]')).toHaveCount(1);
  });
});

test.describe("time picker", () => {
  test("picks an hour and then a minute, and closes on the minute", async ({ page }) => {
    const field = page.getByRole("button", { name: "Departure" });
    await field.scrollIntoViewIfNeeded();
    await expect(field).toContainText("07:30");
    await field.click();
    const panel = page.getByRole("dialog", { name: "Departure" });
    await panel.getByRole("listbox", { name: "Hours" }).getByRole("option", { name: "08" }).click();
    await expect(field).toContainText("08:30");
    await expect(panel).toBeVisible();
    await panel.getByRole("listbox", { name: "Minutes" }).getByRole("option", { name: "45" }).click();
    await expect(panel).toBeHidden();
    await expect(field).toContainText("08:45");
  });

  test("works with the keyboard", async ({ page }) => {
    const field = page.getByRole("button", { name: "Departure" });
    await field.click();
    const panel = page.getByRole("dialog", { name: "Departure" });
    await expect(panel.getByRole("option", { name: "07" })).toBeFocused();
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("Enter");
    await expect(field).toContainText("08:30");
    await page.keyboard.press("ArrowRight");
    await expect(panel.getByRole("listbox", { name: "Minutes" }).getByRole("option", { name: "30" })).toBeFocused();
    await page.keyboard.press("Escape");
    await expect(panel).toBeHidden();
  });
});

test.describe("date and time picker", () => {
  test("sends one combined value once both are chosen", async ({ page }) => {
    const hidden = page.locator('input[type="hidden"][name="start"]');
    await page.getByText("Start time", { exact: true }).scrollIntoViewIfNeeded();
    await expect(hidden).toHaveValue("");

    await page.getByRole("button", { name: "Date", exact: true }).click();
    await page.getByRole("dialog", { name: "Date" }).getByRole("button", { name: "Today" }).click();
    await expect(hidden).toHaveValue("");

    await page.getByRole("button", { name: "Time", exact: true }).click();
    const panel = page.getByRole("dialog", { name: "Time" });
    await panel.getByRole("listbox", { name: "Hours" }).getByRole("option", { name: "06" }).click();
    await panel.getByRole("listbox", { name: "Minutes" }).getByRole("option", { name: "30" }).click();
    await expect(hidden).toHaveValue(/^\d{4}-\d{2}-\d{2}T06:30$/);
  });
});

test.describe("menu placement", () => {
  for (const side of ["bottom", "top", "left", "right"] as const) {
    test(`opens ${side} when there is room`, async ({ page }) => {
      const button = page.getByRole("button", { name: `Menu opening ${side}` });
      await button.evaluate((el) => el.scrollIntoView({ block: "center" }));
      await button.click();
      const menu = page.getByRole("menu", { name: `Menu opening ${side}` });
      await expect(menu).toBeVisible();
      await expect(menu).toHaveAttribute("data-side", side);
      const m = (await menu.boundingBox())!;
      const b = (await button.boundingBox())!;
      if (side === "bottom") expect(m.y).toBeGreaterThanOrEqual(b.y + b.height);
      if (side === "top") expect(m.y + m.height).toBeLessThanOrEqual(b.y);
      if (side === "left") expect(m.x + m.width).toBeLessThanOrEqual(b.x);
      if (side === "right") expect(m.x).toBeGreaterThanOrEqual(b.x + b.width);
    });
  }

  test("a menu asked to open below flips up at the bottom of the screen", async ({ page }) => {
    const button = page.getByRole("button", { name: "Menu opening bottom" });
    await button.evaluate((el) => el.scrollIntoView({ block: "end" }));
    await button.click();
    await expect(page.getByRole("menu", { name: "Menu opening bottom" })).toHaveAttribute("data-side", "top");
  });

  test("a menu asked to open to the left flips right when the button is at the left edge", async ({ page }) => {
    await page.setViewportSize({ width: 420, height: 800 });
    await page.goto("/styleguide");
    const button = page.getByRole("button", { name: "Menu opening left" });
    await button.evaluate((el) => el.scrollIntoView({ block: "center" }));
    const box = (await button.boundingBox())!;
    await button.click();
    const menu = page.getByRole("menu", { name: "Menu opening left" });
    const side = await menu.getAttribute("data-side");
    const m = (await menu.boundingBox())!;
    expect(m.x).toBeGreaterThanOrEqual(0);
    expect(m.x + m.width).toBeLessThanOrEqual(420);
    if (box.x < 220) expect(side).not.toBe("left");
  });
});
