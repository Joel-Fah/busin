import { randomBytes, randomUUID } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteSchool, deleteUser, searchAndChoose, serviceClient, setPlatformAdmin, signInBrowser, type TestUser } from "./support";

// Leads from the landing page in the platform console (ADR 0027, slice 5).
const tag = randomBytes(3).toString("hex");
const schoolLead = randomUUID();
const notifyLead = randomUUID();
const org = `E2E Lead College ${tag}`;
const leadEmail = `head-${tag}@college.example`;
let owner: TestUser;
let schoolId: string | null = null;

test.beforeAll(async () => {
  owner = await createUser(`leads-owner-${tag}`, "admin");
  setPlatformAdmin(owner.id, true);
  const { error } = await serviceClient().from("interest_requests").insert([
    { id: schoolLead, kind: "school", name: "Ama Head", organisation: org, email: leadEmail, message: "We run three buses.", locale: "fr" },
    { id: notifyLead, kind: "notify", email: `fan-${tag}@example.org`, locale: "en" },
  ]);
  if (error) throw error;
});

test.afterAll(async () => {
  setPlatformAdmin(owner.id, false);
  await serviceClient().from("interest_requests").delete().in("id", [schoolLead, notifyLead]);
  if (schoolId) deleteSchool(schoolId);
  await deleteUser(owner);
});

test.use({ viewport: { width: 1280, height: 900 } });
test.describe.configure({ mode: "serial" });

test("a new school lead shows in Needs you, and is marked contacted with a note", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform");
  await page.getByTestId("platform-new-leads").click();
  await expect(page).toHaveURL(/\/platform\/leads\?kind=school&status=new$/);

  const card = page.locator(`[data-lead="${schoolLead}"]`);
  await expect(card).toContainText(org);
  await expect(card).toContainText("We run three buses.");
  await expect(card.getByRole("link", { name: leadEmail })).toHaveAttribute("href", `mailto:${leadEmail}`);

  await card.getByRole("button", { name: "Mark contacted" }).click();
  await expect(page.getByText("Lead marked contacted.")).toBeVisible();
  await page.goto("/platform/leads?kind=school");
  await expect(page.locator(`[data-lead="${schoolLead}"]`)).toContainText("Contacted");

  await page.locator(`[data-lead="${schoolLead}"]`).getByRole("button", { name: "Note" }).click();
  const dialog = page.getByRole("dialog", { name: "Note" });
  await dialog.getByLabel("Note").fill("Called Ama, they start in January.");
  await dialog.getByRole("button", { name: "Save the note" }).click();
  await expect(page.getByText("Note saved.")).toBeVisible();
  await expect(page.locator(`[data-lead="${schoolLead}"]`)).toContainText("Called Ama, they start in January.");
});

test("the school is created from the lead, which then names it", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform/leads?kind=school");
  await page.locator(`[data-lead="${schoolLead}"]`).getByRole("link", { name: "Create the school" }).click();
  await expect(page.getByLabel("Name", { exact: true })).toHaveValue(org);
  await expect(page.getByLabel("Their Google email")).toHaveValue(leadEmail);
  await searchAndChoose(page, "Time zone", "Douala", /^Africa\/Douala/);
  await page.getByRole("button", { name: "Create the school" }).click();
  await expect(page).toHaveURL(/\/platform\/schools\/[0-9a-f-]{36}/);
  schoolId = page.url().match(/schools\/([0-9a-f-]{36})/)?.[1] ?? null;

  await page.goto("/platform/leads?kind=school&status=converted");
  const card = page.locator(`[data-lead="${schoolLead}"]`);
  await expect(card).toContainText("Converted");
  await card.getByRole("link", { name: `Became ${org}` }).click();
  await expect(page.getByRole("heading", { name: org, level: 1 })).toBeVisible();
});

test("notify-me leads are listed apart, can be dismissed and brought back", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform/leads?kind=notify");
  await expect(page.getByRole("button", { name: "Copy these emails" })).toBeVisible();
  const card = page.locator(`[data-lead="${notifyLead}"]`);
  await expect(card).toContainText(`fan-${tag}@example.org`);
  await card.getByRole("button", { name: "Dismiss" }).click();
  await expect(page.getByText("Lead dismissed.")).toBeVisible();
  await page.goto("/platform/leads?kind=notify&status=dismissed");
  await page.locator(`[data-lead="${notifyLead}"]`).getByRole("button", { name: "Back to new" }).click();
  await expect(page.getByText("Lead back to new.")).toBeVisible();
});
