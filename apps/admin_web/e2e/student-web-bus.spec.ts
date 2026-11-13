import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// The student web app's My bus (ADR 0021): for subscribers only, the followed bus live, the arrival at their stop.
const tag = randomBytes(3).toString("hex");
let rider: TestUser;
let outsider: TestUser;
let busId = "";
let tripId = "";
// The seed stop is at 3.8399, 11.49596; the bus starts about 1.5 km north of it, on the way.
const point = (lat: number, lng: number) => `SRID=4326;POINT(${lng} ${lat})`;

test.use({ viewport: { width: 390, height: 844 } });
test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  const db = serviceClient();
  rider = await createUser(`web-bus-${tag}`, "student");
  outsider = await createUser(`web-nobus-${tag}`, "student");
  for (const [user, n] of [[rider, 7], [outsider, 8]] as const) {
    await db.from("profiles").update({ matricule: `BUS${tag}${n}`, phone: `+23760000001${n}`, full_name: "Amara Ngono" }).eq("id", user.id);
  }
  await db.from("subscriptions").insert({ school_id: SEED.schoolId, student_id: rider.id, semester_id: SEED.semesterId, stop_id: SEED.stopId, status: "approved" });
});

test.afterAll(async () => {
  const db = serviceClient();
  if (busId) await db.from("live_positions").delete().eq("bus_id", busId);
  if (tripId) await db.from("trips").delete().eq("id", tripId);
  if (busId) await db.from("buses").delete().eq("id", busId);
  for (const user of [rider, outsider]) if (user) await deleteUser(user);
});

test("following the bus is for subscribers", async ({ page, context }) => {
  await signInBrowser(context, outsider);
  await page.goto("/app/bus");
  await expect(page.getByText("Following the bus is for subscribers")).toBeVisible();
  await expect(page.getByRole("link", { name: "Go to subscription" })).toBeVisible();
});

test("a subscriber is told when no bus is running", async ({ page, context }) => {
  await serviceClient().from("trips").update({ status: "completed", ended_at: new Date().toISOString() }).eq("school_id", SEED.schoolId).eq("status", "active");
  await signInBrowser(context, rider);
  await page.goto("/app/bus");
  await expect(page.getByText("No bus is running right now")).toBeVisible();
});

test("a subscriber follows the running bus live, with its arrival at their stop", async ({ page, context }) => {
  const db = serviceClient();
  const bus = await db.from("buses").insert({ school_id: SEED.schoolId, plate: `E2E-${tag.toUpperCase()}`, name: `Bus ${tag}`, capacity: 40 }).select("id").single();
  busId = bus.data!.id;
  const now = new Date().toISOString();
  const trip = await db.from("trips").insert({ school_id: SEED.schoolId, bus_id: busId, direction: "inbound", status: "active", scheduled_start: now, started_at: now }).select("id").single();
  tripId = trip.data!.id;
  await db.from("live_positions").upsert({ bus_id: busId, school_id: SEED.schoolId, trip_id: tripId, location: point(3.8534, 11.49596), speed_mps: 10, source: "phone", recorded_at: now });

  await signInBrowser(context, rider);
  await page.goto("/app/bus");
  const status = page.getByTestId("bus-status");
  await expect(status).toContainText(`Bus ${tag} · Going to school`);
  await expect(status).toContainText("Estimated arrival");
  await expect(status).toContainText(/\d+ min/);
  await expect(page.getByTestId("bus-update")).toHaveText(`Following Bus ${tag} · Going to school`);
  await expect(page.getByLabel("Map of the bus, your stop and the stops around")).toBeVisible();

  // The bus comes within about 500 m of the stop: the position arrives through Realtime and the screen says it is near.
  await page.waitForTimeout(1500);
  await db.from("live_positions").upsert({ bus_id: busId, school_id: SEED.schoolId, trip_id: tripId, location: point(3.8444, 11.49596), speed_mps: 6, source: "phone", recorded_at: new Date().toISOString() });
  await expect(page.getByTestId("bus-update")).toHaveText(/Almost at your stop, about \d+ min away/);
});
