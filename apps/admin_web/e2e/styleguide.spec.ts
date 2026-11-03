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
