import { randomBytes, randomUUID } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, serviceClient, setPlatformAdmin, signInBrowser, type TestUser } from "./support";

// School health in the platform console (ADR 0027, slice 2): a school that struggles is flagged with its reasons.
const tag = randomBytes(3).toString("hex");
const schoolId = randomUUID();
const schoolName = `E2E Health ${tag}`;
let owner: TestUser;
let joiner: TestUser;

test.beforeAll(async () => {
  const admin = serviceClient();
  // On BusIn for 60 days (past the grace period), nothing set up, and someone asked to join 15 days ago.
  const { error } = await admin.from("schools").insert({ id: schoolId, name: schoolName, created_at: new Date(Date.now() - 60 * 86_400_000).toISOString() });
  if (error) throw error;
  owner = await createUser(`health-owner-${tag}`, "admin");
  setPlatformAdmin(owner.id, true);
  joiner = await createUser(`health-joiner-${tag}`, "student", "pending", "example.org");
  const asked = await admin
    .from("profiles")
    .update({ school_id: schoolId, join_requested_at: new Date(Date.now() - 15 * 86_400_000).toISOString() })
    .eq("id", joiner.id);
  if (asked.error) throw asked.error;
});

test.afterAll(async () => {
  setPlatformAdmin(owner.id, false);
  await deleteUser(joiner);
  await deleteUser(owner);
  await serviceClient().from("schools").delete().eq("id", schoolId);
});

test.use({ viewport: { width: 1280, height: 900 } });

test("a struggling school is Critical, with its reasons in plain words", async ({ context, page }) => {
  await signInBrowser(context, owner);

  // The overview puts it under "Needs you".
  await page.goto("/platform");
  const needs = page.getByTestId("platform-needs");
  await expect(needs.getByRole("link", { name: new RegExp(schoolName) })).toContainText("Critical");

  // The schools list, filtered to Critical.
  await page.goto("/platform/schools");
  await page.getByRole("link", { name: /^Critical/ }).click();
  await expect(page).toHaveURL(/level=critical$/);
  const row = page.getByRole("row").filter({ hasText: schoolName });
  await expect(row).toContainText("Critical");
  await expect(row).toContainText("7 missing: email domain, price, current semester, stops, route, buses, staff");
  await expect(row).toContainText("A join or staff request has waited 15 days");
  await expect(page.getByRole("row").filter({ hasText: "Off" })).toHaveCount(0);

  // Its page: each signal with its level and thresholds.
  await row.getByRole("link", { name: `Open ${schoolName}` }).click();
  await expect(page.getByRole("heading", { name: schoolName, level: 1 })).toBeVisible();
  const request = page.getByTestId("signal-oldest_request_days");
  await expect(request).toContainText("Critical");
  await expect(request).toContainText("Watch above 3, needs help above 7, critical above 14 (days)");
  await expect(page.getByTestId("signal-oldest_pending_days")).toContainText("No request waiting");
  await expect(page.getByText("No record yet: the first one is made tonight.")).toBeVisible();

  const nav = page.getByRole("navigation", { name: "Main navigation" });
  await expect(nav.getByRole("link", { name: "Schools", exact: true })).toHaveAttribute("aria-current", "page");
});

test("a school admin cannot open a school's health page", async ({ context, page }) => {
  const admin = await createUser(`health-admin-${tag}`, "admin");
  try {
    await signInBrowser(context, admin);
    await page.goto(`/platform/schools/${schoolId}`);
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
    await expect(page.getByText(schoolName)).toHaveCount(0);
  } finally {
    await deleteUser(admin);
  }
});
