import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex").toUpperCase();
const plate = `E2E-OD-${tag}`;

let admin: TestUser;
let busId: string;
let tripId: string;

test.beforeAll(async () => {
  admin = await createUser(`overdue-admin-${tag}`, "admin");
  const db = serviceClient();
  const bus = await db.from("buses").insert({ school_id: SEED.schoolId, plate, capacity: 30 }).select("id").single();
  if (bus.error || !bus.data) throw new Error(`could not create a bus: ${bus.error?.message}`);
  busId = bus.data.id;
  // A trip started two days ago and never ended.
  const started = new Date(Date.now() - 2 * 86_400_000).toISOString();
  const trip = await db
    .from("trips")
    .insert({ school_id: SEED.schoolId, bus_id: busId, direction: "inbound", status: "active", scheduled_start: started, started_at: started })
    .select("id")
    .single();
  if (trip.error || !trip.data) throw new Error(`could not create a trip: ${trip.error?.message}`);
  tripId = trip.data.id;
});

test.afterAll(async () => {
  const db = serviceClient();
  await db.from("trips").delete().eq("bus_id", busId);
  await db.from("buses").delete().eq("id", busId);
  if (admin) await deleteUser(admin);
});

test("a trip left running gets attention, and an administrator ends it", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/trips?status=active");

  // The Trips tab says something needs attention, and the row says why.
  await expect(page.getByRole("link", { name: "Trips" }).first()).toHaveAccessibleDescription(/\d+ need attention/);
  const row = page.getByRole("row").filter({ hasText: plate });
  await expect(row).toContainText("Running too long");

  await page.goto(`/trips/${tripId}`);
  await expect(page.getByText(/This trip should probably have ended: Still running since/)).toBeVisible();
  await page.getByRole("button", { name: "End trip" }).click();
  await expect(page.getByText("Trip ended.")).toBeVisible();

  const { data } = await serviceClient().from("trips").select("status, ended_at").eq("id", tripId).single();
  expect(data?.status).toBe("completed");
  expect(data?.ended_at).not.toBeNull();
  await expect(page.getByText("Running too long")).toHaveCount(0);
});
