import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex").toUpperCase();

let admin: TestUser;
let staff: TestUser;

test.beforeAll(async () => {
  admin = await createUser(`insights-admin-${tag}`, "admin");
  staff = await createUser(`insights-staff-${tag}`, "staff");
});

test.afterAll(async () => {
  for (const user of [admin, staff]) {
    if (user) await deleteUser(user);
  }
});

test("an administrator sees the load of each stop and can count again", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/insights");
  await expect(page.getByRole("heading", { name: "Insights", level: 1 })).toBeVisible();

  // The seed has boardings tagged with stops, so the page counts boardings, fullest stop first.
  await expect(page.getByText(/boardings scanned at the stops/)).toBeVisible();
  const tiles = page.getByRole("list", { name: "Stops, fullest first" }).getByRole("button");
  await expect(tiles.first()).toContainText(/per departure · \d+% of the seats/);
  await expect(page.getByRole("list", { name: "Share of the seats" })).toContainText("Full, 80% or more");

  // The period is in the address.
  await page.getByRole("link", { name: "4 weeks" }).click();
  await expect(page).toHaveURL(/\/insights\?days=28$/);

  // Counting again is allowed once every five minutes (an earlier run may have just done it).
  await page.getByRole("button", { name: "Count now" }).click();
  await expect(page.getByText(/^(Counted again\.|Counted a moment ago\. Try again in a few minutes\.)$/)).toBeVisible();
});

test("the proximity view says what it is based on and never shows small groups", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/insights");
  await page.getByRole("link", { name: "Proximity" }).click();
  await expect(page).toHaveURL(/\/insights\?view=proximity$/);
  await expect(page.getByText(/^Based on \d+ of \d+ subscribers/)).toBeVisible();
  const tiles = page.getByRole("list", { name: "Stops, farthest first" }).getByRole("button");
  await expect(tiles.first()).toBeVisible();
  // Every tile either has a typical distance or says there are not enough students yet.
  for (const text of await tiles.allInnerTexts()) {
    expect(text).toMatch(/Typically about [\d.]+ k?m|Not enough students yet/);
  }
});

test("a staff member cannot open the insights", async ({ page, context }) => {
  await signInBrowser(context, staff);
  await page.goto("/insights");
  await expect(page).toHaveURL(/\/no-access$/);
});
