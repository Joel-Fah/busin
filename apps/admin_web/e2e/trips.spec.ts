import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, chooseOption, createUser, deleteUser, pickDate, pickDateTime, serviceClient, setLanguage, setPickerValue, signInBrowser, userClient, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex").toUpperCase();
const prefix = `E2E-TRIP-${tag}`;

let admin: TestUser;
let staff: TestUser;
let student: TestUser;
let driver: TestUser;
let assistant: TestUser;
let busId: string;
let idleBusId: string;
let scheduledId: string;
let activeId: string;
let cancelId: string;
let finishedId: string;

// Far in the future so the trips are always on the first page of the newest-first list.
const START = "2090-06-01T07:30";
// The seed school is in Africa/Douala, which is UTC+1 all year.
const START_UTC = "2090-06-01T06:30:00+00:00";

test.beforeAll(async () => {
  admin = await createUser(`trip-admin-${tag}`, "admin");
  staff = await createUser(`trip-staff-${tag}`, "staff");
  student = await createUser(`trip-student-${tag}`, "student");
  driver = await createUser(`trip-driver-${tag}`, "staff");
  assistant = await createUser(`trip-assistant-${tag}`, "staff");

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
      { school_id: SEED.schoolId, bus_id: busId, driver_id: null, direction: "inbound", status: "scheduled", scheduled_start: "2090-08-01T06:30:00Z" },
      {
        school_id: SEED.schoolId,
        bus_id: busId,
        driver_id: null,
        direction: "outbound",
        status: "completed",
        scheduled_start: "2090-08-02T06:30:00Z",
        started_at: "2090-08-02T06:31:00Z",
        ended_at: "2090-08-02T07:10:00Z",
      },
    ])
    .select("id, status, scheduled_start");
  if (!trips.data) throw new Error(`could not create trips: ${trips.error?.message}`);
  const at = (day: string) => trips.data.find((trip) => trip.scheduled_start.startsWith(day))!.id;
  scheduledId = at("2090-07-01");
  activeId = at("2090-07-02");
  cancelId = at("2090-08-01");
  finishedId = at("2090-08-02");
});

test.afterAll(async () => {
  const db = serviceClient();
  // Audit rows point at the acting admin, so they go before the user does.
  await db.from("audit_log").delete().eq("actor_id", admin?.id ?? "");
  await db.from("trips").delete().in("bus_id", [busId, idleBusId]);
  await db.from("buses").delete().like("plate", `${prefix}%`);
  for (const user of [admin, staff, student, driver, assistant]) {
    if (user) await deleteUser(user);
  }
});

