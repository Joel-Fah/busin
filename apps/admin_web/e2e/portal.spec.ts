import { expect, test } from "@playwright/test";

import {
  SEED,
  createUser,
  deleteUser,
  serviceClient,
  signInBrowser,
  type TestUser,
  setLanguage,
} from "./support";

let admin: TestUser;
let staff: TestUser;
let student: TestUser;
let suspendedAdmin: TestUser;

test.beforeAll(async () => {
  admin = await createUser("admin", "admin");
  staff = await createUser("staff", "staff");
  student = await createUser("student", "student");
  suspendedAdmin = await createUser("suspended", "admin", "suspended");

  // One pending subscription so the "to review" figure is not zero.
  const { error } = await serviceClient().from("subscriptions").insert({
    school_id: SEED.schoolId,
    student_id: student.id,
    semester_id: SEED.semesterId,
    stop_id: SEED.stopId,
  });
  if (error) throw new Error(`could not create a subscription: ${error.message}`);
});

test.afterAll(async () => {
  for (const user of [admin, staff, student, suspendedAdmin]) {
    if (user) await deleteUser(user);
  }
});

async function countRows(table: "subscriptions" | "profiles" | "trips" | "scans", filter?: [string, string]) {
  let query = serviceClient().from(table).select("id", { count: "exact", head: true });
  if (filter) query = query.eq(filter[0], filter[1]);
  const { count, error } = await query;
  if (error) throw new Error(error.message);
  return count ?? 0;
}

test.describe("signed out", () => {
  test("sees the landing page at the root and reaches the login page from it", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { level: 1 })).toContainText("On your side.");
    await page.getByRole("link", { name: "Staff sign in" }).click();
    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByRole("button", { name: "Continue with Google" })).toBeVisible();
  });

  test("is sent to the login page from any portal page", async ({ page }) => {
    await page.goto("/people");
    await expect(page).toHaveURL(/\/login$/);
  });

  test("shows a sign-in error from the callback", async ({ page }) => {
    await page.goto("/login?error=auth_failed");
    // Next also renders its own route announcer with role="alert", so match on the text.
    await expect(page.getByRole("alert").filter({ hasText: "Sign-in did not complete" })).toBeVisible();
  });

  test("sends security headers", async ({ request }) => {
    const response = await request.get("/login");
    expect(response.headers()["x-frame-options"]).toBe("DENY");
    expect(response.headers()["x-content-type-options"]).toBe("nosniff");
    expect(response.headers()["x-powered-by"]).toBeUndefined();
  });
});

