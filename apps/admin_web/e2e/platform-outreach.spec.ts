import { randomBytes, randomUUID } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, pickDate, serviceClient, setPlatformAdmin, signInBrowser, type TestUser } from "./support";

// Reaching out to a school from the platform console (ADR 0027, slice 3).
const tag = randomBytes(3).toString("hex");
const schoolId = randomUUID();
const schoolName = `E2E Outreach ${tag}`;
let owner: TestUser;
let schoolAdmin: TestUser;
let joiner: TestUser;

test.beforeAll(async () => {
  const admin = serviceClient();
  const created = await admin
    .from("schools")
    .insert({ id: schoolId, name: schoolName, contact_email: `office-${tag}@example.org`, created_at: new Date(Date.now() - 60 * 86_400_000).toISOString() });
  if (created.error) throw created.error;
  owner = await createUser(`outreach-owner-${tag}`, "admin");
  setPlatformAdmin(owner.id, true);
  // The school's own administrator, with a phone for WhatsApp.
  schoolAdmin = await createUser(`outreach-admin-${tag}`, "student", "pending", "example.org");
  const made = await admin.from("profiles").update({ school_id: schoolId, role: "admin", status: "verified", phone: "+237677000099" }).eq("id", schoolAdmin.id);
  if (made.error) throw made.error;
  // Someone has waited 15 days to join: Critical.
  joiner = await createUser(`outreach-joiner-${tag}`, "student", "pending", "example.org");
  const asked = await admin
    .from("profiles")
    .update({ school_id: schoolId, join_requested_at: new Date(Date.now() - 15 * 86_400_000).toISOString() })
    .eq("id", joiner.id);
  if (asked.error) throw asked.error;
});

test.afterAll(async () => {
  setPlatformAdmin(owner.id, false);
  const admin = serviceClient();
  await deleteUser(joiner);
  await deleteUser(schoolAdmin);
  await deleteUser(owner);
  await admin.from("school_notices").delete().eq("school_id", schoolId);
  await admin.from("schools").delete().eq("id", schoolId);
});

test.use({ viewport: { width: 1280, height: 900 } });
test.describe.configure({ mode: "serial" });

test("the header sticks as a compact bar while the page scrolls, and comes back at the top", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto(`/platform/schools/${schoolId}`);
  const header = page.getByTestId("sticky-header");
  await expect(header).toHaveAttribute("data-stuck", "false");
  // The first page after the server starts may still be loading its scripts: scroll again until the header reacts.
  await expect(async () => {
    await page.mouse.wheel(0, 900);
    await expect(header).toHaveAttribute("data-stuck", "true", { timeout: 1000 });
  }).toPass();
  await expect(header.getByRole("heading", { name: schoolName, level: 1 })).toBeInViewport();
  await expect(header.getByRole("link", { name: "Reach out" })).toBeInViewport();
  await page.evaluate(() => window.scrollTo(0, 0));
  await expect(header).toHaveAttribute("data-stuck", "false");
});

test("the message is written for the chosen signals and language, and opens in email or WhatsApp", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto(`/platform/schools/${schoolId}#reach-out`);
  const message = page.getByLabel("Message", { exact: true });
  await expect(message).toHaveValue(new RegExp(`^Hello ${schoolName} team,`));
  await expect(message).toHaveValue(/A join or staff request has waited 15 days\. Someone is waiting to join or to become staff: see People, To verify\. .*\/people\?role=verify/);

  const contacts = page.getByTestId("reach-contacts");
  await expect(contacts.getByRole("link", { name: "Open in email" }).first()).toHaveAttribute("href", new RegExp(`^mailto:office-${tag}%40example.org\\?subject=BusIn%3A%20a%20few%20things`));
  await expect(contacts.getByRole("link", { name: "Open in WhatsApp" })).toHaveAttribute("href", /^https:\/\/wa\.me\/237677000099\?text=Hello/);

  await page.getByRole("button", { name: "Français" }).click();
  await expect(message).toHaveValue(new RegExp(`^Bonjour à l'équipe de ${schoolName},`));

  // Leaving a signal out takes it out of the message.
  await page.getByRole("checkbox", { name: "Oldest join or staff request" }).uncheck();
  await expect(message).not.toHaveValue(/adhésion ou de personnel attend/);
});

test("a notice reaches the school's administrators, pauses its signals, and they dismiss it", async ({ browser, context, page }) => {
  await signInBrowser(context, owner);
  await page.goto(`/platform/schools/${schoolId}#reach-out`);
  await page.getByRole("button", { name: "Send as a notice in their portal" }).click();
  await expect(page.getByText("Notice sent to the school.")).toBeVisible();
  const history = page.getByTestId("outreach-history");
  await expect(history).toContainText("Notice in their portal");
  await expect(history).toContainText("Not dismissed yet");
  await expect(page.getByTestId("signal-oldest_request_days").getByTestId("signal-paused")).toContainText("Paused until");

  // Its serious signals are all paused, so it leaves "Needs you" for now.
  await page.goto("/platform");
  await expect(page.getByTestId("platform-needs").getByRole("link", { name: new RegExp(schoolName) })).toHaveCount(0);

  // The school's administrator sees it on their overview and dismisses it.
  const other = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  await signInBrowser(other, schoolAdmin);
  const adminPage = await other.newPage();
  await adminPage.goto("/");
  const notices = adminPage.getByTestId("school-notices");
  await expect(notices).toContainText("A reminder from BusIn");
  await expect(notices).toContainText("A join or staff request has waited 15 days");
  await expect(notices.getByRole("link", { name: "Open" })).toHaveAttribute("href", "/people?role=verify");
  await notices.getByRole("button", { name: "Dismiss" }).click();
  await expect(adminPage.getByText("Reminder dismissed.")).toBeVisible();
  await expect(adminPage.getByTestId("school-notices")).toHaveCount(0);
  await other.close();

  await page.goto(`/platform/schools/${schoolId}`);
  await expect(page.getByTestId("outreach-history")).toContainText("Dismissed by the school");
});

test("a contact is logged with a follow-up, which shows in Needs you until done", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto(`/platform/schools/${schoolId}#reach-out`);
  const today = new Date().toISOString().slice(0, 10);
  await pickDate(page, "Follow up on", today);
  await page.getByLabel("Note", { exact: true }).fill("Called the registrar.");
  await page.getByRole("button", { name: "Save", exact: true }).click();
  await expect(page.getByText("Contact saved.")).toBeVisible();
  await expect(page.getByTestId("outreach-history")).toContainText("Called the registrar.");

  await page.goto("/platform");
  const followUps = page.getByTestId("platform-follow-ups");
  const row = followUps.getByRole("listitem").filter({ hasText: schoolName });
  await expect(row).toContainText("Called the registrar.");
  await row.getByRole("button", { name: "Done" }).click();
  await expect(page.getByText("Follow-up done.")).toBeVisible();
  await expect(page.getByTestId("platform-follow-ups").getByRole("listitem").filter({ hasText: schoolName })).toHaveCount(0);
});