async function tripOnBus(id: string, bus: string) {
  const { data } = await serviceClient()
    .from("trips")
    .select("id, driver_id, assistant_id, direction, status, scheduled_start")
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
    await chooseOption(page, "Bus", `${prefix} RUN`);
    await chooseOption(page, "Driver", `E2E trip-driver-${tag}`);
    await chooseOption(page, "Assistant", `E2E trip-assistant-${tag}`);
    await chooseOption(page, "Direction", "Going home");
    await pickDateTime(page, START);
    await page.getByRole("button", { name: "Schedule trip" }).click();

    await expect(page.getByRole("status")).toContainText("Trip scheduled.");
    const created = (await tripOnBus(scheduledId, busId)).filter((trip) => ![activeId, cancelId, finishedId].includes(trip.id));
    expect(created).toHaveLength(1);
    expect(created[0].driver_id).toBe(driver.id);
    expect(created[0].assistant_id).toBe(assistant.id);
    expect(created[0].direction).toBe("outbound");
    expect(created[0].status).toBe("scheduled");
    expect(new Date(created[0].scheduled_start).toISOString()).toBe(new Date(START_UTC).toISOString());
  });

  test("the assistant cannot be the driver", async ({ page }) => {
    await page.goto("/trips/new");
    await chooseOption(page, "Bus", `${prefix} RUN`);
    await chooseOption(page, "Driver", `E2E trip-driver-${tag}`);
    await chooseOption(page, "Assistant", `E2E trip-driver-${tag}`);
    await pickDateTime(page, START);
    await page.getByRole("button", { name: "Schedule trip" }).click();
    await expect(page.getByRole("alert").filter({ hasText: "The driver and the assistant must be two different people." })).toBeVisible();
  });

  test("a trip started in the field shows a chip, who started it, and can be filtered", async ({ page }) => {
    const db = serviceClient();
    const { data: field, error } = await db
      .from("trips")
      .insert({
        school_id: SEED.schoolId,
        bus_id: busId,
        driver_id: driver.id,
        direction: "inbound",
        status: "completed",
        scheduled_start: "2090-09-01T06:30:00Z",
        started_at: "2090-09-01T06:30:00Z",
        ended_at: "2090-09-01T07:10:00Z",
        origin: "field",
        created_by: driver.id,
      })
      .select("id")
      .single();
    expect(error).toBeNull();
    try {
      await page.goto("/trips?source=field");
      const row = page.getByRole("row").filter({ hasText: `${prefix} RUN` });
      await expect(row).toHaveCount(1);
      await expect(row).toContainText("Field");
      await expect(page.getByRole("row").filter({ hasText: "Not assigned" }).filter({ hasText: "Field" })).toHaveCount(0);

      await page.goto(`/trips/${field!.id}`);
      await expect(page.getByText("Started in the field").first()).toBeVisible();
      await expect(page.getByText(new RegExp(`E2E trip-driver-${tag}.* started this trip from the ops app`))).toBeVisible();
    } finally {
      await db.from("trips").delete().eq("id", field!.id);
    }
  });

  test("an out-of-service bus is not offered", async ({ page }) => {
    await page.goto("/trips/new");
    await page.getByRole("combobox", { name: "Bus" }).click();
    const list = page.getByRole("listbox", { name: "Bus" });
    await expect(list.getByRole("option", { name: new RegExp(`${prefix} RUN`) })).toHaveCount(1);
    await expect(list.getByRole("option", { name: new RegExp(`${prefix} IDLE`) })).toHaveCount(0);
  });

  test("the server refuses an out-of-service bus even if the form is tampered with", async ({ page }) => {
    await page.goto("/trips/new");
    await page.waitForLoadState("networkidle");
    // The idle bus is not in the list, so put its id in the field the form submits.
    await pickDateTime(page, START);
    await setPickerValue(page, "bus_id", idleBusId);
    await page.getByRole("button", { name: "Schedule trip" }).click();

    await expect(page.getByRole("alert").filter({ hasText: "That bus is not available." })).toBeVisible();
    expect((await tripOnBus(scheduledId, idleBusId)).length).toBe(0);
  });

  test("only staff are offered as drivers", async ({ page }) => {
    await page.goto("/trips/new");
    await page.getByRole("combobox", { name: "Driver" }).click();
    const options = page.getByRole("listbox", { name: "Driver" }).getByRole("option");
    await expect(options.filter({ hasText: `E2E trip-driver-${tag}` })).toHaveCount(1);
    await expect(options.filter({ hasText: `E2E trip-student-${tag}` })).toHaveCount(0);
    await expect(options.filter({ hasText: `E2E trip-admin-${tag}` })).toHaveCount(0);
  });

  test("edits a scheduled trip and shows its start in the school timezone", async ({ page }) => {
    await page.goto(`/trips/${scheduledId}`);
    // 2090-07-01T06:30Z is 07:30 in Douala.
    await expect(page.locator('input[name="scheduled_start"]')).toHaveValue("2090-07-01T07:30");

    await chooseOption(page, "Driver", "Not assigned yet");
    await pickDateTime(page, "2090-07-01T08:15");
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

  test("cancelling a trip keeps it, records the reason and locks it", async ({ page }) => {
    await page.goto(`/trips/${cancelId}`);
    await page.getByText("Cancel this trip", { exact: true }).last().click();
    await page.getByLabel("Reason").fill("The bus is in the garage.");
    await page.getByRole("button", { name: "Cancel trip" }).click();

    await expect(page.getByRole("status")).toContainText("Trip cancelled.");
    const db = serviceClient();
    expect((await db.from("trips").select("status").eq("id", cancelId).single()).data?.status).toBe("cancelled");
    const { data: entries } = await db.from("audit_log").select("actor_id, details").eq("target_id", cancelId).eq("action", "trip.cancelled");
    expect(entries).toHaveLength(1);
    expect(entries?.[0].actor_id).toBe(admin.id);
    expect(entries?.[0].details).toMatchObject({ reason: "The bus is in the garage." });

    // It cannot be cancelled again, and it can now be archived.
    await expect(page.getByRole("button", { name: "Cancel trip" })).toHaveCount(0);
    await expect(page.getByRole("button", { name: "Archive trip" })).toBeVisible();
  });

  test("a running trip offers neither cancel nor archive", async ({ page }) => {
    await page.goto(`/trips/${activeId}`);
    await expect(page.getByText("can no longer be changed here")).toBeVisible();
    await expect(page.getByText("Cancel this trip")).toHaveCount(0);
    await expect(page.getByRole("button", { name: "Archive trip" })).toHaveCount(0);
  });

  test("an archived trip leaves the lists, shows under Archived, and can be restored", async ({ page }) => {
    const when = /Aug 2, 2090/;
    await page.goto(`/trips/${finishedId}`);
    await page.getByRole("button", { name: "Archive trip" }).click();
    await expect(page.getByRole("status")).toContainText("Trip archived.");
    await expect(page.getByText("Archived", { exact: true }).first()).toBeVisible();
    expect((await serviceClient().from("trips").select("archived_at").eq("id", finishedId).single()).data?.archived_at).not.toBeNull();

    await page.goto("/trips?status=completed");
    await expect(page.getByRole("row").filter({ hasText: when })).toHaveCount(0);
    await page.goto("/trips?status=archived");
    await expect(page.getByRole("row").filter({ hasText: when })).toHaveCount(1);

    await page.goto(`/trips/${finishedId}`);
    await page.getByRole("button", { name: "Restore trip" }).click();
    await expect(page.getByRole("status")).toContainText("Trip restored.");
    await page.goto("/trips?status=archived");
    await expect(page.getByRole("row").filter({ hasText: when })).toHaveCount(0);
  });

  test("a trip cannot be deleted through the API, even by an administrator", async () => {
    const { error, count } = await (await userClient(admin)).from("trips").delete({ count: "exact" }).eq("id", finishedId);
    expect(error !== null || count === 0).toBe(true);
    const { data } = await serviceClient().from("trips").select("id").eq("id", finishedId);
    expect(data).toHaveLength(1);
  });

  test("filters from the column headings, shows each as a chip, and the chips remove them", async ({ page }) => {
    await page.goto("/trips");
    await page.getByRole("button", { name: "Direction", exact: true }).click();
    await page.getByRole("dialog", { name: "Direction" }).getByRole("link", { name: "Going home" }).click();
    await expect(page).toHaveURL(/direction=outbound/);

    await page.getByRole("button", { name: /^Bus/ }).click();
    await page.getByRole("dialog", { name: "Bus" }).getByRole("link", { name: `${prefix} RUN` }).click();
    await expect(page).toHaveURL(/bus=/);

    const chips = page.getByRole("group", { name: "Active filters" });
    await expect(chips.getByRole("link", { name: /Direction Going home/ })).toBeVisible();
    await expect(chips.getByRole("link", { name: new RegExp(`Bus ${prefix} RUN`) })).toBeVisible();
    // Going home on this bus: the finished trip of 2 August, not the scheduled one of 1 July.
    await expect(page.getByRole("row").filter({ hasText: /Aug 2, 2090/ })).toHaveCount(1);
    await expect(page.getByRole("row").filter({ hasText: /Jul 1, 2090/ })).toHaveCount(0);

    await chips.getByRole("link", { name: /Direction Going home/ }).click();
    await expect(page).not.toHaveURL(/direction=/);
    await expect(page).toHaveURL(/bus=/);
    await page.getByRole("group", { name: "Active filters" }).getByRole("link", { name: /Bus/ }).click();
    await expect(page).toHaveURL(/\/trips$/);
    await expect(page.getByRole("group", { name: "Active filters" })).toHaveCount(0);
  });

  test("filters by day in the school timezone from the Start heading", async ({ page }) => {
    await page.goto("/trips");
    await page.getByRole("button", { name: "Start", exact: true }).click();
    await pickDate(page, "Day", "2090-07-01");
    await expect(page).toHaveURL(/date=2090-07-01/);
    await expect(page.getByRole("row").filter({ hasText: /Jul 1, 2090/ })).toHaveCount(1);
    await expect(page.getByRole("row").filter({ hasText: /Jul 2, 2090/ })).toHaveCount(0);
  });

  test("filters by driver, including trips that have none yet", async ({ page }) => {
    // Its own trip, so the test does not depend on what the others changed.
    const own = await serviceClient()
      .from("trips")
      .insert({ school_id: SEED.schoolId, bus_id: busId, driver_id: driver.id, direction: "inbound", status: "scheduled", scheduled_start: "2090-09-15T06:30:00Z" })
      .select("id")
      .single();
    expect(own.error).toBeNull();

    await page.goto("/trips?driver=none");
    await expect(page.getByRole("row").filter({ hasText: /Jul 2, 2090/ })).toHaveCount(1);
    await expect(page.getByRole("row").filter({ hasText: /Sep 15, 2090/ })).toHaveCount(0);
    await page.goto(`/trips?driver=${driver.id}`);
    await expect(page.getByRole("row").filter({ hasText: /Sep 15, 2090/ })).toHaveCount(1);
    await expect(page.getByRole("row").filter({ hasText: /Jul 2, 2090/ })).toHaveCount(0);
  });

  test("the numbers on the tabs follow the filters", async ({ page }) => {
    const { count } = await serviceClient()
      .from("trips")
      .select("id", { count: "exact", head: true })
      .eq("direction", "outbound")
      .is("archived_at", null);
    await page.goto("/trips?direction=outbound");
    const tabs = page.getByRole("navigation", { name: "Filter by status" });
    await expect(tabs.getByRole("link", { name: /All/ })).toContainText(String(count ?? 0));
    // No trip is on the idle bus, so every tab reads 0 and the list says so.
    await page.goto(`/trips?bus=${idleBusId}`);
    await expect(tabs.getByRole("link", { name: /All/ })).toContainText("0");
    await expect(page.getByText("No trips match this filter.")).toBeVisible();
    await expect(page.getByText("Try removing a filter above the table.")).toBeVisible();
  });

  test("odd filter values fall back safely", async ({ page }) => {
    await page.goto("/trips?bus=x&driver=%27%3B&direction=up&date=2026-02-30");
    await expect(page.getByRole("heading", { name: "Trips", level: 1 })).toBeVisible();
    await expect(page.getByRole("group", { name: "Active filters" })).toHaveCount(0);
    await expect(page.getByText("could not be loaded")).toHaveCount(0);
  });

  test("a missing start time is refused with a clear message", async ({ page }) => {
    await page.goto("/trips/new");
    await chooseOption(page, "Bus", `${prefix} RUN`);
    await page.getByRole("button", { name: "Schedule trip" }).click();
    await expect(page.getByRole("alert")).toBeVisible();
    await expect(page).toHaveURL(/\/trips\/new\?error=/);
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

  test("each tab shows how many trips are behind it, matching the database", async ({ page }) => {
    const db = serviceClient();
    const total = async (status?: "scheduled" | "active" | "completed" | "cancelled") => {
      let query = db.from("trips").select("id", { count: "exact", head: true }).is("archived_at", null);
      if (status) query = query.eq("status", status);
      const { count } = await query;
      return count ?? 0;
    };
    await page.goto("/trips");
    const tabs = page.getByRole("navigation", { name: "Filter by status" });
    await expect(tabs.getByRole("link", { name: /Scheduled/ })).toContainText(String(await total("scheduled")));
    await expect(tabs.getByRole("link", { name: /Running/ })).toContainText(String(await total("active")));
    await expect(tabs.getByRole("link", { name: /All/ })).toContainText(String(await total()));
  });

  test("a page past the last one shows an empty state, not an error", async ({ page }) => {
    await page.goto("/trips?status=cancelled&page=50");
    await expect(page.getByText("No trips match this filter.")).toBeVisible();
    await expect(page.getByText("could not be loaded")).toHaveCount(0);
  });

  test("the help button explains trips with examples", async ({ page }) => {
    await page.goto("/trips");
    await page.getByRole("button", { name: "Help" }).click();
    await expect(page.getByRole("dialog", { name: "How trips work" }).getByText("The driver changes")).toBeVisible();
  });

  test("the pages are available in French", async ({ page }) => {
    await setLanguage(page, "fr");
    await page.goto("/trips");
    await expect(page.getByRole("heading", { name: "Trajets", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "Planifier un trajet" })).toBeVisible();
    await setLanguage(page, "en");
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

test.describe("the sticky bar on a tabs-only page", () => {
  test("stretches to the width of the table when it sticks, and relaxes at the top", async ({ page, context }) => {
    await signInBrowser(context, admin);
    await page.setViewportSize({ width: 1280, height: 420 });
    await page.goto("/trips");
    const bar = page.locator(".sticky-toolbar");
    const tabs = page.getByRole("navigation", { name: "Filter by status" });
    const table = page.getByRole("table");

    await expect(bar).toHaveAttribute("data-stuck", "false");
    const roomy = (await tabs.boundingBox())!;
    expect(roomy.width).toBeLessThan(900);

    await page.mouse.wheel(0, 900);
    await expect(bar).toHaveAttribute("data-stuck", "true");
    const tableBox = (await table.boundingBox())!;
    // The tabs share the bar, so they are about as wide as the table (less the bar's own padding).
    await expect.poll(async () => (await tabs.boundingBox())!.width).toBeGreaterThan(tableBox.width - 60);
    expect((await bar.boundingBox())!.width).toBeGreaterThan(tableBox.width - 4);

    await page.mouse.wheel(0, -3000);
    await expect(bar).toHaveAttribute("data-stuck", "false");
    await expect.poll(async () => (await tabs.boundingBox())!.width).toBeLessThan(900);
  });
});
