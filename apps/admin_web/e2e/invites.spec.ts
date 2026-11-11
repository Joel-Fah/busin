import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");
const newEmail = `e2e-invite-${tag}@personal-mail.org`;

let admin: TestUser;
let staff: TestUser;
let student: TestUser;

test.beforeAll(async () => {
  admin = await createUser(`invite-admin-${tag}`, "admin");
  staff = await createUser(`invite-staff-${tag}`, "staff");
  student = await createUser(`invite-student-${tag}`, "student");
});

test.afterAll(async () => {
  await serviceClient().from("staff_invites").delete().eq("email", newEmail);
  for (const user of [admin, staff, student]) {
    if (user) await deleteUser(user);
  }
});

test("an administrator adds staff by email, sees the invite wait, and withdraws it", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/people");
  await page.getByRole("link", { name: "Add staff by email" }).click();
  await expect(page).toHaveURL(/\/people\/invite$/);

  await page.getByLabel("Email", { exact: true }).fill(`  ${newEmail.toUpperCase()} `);
  await page.getByRole("button", { name: "Add", exact: true }).click();
  await expect(page.getByText(/They join your school with this role the first time they sign in/)).toBeVisible();
  const row = page.getByRole("row").filter({ hasText: newEmail });
  await expect(row).toContainText("Staff");
  await expect(row).toContainText("in 30 days");

  await row.getByRole("button", { name: `Withdraw the invite for ${newEmail}` }).click();
  await expect(page.getByText("Invite withdrawn.")).toBeVisible();
  await expect(page.getByRole("row").filter({ hasText: newEmail })).toHaveCount(0);
});

test("an account already at the school gets the role at once", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/people/invite");
  await page.getByLabel("Email", { exact: true }).fill(student.email);
  await page.getByRole("button", { name: "Add", exact: true }).click();
  await expect(page.getByText("Done. That account now has the role.")).toBeVisible();
  const { data } = await serviceClient().from("profiles").select("role").eq("id", student.id).single();
  expect(data?.role).toBe("staff");
});

test("a staff member cannot add staff", async ({ page, context }) => {
  await signInBrowser(context, staff);
  await page.goto("/people/invite");
  await expect(page).toHaveURL(/\/no-access$/);
});
