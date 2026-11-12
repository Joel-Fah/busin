import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");
let admin: TestUser;

test.beforeAll(async () => {
  admin = await createUser(`acad-admin-${tag}`, "admin");
});

test.afterAll(async () => {
  if (admin) await deleteUser(admin);
});

test("an administrator builds a faculty with a department, renames it, and removes them in order", async ({ page }) => {
  await page.goto("/dev/login");
  await page.getByLabel("Email").fill(admin.email);
  await page.getByLabel("Password").fill(admin.password);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL(/\/$/);
  await page.goto("/academics");
  await expect(page.getByRole("heading", { name: "Faculties and departments", level: 1 })).toBeVisible();

  const faculty = `Faculty ${tag}`;
  const department = `Department ${tag}`;

  // A faculty
  const addFaculty = page.locator("form").filter({ has: page.getByRole("button", { name: "Add a faculty" }) });
  await addFaculty.getByLabel("Faculty name").fill(faculty);
  await addFaculty.getByRole("button", { name: "Add a faculty" }).click();
  await expect(page.getByText("Faculty added.")).toBeVisible();

  // A department inside it
  const card = page.locator("div.relative").filter({ has: page.locator(`input[value="${faculty}"]`) }).last();
  const addDepartment = card.locator("form").filter({ has: page.getByRole("button", { name: "Add a department" }) });
  await addDepartment.getByLabel("Department name").fill(department);
  await addDepartment.getByLabel("Code").fill("TST");
  await addDepartment.getByRole("button", { name: "Add a department" }).click();
  await expect(page.getByText("Department added.")).toBeVisible();
  await expect(page.locator(`input[value="${department}"]`)).toBeVisible();

  // The same name twice is refused
  const again = page.locator("div.relative").filter({ has: page.locator(`input[value="${faculty}"]`) }).last().locator("form").filter({ has: page.getByRole("button", { name: "Add a department" }) });
  await again.getByLabel("Department name").fill(department);
  await again.getByRole("button", { name: "Add a department" }).click();
  await expect(page.getByText("That name is already used here.")).toBeVisible();

  // A faculty with departments cannot be removed
  await page.locator("form").filter({ has: page.locator(`input[value="${faculty}"]`) }).getByRole("button", { name: "Remove" }).click();
  await expect(page.getByText("Remove its departments first.")).toBeVisible();

  // Rename the department
  const renamed = `${department} renamed`;
  const row = page.locator("form").filter({ has: page.locator(`input[value="${department}"]`) });
  await row.getByLabel("Department name").fill(renamed);
  await row.getByRole("button", { name: "Save" }).click();
  await expect(page.getByText("Department saved.")).toBeVisible();

  // Remove in order
  await page.locator("form").filter({ has: page.locator(`input[value="${renamed}"]`) }).getByRole("button", { name: "Remove" }).click();
  await expect(page.getByText("Department removed.")).toBeVisible();
  await page.locator("form").filter({ has: page.locator(`input[value="${faculty}"]`) }).getByRole("button", { name: "Remove" }).click();
  await expect(page.getByText("Faculty removed.")).toBeVisible();
});

test("a degree level can be added and removed", async ({ page }) => {
  await page.goto("/dev/login");
  await page.getByLabel("Email").fill(admin.email);
  await page.getByLabel("Password").fill(admin.password);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL(/\/$/);
  await page.goto("/academics");
  const level = `Level ${tag}`;
  const add = page.locator("form").filter({ has: page.getByRole("button", { name: "Add a degree level" }) });
  await add.getByLabel("Degree level").fill(level);
  await add.getByRole("button", { name: "Add a degree level" }).click();
  await expect(page.getByText("Degree level added.")).toBeVisible();
  await page.locator("form").filter({ has: page.locator(`input[value="${level}"]`) }).getByRole("button", { name: "Remove" }).click();
  await expect(page.getByText("Degree level removed.")).toBeVisible();
});
