import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// The student web app's profile and the pages behind it (ADR 0021).
const tag = randomBytes(3).toString("hex");
let student: TestUser;
let driver: TestUser;
let busId = "";
let tripId = "";

test.use({ viewport: { width: 390, height: 844 } });
test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  const db = serviceClient();
  student = await createUser(`web-me-${tag}`, "student");
  driver = await createUser(`web-me-staff-${tag}`, "staff");
  await db.from("profiles").update({ matricule: `ME${tag}`, phone: "+237600000031", full_name: "Amara Ngono" }).eq("id", student.id);
  const sub = await db.from("subscriptions").insert({ school_id: SEED.schoolId, student_id: student.id, semester_id: SEED.semesterId, stop_id: SEED.stopId, status: "approved" }).select("id").single();
  const bus = await db.from("buses").insert({ school_id: SEED.schoolId, plate: `ME-${tag.toUpperCase()}`, capacity: 30 }).select("id").single();
  busId = bus.data!.id;
  const now = new Date().toISOString();
  const trip = await db.from("trips").insert({ school_id: SEED.schoolId, bus_id: busId, direction: "inbound", status: "completed", scheduled_start: now, started_at: now, ended_at: now }).select("id").single();
  tripId = trip.data!.id;
  const scan = await db.from("scans").insert({ school_id: SEED.schoolId, trip_id: tripId, student_id: student.id, subscription_id: sub.data!.id, stop_id: SEED.stopId, scanned_by: driver.id, scanned_at: now });
  if (scan.error) throw new Error(scan.error.message);
});

test.afterAll(async () => {
  const db = serviceClient();
  if (tripId) {
    await db.from("scans").delete().eq("trip_id", tripId);
    await db.from("trips").delete().eq("id", tripId);
  }
  if (busId) await db.from("buses").delete().eq("id", busId);
  for (const user of [student, driver]) if (user) await deleteUser(user);
});

test("edits the details and sees them saved", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/profile");
  await page.getByRole("link", { name: "Edit details" }).click();
  await page.getByLabel("Phone number").fill("+237 699 00 11 22");
  await page.getByRole("button", { name: "Save" }).click();
  await expect(page).toHaveURL(/\/app\/profile\?saved=1$/);
  // Shown with spaces, stored as E.164 (ADR 0024).
  await expect(page.getByText("+237 6 99 00 11 22")).toBeVisible();
  const { data } = await serviceClient().from("profiles").select("phone").eq("id", student.id).single();
  expect(data?.phone).toBe("+237699001122");
});

test("lists boardings by day, with this week's count", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/history");
  await expect(page.getByRole("heading", { name: "Your boardings" })).toBeVisible();
  await expect(page.getByText("1 boarding", { exact: true })).toBeVisible();
  await expect(page.getByText("Going to school")).toBeVisible();
});

test("changes bus days and bus near my stop", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/settings/notifications");
  await expect(page.getByText("Morning and evening reminders are only in the BusIn app for now.")).toBeVisible();
  await page.getByText("Sat", { exact: true }).click();
  await page.getByText("10 min", { exact: true }).click();
  await page.getByRole("button", { name: "Save" }).click();
  await expect(page.getByText("Saved.")).toBeVisible();
  const { data } = await serviceClient().from("notification_preferences").select("riding_days, bus_near_minutes").eq("user_id", student.id).single();
  expect(data).toEqual({ riding_days: 31 | (1 << 5), bus_near_minutes: 10 });
});

test("saves an area from one rounded reading of the location, and removes it", async ({ page, context }) => {
  await context.grantPermissions(["geolocation"]);
  await context.setGeolocation({ latitude: 3.84876, longitude: 11.50231 });
  await signInBrowser(context, student);
  await page.goto("/app/settings/area");
  await page.getByRole("button", { name: "Yes, I am home" }).click();
  await page.getByRole("dialog").getByRole("button", { name: "Continue" }).click();
  await page.getByLabel("What do you call this area?").fill("Biyem-Assi");
  await page.getByRole("button", { name: "Save my area" }).click();
  await expect(page.getByText("Saved as Biyem-Assi")).toBeVisible();
  await page.getByRole("button", { name: "Remove my area" }).click();
  await expect(page.getByText("Saved as Biyem-Assi")).toHaveCount(0);
});

test("turns streaks on, sees the leaderboard, and turns them off", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/streaks");
  await page.getByRole("button", { name: "Turn on streaks" }).click();
  await expect(page.getByTestId("streak-card")).toBeVisible();
  await expect(page.getByRole("heading", { name: "Leaderboard" })).toBeVisible();
  await page.getByRole("button", { name: "Turn off streaks" }).click();
  await expect(page.getByRole("button", { name: "Turn on streaks" })).toBeVisible();
});

test("reads the privacy policy in French", async ({ page, context }) => {
  await signInBrowser(context, student);
  await context.addCookies([{ name: "locale", value: "fr", url: "http://127.0.0.1:" + (process.env.E2E_PORT ?? "3000") }]);
  await page.goto("/app/legal");
  await page.getByRole("link", { name: /Politique de confidentialité/ }).click();
  await expect(page.getByRole("heading", { name: "En bref" })).toBeVisible();
  await expect(page.getByRole("navigation", { name: "BusIn" }).getByRole("link", { name: "Profil" })).toHaveAttribute("aria-current", "page");
});
