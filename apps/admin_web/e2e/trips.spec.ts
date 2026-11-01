import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex").toUpperCase();
const prefix = `E2E-TRIP-${tag}`;

let admin: TestUser;
let staff: TestUser;
let student: TestUser;
let driver: TestUser;
let busId: string;
let idleBusId: string;
let scheduledId: string;
let activeId: string;

// Far in the future so the trips are always on the first page of the newest-first list.
const START = "2090-06-01T07:30";
// The seed school is in Africa/Douala, which is UTC+1 all year.
const START_UTC = "2090-06-01T06:30:00+00:00";

test.beforeAll(async () => {
  admin = await createUser(`trip-admin-${tag}`, "admin");
  staff = await createUser(`trip-staff-${tag}`, "staff");
  student = await createUser(`trip-student-${tag}`, "student");
  driver = await createUser(`trip-driver-${tag}`, "staff");

  const db = serviceClient();
  const bus = await db
    .from("buses")
    .insert({ school_id: SEED.schoolId, plate: `${prefix} RUN`, capacity: 40 })
    .select("id")
    .single();
  const idle = await db
    .from("buses")
    .insert({ school_id: SEED.schoolId, plate: `${prefix} IDLE`, capacity: 40, in_service: false })
    .select("id")
    .single();
  if (!bus.data || !idle.data) throw new Error(`could not create buses: ${bus.error?.message ?? idle.error?.message}`);
  busId = bus.data.id;
  idleBusId = idle.data.id;

  const trips = await db
    .from("trips")
    .insert([
      { school_id: SEED.schoolId, bus_id: busId, driver_id: driver.id, direction: "inbound", status: "scheduled", scheduled_start: "2090-07-01T06:30:00Z" },
      {
        school_id: SEED.schoolId,
        bus_id: busId,
        driver_id: null,
        direction: "outbound",
        status: "active",
        scheduled_start: "2090-07-02T06:30:00Z",
        started_at: "2090-07-02T06:31:00Z",
      },
    ])
    .select("id, status");
  if (!trips.data) throw new Error(`could not create trips: ${trips.error?.message}`);
  scheduledId = trips.data.find((trip) => trip.status === "scheduled")!.id;
  activeId = trips.data.find((trip) => trip.status === "active")!.id;
});

test.afterAll(async () => {
  const db = serviceClient();
  await db.from("trips").delete().in("bus_id", [busId, idleBusId]);
  await db.from("buses").delete().like("plate", `${prefix}%`);
  for (const user of [admin, staff, student, driver]) {
    if (user) await deleteUser(user);
  }
});

async function tripOnBus(id: string, bus: string) {
  const { data } = await serviceClient()
    .from("trips")
    .select("id, driver_id, direction, status, scheduled_start")
    .eq("bus_id", bus)
    .neq("id", id);
  return data ?? [];
}

