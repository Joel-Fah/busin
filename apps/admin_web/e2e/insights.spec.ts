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
  // How close students live to the bus route itself (or how to get that figure).
  await expect(page.getByText(/Along the bus route: \d+ of \d+ live within 500 m|Set the bus route|Not enough students have shared/)).toBeVisible();
  const tiles = page.getByRole("list", { name: "Stops, farthest first" }).getByRole("button");
  await expect(tiles.first()).toBeVisible();
  // Every tile either has a typical distance or says there are not enough students yet.
  for (const text of await tiles.allInnerTexts()) {
    expect(text).toMatch(/Typically about [\d.]+ k?m|Not enough students yet/);
  }
});

test("the graph shows each stop as a button that opens its figures, by mouse or keyboard", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/insights");
  await page.getByRole("link", { name: "Graph" }).click();
  await expect(page).toHaveURL(/\/insights\?view=graph$/);
  const graph = page.getByRole("group", { name: /Graph of the stops/ });
  await expect(graph).toBeVisible();
  const nodes = graph.getByRole("button");
  await expect(nodes.first()).toBeVisible();
  await expect(page.getByText(/Select a stop, a dot or a dashed ring/)).toBeVisible();
  // The guide says what the graph shows, and draws each shape; it folds away so nothing under it is hidden.
  const guide = page.getByRole("complementary", { name: "Guide to the graph" });
  await expect(guide.getByRole("tab", { name: "In short" })).toHaveAttribute("aria-selected", "true");
  await expect(guide).toContainText(/stops and \d+ subscribers/);
  await guide.getByRole("tab", { name: "How to read" }).click();
  await expect(guide).toContainText("A suggested new stop.");
  await guide.getByRole("button", { name: "Fold the guide" }).click();
  await expect(guide).not.toContainText("A suggested new stop.");

  // Pointing at a stop shows its report in a card of the design system, not the browser's tooltip.
  const report = page.locator("[data-graph-report]");
  await expect(report).toHaveCount(0);
  const stopNode = graph.getByRole("button", { name: /^Mvan roundabout/ });
  if ((await stopNode.count()) > 0) {
    await stopNode.hover();
    await expect(report).toContainText("Mvan roundabout");
    await page.mouse.move(5, 5);
    await expect(report).toHaveCount(0);
  }
  await expect(graph.locator("title")).toHaveCount(0);

  await nodes.first().click();
  await expect(nodes.first()).toHaveAttribute("aria-pressed", "true");
  await expect(page.getByText(/Select a stop, a dot or a dashed ring/)).toBeHidden();

  // The keyboard reaches the next node and opens it too.
  await nodes.nth(1).focus();
  await page.keyboard.press("Enter");
  await expect(nodes.nth(1)).toHaveAttribute("aria-pressed", "true");

  await page.getByRole("button", { name: "Zoom in" }).click();
  await page.getByRole("button", { name: "Back to the whole graph" }).click();
});

test("the suggestions say what they cannot know, and each one is a sentence to select", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/insights");
  await page.getByRole("link", { name: "Suggestions" }).click();
  await expect(page).toHaveURL(/\/insights\?view=suggestions$/);
  await expect(page.getByText(/Suggestions count students, not roads/)).toBeVisible();
  const list = page.getByRole("list", { name: "Suggestions" });
  if ((await list.count()) > 0) {
    const first = list.getByRole("button").first();
    await first.click();
    await expect(first).toHaveAttribute("aria-pressed", "true");
    // A new stop on a school with a route shows the suggested route against today's, with what it gains.
    if ((await first.innerText()).startsWith("New stop") && (await page.getByText("Set the bus route").count()) === 0) {
      const compare = page.getByRole("region", { name: "Suggested route" });
      await expect(compare).toContainText(/\+\d+ students within 500 m of a stop/);
      await expect(compare).toContainText(/Blue: the suggested route/);
      await compare.getByText(/Directions, stop by stop/).click();
      await expect(compare.getByRole("list")).toContainText("Leave from");
      await compare.getByRole("button", { name: "Back to today's route" }).click();
      await expect(compare).toHaveCount(0);
    }
  } else {
    await expect(page.getByText(/Nothing to suggest for now/)).toBeVisible();
  }
});

test("a staff member cannot open the insights", async ({ page, context }) => {
  await signInBrowser(context, staff);
  await page.goto("/insights");
  await expect(page).toHaveURL(/\/no-access$/);
});
