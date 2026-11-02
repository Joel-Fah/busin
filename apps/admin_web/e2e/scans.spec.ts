import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import {
  SEED,
  createSubscription,
  createUser,
  deleteUser,
  serviceClient,
  signInBrowser,
  type TestUser,
} from "./support";

const tag = randomBytes(3).toString("hex").toUpperCase();
const prefix = `E2E-SCAN-${tag}`;
const SECOND_STOP = "00000000-0000-4000-8000-000000000022";

let admin: TestUser;
let staff: TestUser;
let studentA: TestUser;
let studentB: TestUser;
let busId: string;
let tripActiveId: string;
let tripDoneId: string;

test.beforeAll(async () => {
  admin = await createUser(`scan-admin-${tag}`, "admin");
  staff = await createUser(`scan-staff-${tag}`, "staff");
  studentA = await createUser(`scan-alice-${tag}`, "student");
  studentB = await createUser(`scan-bob-${tag}`, "student");

  const db = serviceClient();
  const bus = await db
    .from("buses")
    .insert({ school_id: SEED.schoolId, plate: `${prefix} BUS`, capacity: 40 })
    .select("id")
    .single();
  if (!bus.data) throw new Error(`could not create a bus: ${bus.error?.message}`);
  busId = bus.data.id;

  const trips = await db
    .from("trips")
    .insert([
      {
        school_id: SEED.schoolId,
        bus_id: busId,
        driver_id: null,
        direction: "inbound",
        status: "active",
        scheduled_start: "2090-07-02T06:30:00Z",
        started_at: "2090-07-02T06:31:00Z",
      },
      {
        school_id: SEED.schoolId,
        bus_id: busId,
        driver_id: null,
        direction: "outbound",
        status: "completed",
        scheduled_start: "2090-07-03T06:30:00Z",
        started_at: "2090-07-03T06:31:00Z",
        ended_at: "2090-07-03T07:30:00Z",
      },
    ])
    .select("id, status");
  if (!trips.data) throw new Error(`could not create trips: ${trips.error?.message}`);
  tripActiveId = trips.data.find((trip) => trip.status === "active")!.id;
  tripDoneId = trips.data.find((trip) => trip.status === "completed")!.id;

  const subA = await createSubscription(studentA.id);
  const subB = await createSubscription(studentB.id);
  const scans = await db.from("scans").insert([
    {
      school_id: SEED.schoolId,
      trip_id: tripActiveId,
      student_id: studentA.id,
      subscription_id: subA,
      stop_id: SEED.stopId,
      scanned_by: staff.id,
      scanned_at: "2090-07-02T06:40:00Z",
    },
    {
      school_id: SEED.schoolId,
      trip_id: tripDoneId,
      student_id: studentB.id,
      subscription_id: subB,
      stop_id: SECOND_STOP,
      scanned_by: staff.id,
      scanned_at: "2090-07-03T06:40:00Z",
    },
  ]);
  if (scans.error) throw new Error(`could not create scans: ${scans.error.message}`);
});

test.afterAll(async () => {
  const db = serviceClient();
  await db.from("scans").delete().in("trip_id", [tripActiveId, tripDoneId]);
  await db.from("subscriptions").delete().in("student_id", [studentA.id, studentB.id]);
  await db.from("trips").delete().eq("bus_id", busId);
  await db.from("buses").delete().eq("id", busId);
  for (const user of [admin, staff, studentA, studentB]) {
    if (user) await deleteUser(user);
  }
});

const alice = `E2E scan-alice-${tag}`;
const bob = `E2E scan-bob-${tag}`;

test.describe("administrator viewing boardings", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("lists boardings newest first with student, bus and direction", async ({ page }) => {
    await page.goto("/scans");
    await expect(page.getByRole("heading", { name: "Boardings", level: 1 })).toBeVisible();

    const rows = page.getByRole("row").filter({ hasText: `${prefix} BUS` });
    await expect(rows).toHaveCount(2);
    await expect(rows.first()).toContainText(bob);
    await expect(rows.first()).toContainText("From campus");
    await expect(rows.last()).toContainText(alice);
    await expect(rows.last()).toContainText("To campus");
  });

  test("filters by day in the school timezone", async ({ page }) => {
    await page.goto("/scans");
    await page.getByLabel("Day").fill("2090-07-02");
    await page.getByRole("button", { name: "Apply" }).click();

    await expect(page).toHaveURL(/date=2090-07-02/);
    await expect(page.getByRole("row").filter({ hasText: alice })).toHaveCount(1);
    await expect(page.getByRole("row").filter({ hasText: bob })).toHaveCount(0);
  });

  test("filters by stop", async ({ page }) => {
    await page.goto(`/scans?stop=${SECOND_STOP}`);
    await expect(page.getByRole("row").filter({ hasText: bob })).toHaveCount(1);
    await expect(page.getByRole("row").filter({ hasText: alice })).toHaveCount(0);
  });

  test("a trip links to its boardings", async ({ page }) => {
    await page.goto(`/trips/${tripDoneId}`);
    await page.getByRole("link", { name: "View boardings" }).click();

    await expect(page).toHaveURL(new RegExp(`/scans\\?trip=${tripDoneId}`));
    await expect(page.getByRole("row").filter({ hasText: bob })).toHaveCount(1);
    await expect(page.getByRole("row").filter({ hasText: alice })).toHaveCount(0);
    await expect(page.getByText(`${prefix} BUS`).first()).toBeVisible();

    await page.getByRole("link", { name: "Show all trips" }).click();
    await expect(page).toHaveURL(/\/scans$/);
  });

  test("says so when no boarding matches", async ({ page }) => {
    await page.goto("/scans?date=2091-01-01");
    await expect(page.getByText("No boardings match these filters.")).toBeVisible();
  });

  test("odd filter and page values fall back safely", async ({ page }) => {
    await page.goto("/scans?trip=%27%3Bdrop&stop=x&date=2026-02-30&page=-2");
    await expect(page.getByRole("heading", { name: "Boardings", level: 1 })).toBeVisible();
    await expect(page.getByText("could not be loaded")).toHaveCount(0);
  });

  test("the pages are available in French", async ({ page }) => {
    await page.goto("/scans");
    await page.getByRole("button", { name: "Français" }).click();
    await expect(page.getByRole("heading", { name: "Embarquements", level: 1 })).toBeVisible();
    await page.getByRole("button", { name: "English" }).click();
  });
});

for (const [label, who] of [
  ["a student", () => studentA],
  ["a staff member", () => staff],
] as const) {
  test(`${label} cannot open the boardings page`, async ({ page, context }) => {
    await signInBrowser(context, who());
    await page.goto("/scans");
    await expect(page).toHaveURL(/\/no-access$/);
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/scans");
  await expect(page).toHaveURL(/\/login$/);
});
