import { expect, test } from "@playwright/test";

import {
  SEED,
  createUser,
  deleteUser,
  serviceClient,
  signInBrowser,
  type TestUser,
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
  test("is sent to the login page", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByRole("button", { name: "Continue with Google" })).toBeVisible();
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

  test("can switch to French and back", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Français" }).click();
    await expect(page.getByRole("heading", { name: "Vue d'ensemble", level: 1 })).toBeVisible();
    await page.getByRole("button", { name: "English" }).click();
    await expect(page.getByRole("heading", { name: "Overview", level: 1 })).toBeVisible();
  });

  test("signing out returns to the login page and closes the portal", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Sign out" }).click();
    await expect(page).toHaveURL(/\/login$/);
    await page.goto("/");
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
