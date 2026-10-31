import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");

let admin: TestUser;
let staff: TestUser;
let promote: TestUser;
let suspend: TestUser;
let plainStudent: TestUser;

const nameOf = (label: string) => `E2E ${label}`;

test.beforeAll(async () => {
  admin = await createUser(`ppl-admin-${tag}`, "admin");
  staff = await createUser(`ppl-staff-${tag}`, "staff");
  promote = await createUser(`promote-${tag}`, "student");
  suspend = await createUser(`suspend-${tag}`, "student");
  plainStudent = await createUser(`plain-${tag}`, "student");
});

test.afterAll(async () => {
  // Audit rows point at the acting admin, so they go before the users do.
  await serviceClient().from("audit_log").delete().eq("actor_id", admin?.id ?? "");
  for (const user of [admin, staff, promote, suspend, plainStudent]) {
    if (user) await deleteUser(user);
  }
});

test.describe("administrator managing people", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("lists people and filters by role", async ({ page }) => {
    await page.goto("/people");
    await expect(page.getByRole("heading", { name: "People", level: 1 })).toBeVisible();

    const filters = page.getByRole("navigation", { name: "Filter by role" });
    await filters.getByRole("link", { name: "Staff" }).click();
    await expect(page).toHaveURL(/role=staff/);
    await expect(page.getByRole("row").filter({ hasText: nameOf(`ppl-staff-${tag}`) })).toBeVisible();
    await expect(page.getByRole("row").filter({ hasText: nameOf(`promote-${tag}`) })).toHaveCount(0);

    await filters.getByRole("link", { name: "Students" }).click();
    await expect(page.getByRole("row").filter({ hasText: nameOf(`promote-${tag}`) })).toBeVisible();
    await expect(page.getByRole("row").filter({ hasText: nameOf(`ppl-staff-${tag}`) })).toHaveCount(0);
  });

  test("searches by name, and odd characters do not break the page", async ({ page }) => {
    await page.goto("/people");
    await page.getByRole("searchbox").fill(`promote-${tag}`);
    await page.getByRole("button", { name: "Search" }).click();
    await expect(page.getByRole("row").filter({ hasText: nameOf(`promote-${tag}`) })).toBeVisible();
    await expect(page.getByRole("row").filter({ hasText: nameOf(`plain-${tag}`) })).toHaveCount(0);

    await page.goto("/people?q=" + encodeURIComponent("a,b)(%*\\\"'"));
    await expect(page.getByRole("heading", { name: "People", level: 1 })).toBeVisible();
    await expect(page.getByRole("alert").filter({ hasText: "could not be loaded" })).toHaveCount(0);
  });

  test("changing a role is stored and audited", async ({ page }) => {
    await page.goto("/people");
    await page.getByRole("searchbox").fill(`promote-${tag}`);
    await page.getByRole("button", { name: "Search" }).click();
    await page.getByRole("row").filter({ hasText: nameOf(`promote-${tag}`) }).getByRole("link").first().click();

    await page.getByLabel("New role").selectOption("staff");
    await page.getByRole("button", { name: "Change role" }).click();
    await expect(page.getByRole("status")).toContainText("Role changed.");

    const db = serviceClient();
    expect((await db.from("profiles").select("role").eq("id", promote.id).single()).data?.role).toBe("staff");

    const { data: entries } = await db
      .from("audit_log")
      .select("action, actor_id, details")
      .eq("target_id", promote.id)
      .eq("action", "user.role_changed");
    expect(entries).toHaveLength(1);
    expect(entries?.[0].actor_id).toBe(admin.id);
    expect(entries?.[0].details).toMatchObject({ from: "student", to: "staff" });
  });

  test("suspending and restoring an account", async ({ page }) => {
    await page.goto(`/people/${suspend.id}`);
    await page.getByText("Suspend this account").click();
    await page.getByRole("button", { name: "Confirm suspension" }).click();
    await expect(page.getByRole("status")).toContainText("Account suspended.");

    const db = serviceClient();
    expect((await db.from("profiles").select("status").eq("id", suspend.id).single()).data?.status).toBe("suspended");

    await page.getByRole("button", { name: "Restore this account" }).click();
    await expect(page.getByRole("status")).toContainText("Account restored.");
    expect((await db.from("profiles").select("status").eq("id", suspend.id).single()).data?.status).toBe("verified");
  });

  test("an administrator cannot change their own account", async ({ page }) => {
    await page.goto(`/people/${admin.id}`);
    await expect(page.getByRole("note")).toContainText("You cannot change your own role or status");
    await expect(page.getByRole("button", { name: "Change role" })).toHaveCount(0);
    await expect(page.getByText("Suspend this account")).toHaveCount(0);
  });

  test("a malformed or unknown id shows the not-found page", async ({ page }) => {
    await page.goto("/people/not-a-uuid");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
    await page.goto("/people/a1000000-0000-4000-8000-0000000000ff");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  });

  test("the pages are available in French", async ({ page }) => {
    await page.goto("/people");
    await page.getByRole("button", { name: "Français" }).click();
    await expect(page.getByRole("heading", { name: "Personnes", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "Étudiants" })).toBeVisible();
    await page.getByRole("button", { name: "English" }).click();
  });
});

for (const [label, who] of [
  ["a student", () => plainStudent],
  ["a staff member", () => staff],
] as const) {
  test(`${label} cannot open the people pages`, async ({ page, context }) => {
    await signInBrowser(context, who());
    await page.goto("/people");
    await expect(page).toHaveURL(/\/no-access$/);
    await page.goto(`/people/${admin.id}`);
    await expect(page).toHaveURL(/\/no-access$/);
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/people");
  await expect(page).toHaveURL(/\/login$/);
});
