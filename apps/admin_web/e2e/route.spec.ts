import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");

let admin: TestUser;
let staff: TestUser;
// What the school had, put back after the tests.
let original: { campus: unknown; campusName: string | null; route: { id: string; stops: { stop_id: string; position: number }[] } | null };
let stopIds: string[] = [];

test.beforeAll(async () => {
  admin = await createUser(`route-admin-${tag}`, "admin");
  staff = await createUser(`route-staff-${tag}`, "staff");
  const db = serviceClient();
  const school = await db.from("schools").select("campus_location, campus_name").eq("id", SEED.schoolId).single();
  const route = await db.from("routes").select("id").eq("school_id", SEED.schoolId).order("created_at").limit(1).maybeSingle();
  const stops = route.data ? await db.from("route_stops").select("stop_id, position").eq("route_id", route.data.id) : { data: [] };
  original = { campus: school.data?.campus_location ?? null, campusName: school.data?.campus_name ?? null, route: route.data ? { id: route.data.id, stops: stops.data ?? [] } : null };
  const active = await db.from("stops").select("id").eq("school_id", SEED.schoolId).eq("active", true).order("name").limit(3);
  stopIds = (active.data ?? []).map((s) => s.id);
});

test.afterAll(async () => {
  const db = serviceClient();
  await db.from("schools").update({ campus_location: original.campus as string | null, campus_name: original.campusName }).eq("id", SEED.schoolId);
  await db.from("routes").delete().eq("school_id", SEED.schoolId);
  if (original.route) {
    await db.from("routes").insert({ id: original.route.id, school_id: SEED.schoolId });
    if (original.route.stops.length > 0) {
      await db.from("route_stops").insert(original.route.stops.map((s) => ({ ...s, route_id: original.route!.id, school_id: SEED.schoolId })));
    }
  }
  for (const user of [admin, staff]) if (user) await deleteUser(user);
});

test("an administrator orders the route, and the directions follow it to the campus", async ({ page, context }) => {
  test.skip(stopIds.length < 2, "needs two active stops");
  const db = serviceClient();
  // A known start: a campus and a two-stop route.
  await db.from("schools").update({ campus_location: "SRID=4326;POINT(11.515 3.915)", campus_name: "Test campus" }).eq("id", SEED.schoolId);
  await db.from("routes").delete().eq("school_id", SEED.schoolId);
  const route = await db.from("routes").insert({ school_id: SEED.schoolId }).select("id").single();
  await db.from("route_stops").insert(stopIds.slice(0, 2).map((id, i) => ({ route_id: route.data!.id, stop_id: id, school_id: SEED.schoolId, position: i })));

  await signInBrowser(context, admin);
  await page.goto("/stops");
  await page.getByRole("link", { name: "Bus route" }).click();
  await expect(page).toHaveURL(/\/stops\/route$/);
  await expect(page.getByRole("heading", { name: "Bus route", level: 1 })).toBeVisible();

  const order = page.getByRole("list", { name: "Stops in order" }).getByRole("listitem");
  await expect(order).toHaveCount(2);
  const second = (await order.nth(1).innerText()).split("\n").find((line) => line && !/^\d+$/.test(line))!;
  await page.getByRole("button", { name: `Move ${second} earlier` }).click();
  await expect(order.first()).toContainText(second);

  // Before the road is drawn, the directions are estimates and end at the campus.
  const steps = page.getByRole("list", { name: "Directions" }).getByRole("listitem");
  await expect(steps).toHaveCount(2);
  await expect(steps.last()).toContainText("to Test campus");
  await expect(page.getByText(/Estimated from straight lines/)).toBeVisible();

  await page.getByRole("button", { name: "Save the order" }).click();
  await expect(page.getByText(/Order saved/)).toBeVisible();
  const saved = await db.from("route_stops").select("stop_id, position").eq("route_id", route.data!.id).order("position");
  expect(saved.data?.[0].stop_id).toBe(stopIds[1]);
});

test("a staff member cannot open the route editor", async ({ page, context }) => {
  await signInBrowser(context, staff);
  await page.goto("/stops/route");
  await expect(page).toHaveURL(/\/no-access$/);
});