test.describe("administrator", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("sees the overview with figures that match the database", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("heading", { name: "Overview", level: 1 })).toBeVisible();

    const expected = {
      pendingSubscriptions: await countRows("subscriptions", ["status", "pending"]),
      students: await countRows("profiles", ["role", "student"]),
      activeTrips: await countRows("trips", ["status", "active"]),
    };
    expect(expected.pendingSubscriptions).toBeGreaterThanOrEqual(1);

    for (const [key, value] of Object.entries(expected)) {
      await expect(page.getByTestId(`stat-${key}`).locator(".stat-value")).toHaveText(String(value));
    }
    await expect(page.getByTestId("stat-scansToday")).toBeVisible();
  });

  test("shows the trends and short lists beside the figures", async ({ page }) => {
    await page.goto("/");
    // Boardings chart: a named image, with one entry for each of the last 14 days for screen readers.
    const boardings = page.getByTestId("tile-boardings").locator("xpath=..");
    await expect(boardings.getByRole("img", { name: "Boardings per day over the last 14 days" })).toBeVisible();
    await expect(boardings.locator("figcaption li")).toHaveCount(14);

    // The status mix repeats each figure as text and links to that status.
    const mix = page.getByTestId("tile-mix").locator("xpath=..");
    await expect(mix.getByRole("link", { name: /Pending/ })).toHaveAttribute("href", "/subscriptions?status=pending");

    // The oldest request waiting is listed, with how long it has waited.
    const waiting = page.getByTestId("tile-waiting").locator("xpath=..");
    await expect(waiting.getByRole("listitem").first()).toBeVisible();
    await expect(waiting.getByRole("listitem").first()).toContainText(/\d+ (h|d)/);

    await expect(page.getByTestId("tile-trips")).toBeVisible();
    await expect(page.getByTestId("tile-semester")).toBeVisible();
    await expect(page.getByTestId("tile-fleet").locator("xpath=..").getByRole("link", { name: /Stops/ })).toHaveAttribute("href", "/stops");
  });

  test("greets the administrator and the chart bars show a tooltip on hover", async ({ page }) => {
    // Tall enough that the floating navigation bar does not sit over the chart.
    await page.setViewportSize({ width: 1440, height: 1500 });
    await page.goto("/");
    const welcome = page.getByTestId("welcome");
    await expect(welcome.getByRole("heading", { level: 2, name: /^Good (morning|afternoon|evening)/ })).toBeVisible();
    // Two to four insight cards, each a link.
    const cards = await welcome.getByRole("link").count();
    expect(cards).toBeGreaterThanOrEqual(2);
    expect(cards).toBeLessThanOrEqual(4);
    await expect(welcome.getByRole("link", { name: /Boardings today/ })).toHaveAttribute("href", "/scans");

    const tile = page.getByTestId("tile-boardings").locator("xpath=..");
    await expect(tile.getByRole("link", { name: "Boardings" }).locator("svg")).toBeVisible();
    await tile.locator("[data-tip]").last().hover();
    await expect(page.getByRole("tooltip")).toContainText(/: \d+$/);
    // The status bar has one too.
    await page.getByTestId("tile-mix").locator("xpath=..").locator("[data-tip]").first().hover();
    await expect(page.getByRole("tooltip")).toContainText(/: \d+$/);
  });

  test("only the insight cards follow the mouse, and stay still for reduced motion", async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 1500 });
    const offsets = async () => {
      const welcome = page.getByTestId("welcome");
      const read = (selector: string) => welcome.locator(selector).first().evaluate((el) => getComputedStyle(el).translate);
      return { bus: await read("img"), text: await read("h2"), cards: await read("ul") };
    };
    const still = { bus: "none", text: "none", cards: "0px" };

    // Reduced motion (the suite default): the pointer changes nothing.
    await page.goto("/");
    await expect(page.getByTestId("welcome")).toBeVisible();
    const box = (await page.getByTestId("welcome").boundingBox())!;
    await page.mouse.move(box.x + box.width - 20, box.y + 20);
    await page.waitForTimeout(500);
    expect(await offsets()).toEqual(still);

    // Otherwise the cards move with the pointer and nothing else does; they return when it leaves.
    await page.emulateMedia({ reducedMotion: "no-preference" });
    await page.reload();
    await expect(page.getByTestId("welcome")).toBeVisible();
    // Keep moving until the page has hydrated and listens.
    await expect
      .poll(async () => {
        await page.mouse.move(box.x + 40, box.y + 40);
        await page.mouse.move(box.x + box.width - 20, box.y + 20, { steps: 4 });
        await page.waitForTimeout(150);
        return (await offsets()).cards;
      })
      .toMatch(/^[1-9]/);
    expect(await offsets()).toMatchObject({ bus: "none", text: "none" });
    await page.mouse.move(box.x - 40, box.y - 40);
    await expect.poll(async () => (await offsets()).cards).toMatch(/^0px/);
  });

  test("each figure is a card that leads to where its detail lives", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByTestId("stat-pendingSubscriptions")).toHaveAttribute("href", "/subscriptions");
    await expect(page.getByTestId("stat-students")).toHaveAttribute("href", "/people?role=student");
    await expect(page.getByTestId("stat-activeTrips")).toHaveAttribute("href", "/trips?status=active");
    await expect(page.getByTestId("stat-scansToday")).toHaveAttribute("href", "/scans");
    await page.getByTestId("stat-students").click();
    await expect(page).toHaveURL(/\/people\?role=student$/);
  });

  test("the sign-in page is a branded card with the logo, a title and one clear action", async ({ browser }) => {
    const context = await browser.newContext();
    const page = await context.newPage();
    await page.goto("/login");
    await expect(page.getByRole("heading", { name: "Sign in to the admin portal", level: 1 })).toBeVisible();
    await expect(page.getByRole("img", { name: "BusIn" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Continue with Google" })).toBeVisible();
    await context.close();
  });

  test("can switch to French and back", async ({ page }) => {
    await setLanguage(page, "fr");
    await page.goto("/");
    await expect(page.getByRole("heading", { name: "Vue d'ensemble", level: 1 })).toBeVisible();
    await setLanguage(page, "en");
    await page.goto("/");
    await expect(page.getByRole("heading", { name: "Overview", level: 1 })).toBeVisible();
  });

  test("signing out returns to the login page and closes the portal", async ({ page }) => {
    await page.goto("/profile");
    await page.getByRole("button", { name: "Sign out" }).click();
    await expect(page).toHaveURL(/\/login$/);
    // The root is the public landing page now; the portal itself stays closed.
    await page.goto("/");
    await expect(page.getByRole("heading", { level: 1 })).toContainText("On your side.");
    await page.goto("/people");
    await expect(page).toHaveURL(/\/login$/);
  });

  test("an administrator who opens the login page goes straight to the overview", async ({ page }) => {
    await page.goto("/login");
    await expect(page).toHaveURL(/\/$/);
  });
});

for (const [label, who] of [
  ["a student", () => student],
  ["a staff member", () => staff],
  ["a suspended administrator", () => suspendedAdmin],
] as const) {
  test(`${label} gets the no-access page`, async ({ page, context }) => {
    await signInBrowser(context, who());
    await page.goto("/");
    await expect(page).toHaveURL(/\/no-access$/);
    await expect(page.getByRole("heading", { name: "No access" })).toBeVisible();
    await expect(page.getByTestId("stat-students")).toHaveCount(0);
  });
}