test.describe("administrator managing trips", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("lists trips with bus, direction, driver and status, and filters by status", async ({ page }) => {
    await page.goto("/trips");
    await expect(page.getByRole("heading", { name: "Trips", level: 1 })).toBeVisible();
    const row = page.getByRole("row").filter({ hasText: `${prefix} RUN` }).first();
    await expect(row).toBeVisible();

    await page.getByRole("link", { name: "Running" }).click();
    await expect(page).toHaveURL(/status=active/);
    await expect(page.getByRole("row").filter({ hasText: `${prefix} RUN` })).toContainText("Not assigned");
    await expect(page.getByRole("row").filter({ hasText: `E2E trip-driver-${tag}` })).toHaveCount(0);
  });

  test("schedules a trip and stores the start time in the school timezone", async ({ page }) => {
    await page.goto("/trips/new");
    await page.getByLabel("Bus").selectOption({ label: `${prefix} RUN` });
    await page.getByLabel("Driver").selectOption({ label: `E2E trip-driver-${tag}` });
    await page.getByLabel("Direction").selectOption("outbound");
    await page.getByLabel("Start time").fill(START);
    await page.getByRole("button", { name: "Schedule trip" }).click();

    await expect(page.getByRole("status")).toContainText("Trip scheduled.");
    const created = (await tripOnBus(scheduledId, busId)).filter((trip) => trip.id !== activeId);
    expect(created).toHaveLength(1);
    expect(created[0].driver_id).toBe(driver.id);
    expect(created[0].direction).toBe("outbound");
    expect(created[0].status).toBe("scheduled");
    expect(new Date(created[0].scheduled_start).toISOString()).toBe(new Date(START_UTC).toISOString());
  });

  test("an out-of-service bus is not offered", async ({ page }) => {
    await page.goto("/trips/new");
    await expect(page.getByLabel("Bus").locator("option", { hasText: `${prefix} RUN` })).toHaveCount(1);
    await expect(page.getByLabel("Bus").locator("option", { hasText: `${prefix} IDLE` })).toHaveCount(0);
  });

  test("the server refuses an out-of-service bus even if the form is tampered with", async ({ page }) => {
    await page.goto("/trips/new");
    await page.waitForLoadState("networkidle");
    await page.getByLabel("Bus").evaluate((select, id) => {
      const option = document.createElement("option");
      option.value = id;
      option.textContent = "tampered";
      (select as HTMLSelectElement).appendChild(option);
    }, idleBusId);
    await page.getByLabel("Bus").selectOption("tampered");
    await page.getByLabel("Start time").fill(START);
    await page.getByRole("button", { name: "Schedule trip" }).click();

    await expect(page.getByRole("alert").filter({ hasText: "That bus is not available." })).toBeVisible();
    expect((await tripOnBus(scheduledId, idleBusId)).length).toBe(0);
  });

  test("only staff are offered as drivers", async ({ page }) => {
    await page.goto("/trips/new");
    const options = page.getByLabel("Driver").locator("option");
    await expect(options.filter({ hasText: `E2E trip-driver-${tag}` })).toHaveCount(1);
    await expect(options.filter({ hasText: `E2E trip-student-${tag}` })).toHaveCount(0);
    await expect(options.filter({ hasText: `E2E trip-admin-${tag}` })).toHaveCount(0);
  });

  test("edits a scheduled trip and shows its start in the school timezone", async ({ page }) => {
    await page.goto(`/trips/${scheduledId}`);
    // 2090-07-01T06:30Z is 07:30 in Douala.
    await expect(page.getByLabel("Start time")).toHaveValue("2090-07-01T07:30");

    await page.getByLabel("Driver").selectOption("");
    await page.getByLabel("Start time").fill("2090-07-01T08:15");
    await page.getByRole("button", { name: "Save trip" }).click();

    await expect(page.getByRole("status")).toContainText("Trip saved.");
    const { data } = await serviceClient().from("trips").select("driver_id, scheduled_start").eq("id", scheduledId).single();
    expect(data?.driver_id).toBeNull();
    expect(new Date(data!.scheduled_start).toISOString()).toBe("2090-07-01T07:15:00.000Z");
  });

  test("a running trip cannot be edited", async ({ page }) => {
    await page.goto(`/trips/${activeId}`);
    await expect(page.getByText("can no longer be changed here")).toBeVisible();
    await expect(page.getByRole("button", { name: "Save trip" })).toHaveCount(0);
  });

  test("the browser blocks a missing start time", async ({ page }) => {
    await page.goto("/trips/new");
    await page.getByLabel("Bus").selectOption({ label: `${prefix} RUN` });
    await page.getByRole("button", { name: "Schedule trip" }).click();
    await expect(page).toHaveURL(/\/trips\/new$/);
  });

  test("an unknown or malformed id shows the not-found page", async ({ page }) => {
    await page.goto("/trips/not-a-uuid");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
    await page.goto("/trips/a1000000-0000-4000-8000-0000000000ff");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  });

  test("odd filter and page values fall back safely", async ({ page }) => {
    await page.goto("/trips?status=%27%3Bdrop&page=-4");
    await expect(page.getByRole("heading", { name: "Trips", level: 1 })).toBeVisible();
  });

  test("the pages are available in French", async ({ page }) => {
    await page.goto("/trips");
    await page.getByRole("button", { name: "Français" }).click();
    await expect(page.getByRole("heading", { name: "Trajets", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "Planifier un trajet" })).toBeVisible();
    await page.getByRole("button", { name: "English" }).click();
  });
});

for (const [label, who] of [
  ["a student", () => student],
  ["a staff member", () => staff],
] as const) {
  test(`${label} cannot open the trips pages`, async ({ page, context }) => {
    await signInBrowser(context, who());
    for (const path of ["/trips", "/trips/new", `/trips/${scheduledId}`]) {
      await page.goto(path);
      await expect(page).toHaveURL(/\/no-access$/);
    }
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/trips");
  await expect(page).toHaveURL(/\/login$/);
});
