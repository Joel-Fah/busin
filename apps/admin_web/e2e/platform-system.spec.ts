import { randomBytes, randomUUID } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteSchool, deleteUser, serviceClient, setPlatformAdmin, signInBrowser, type TestUser } from "./support";

// Usage, costs and system health in the platform console (ADR 0027, slice 6).
const tag = randomBytes(3).toString("hex");
const schoolId = randomUUID();
const busId = randomUUID();
const tripId = randomUUID();
const schoolName = `E2E Quiet ${tag}`;
let owner: TestUser;

test.beforeAll(async () => {
  const admin = serviceClient();
  owner = await createUser(`system-owner-${tag}`, "admin");
  setPlatformAdmin(owner.id, true);
  const hourAgo = new Date(Date.now() - 3_600_000).toISOString();
  for (const step of [
    () => admin.from("schools").insert({ id: schoolId, name: schoolName }),
    () => admin.from("buses").insert({ id: busId, school_id: schoolId, plate: `Q-${tag}`, capacity: 30 }),
    // Running for an hour, and its bus never sent a position.
    () => admin.from("trips").insert({ id: tripId, school_id: schoolId, bus_id: busId, direction: "inbound", status: "active", scheduled_start: hourAgo, started_at: hourAgo }),
  ]) {
    const { error } = await step();
    if (error) throw error;
  }
});

test.afterAll(async () => {
  setPlatformAdmin(owner.id, false);
  const admin = serviceClient();
  await admin.from("trips").delete().eq("id", tripId);
  await admin.from("buses").delete().eq("id", busId);
  deleteSchool(schoolId);
  await deleteUser(owner);
});

test.use({ viewport: { width: 1280, height: 900 } });

test("the health page shows the plan limits, the jobs, push and a bus gone quiet", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform");
  await page.getByTestId("platform-system-checks").click();
  await expect(page).toHaveURL(/\/platform\/health$/);
  await expect(page.getByRole("heading", { name: "Health", level: 1 })).toBeVisible();

  for (const id of ["limit-database", "limit-storage", "limit-accounts", "limit-directions"]) {
    await expect(page.getByTestId(id).getByRole("meter")).toBeVisible();
  }
  await expect(page.getByTestId("limit-database")).toContainText("of 500 MB");

  const jobs = page.getByTestId("jobs");
  await expect(jobs.locator('[data-job="busin-send-push"]')).toContainText("Send push notifications");
  await expect(jobs.locator('[data-job="busin-send-push"]')).toContainText("Every minute");
  await expect(jobs.locator('[data-job="busin-school-health"]')).toContainText("Every day at 02:20 UTC");

  await expect(page.getByTestId("push")).toContainText("sent in 7 days");
  await expect(page.getByTestId("quiet-trips").getByRole("link", { name: schoolName })).toBeVisible();

  const nav = page.getByRole("navigation", { name: "Main navigation" });
  await expect(nav.getByRole("link", { name: "Health", exact: true })).toHaveAttribute("aria-current", "page");
});

test("a school admin cannot open it", async ({ context, page }) => {
  const admin = await createUser(`system-admin-${tag}`, "admin");
  try {
    await signInBrowser(context, admin);
    await page.goto("/platform/health");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  } finally {
    await deleteUser(admin);
  }
});
