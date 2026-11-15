import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteSchool, deleteUser, serviceClient, setPlatformAdmin, signInBrowser, signUpAs, type TestUser } from "./support";

// School onboarding from the platform console (ADR 0027, slice 4).
const tag = randomBytes(3).toString("hex");
const schoolName = `E2E Onboarding ${tag}`;
const domain = `onboard-${tag}.edu`;
const adminEmail = `registrar-${tag}@example.org`;
let owner: TestUser;
let schoolId: string | null = null;

test.beforeAll(async () => {
  owner = await createUser(`onboard-owner-${tag}`, "admin");
  setPlatformAdmin(owner.id, true);
});

test.afterAll(async () => {
  setPlatformAdmin(owner.id, false);
  // The school's own accounts (the invited administrator) go with it.
  if (schoolId) deleteSchool(schoolId);
  await deleteUser(owner);
});

test.use({ viewport: { width: 1280, height: 900 } });
test.describe.configure({ mode: "serial" });

test("a school is created with its domain and its first administrator invited", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform/schools");
  await page.getByRole("link", { name: "New school" }).click();
  await expect(page).toHaveURL(/\/platform\/schools\/new$/);

  await page.getByLabel("Name", { exact: true }).fill(schoolName);
  await page.getByLabel("Short name").fill("EOS");
  await page.getByLabel("City").fill("Lagos");
  await page.getByLabel("Time zone").fill("Africa/Lagos");
  const domains = page.getByLabel("Student email domains");
  await domains.fill(domain);
  await domains.press("Enter");
  await page.getByLabel("Their Google email").fill(adminEmail);
  await page.getByRole("button", { name: "Create the school" }).click();

  await expect(page).toHaveURL(/\/platform\/schools\/[0-9a-f-]{36}/);
  schoolId = page.url().match(/schools\/([0-9a-f-]{36})/)?.[1] ?? null;
  await expect(page.getByText("School created, and its administrator invited.")).toBeVisible();
  await expect(page.getByRole("heading", { name: schoolName, level: 1 })).toBeVisible();
  await expect(page.getByTestId("admin-invites")).toContainText(adminEmail);

  const { data } = await serviceClient().from("schools").select("timezone, city, short_name, school_domains(domain)").eq("id", schoolId!).single();
  expect(data).toMatchObject({ timezone: "Africa/Lagos", city: "Lagos", short_name: "EOS", school_domains: [{ domain }] });
});

test("the same name is refused, and the form keeps what was typed", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform/schools/new");
  await page.getByLabel("Name", { exact: true }).fill(schoolName.toUpperCase());
  await page.getByLabel("Short name").fill("DUP");
  await page.getByLabel("Time zone").fill("Africa/Lagos");
  await page.getByRole("button", { name: "Create the school" }).click();
  await expect(page.getByText("A school with this name already exists.")).toBeVisible();
  await expect(page.getByLabel("Short name")).toHaveValue("DUP");
});

test("the invited administrator's first sign-in opens the new school's portal", async ({ browser }) => {
  const invited = await signUpAs(adminEmail);
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  await signInBrowser(context, invited);
  const page = await context.newPage();
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Overview", level: 1 })).toBeVisible();
  await expect(page.getByText(schoolName).first()).toBeVisible();
  await context.close();
});

test("a school is switched off after a confirmation, and back on", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto(`/platform/schools/${schoolId}`);
  await page.getByRole("button", { name: "Switch off" }).click();
  const dialog = page.getByRole("dialog", { name: `Switch ${schoolName} off?` });
  await expect(dialog).toContainText("People already in keep their access.");
  await dialog.getByRole("button", { name: "Switch off" }).click();
  await expect(page.getByText("School switched off.")).toBeVisible();
  await expect(page.getByTestId("sticky-header")).toContainText("Switched off");
  await expect(page.getByRole("heading", { name: "Reach out" })).toHaveCount(0);

  await page.getByRole("button", { name: "Switch on" }).click();
  await page.getByRole("dialog", { name: `Switch ${schoolName} back on?` }).getByRole("button", { name: "Switch on" }).click();
  await expect(page.getByText("School switched back on.")).toBeVisible();
});
