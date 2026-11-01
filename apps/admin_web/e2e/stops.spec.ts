import { randomBytes } from "node:crypto";

import { expect, test, type Page } from "@playwright/test";

import { parsePoint } from "../lib/geo";
import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");
const prefix = `E2E stop-${tag}`;

let admin: TestUser;
let staff: TestUser;
let student: TestUser;
let existingId: string;

// A blank base map, so the tests need no outside map server and no network.
const BLANK_STYLE = {
  version: 8,
  sources: {},
  layers: [{ id: "background", type: "background", paint: { "background-color": "#e8f1f2" } }],
};

test.beforeAll(async () => {
  admin = await createUser(`stop-admin-${tag}`, "admin");
  staff = await createUser(`stop-staff-${tag}`, "staff");
  student = await createUser(`stop-student-${tag}`, "student");

  const { data, error } = await serviceClient()
    .from("stops")
    .insert({ school_id: SEED.schoolId, name: `${prefix} existing`, location: "SRID=4326;POINT(11.5021000 3.8480000)" })
    .select("id")
    .single();
  if (error || !data) throw new Error(`could not create a stop: ${error?.message}`);
  existingId = data.id;
});

test.afterAll(async () => {
  await serviceClient().from("stops").delete().like("name", `${prefix}%`);
  for (const user of [admin, staff, student]) {
    if (user) await deleteUser(user);
  }
});

async function stopByName(name: string) {
  const { data } = await serviceClient().from("stops").select("id, name, active, location").eq("name", name).maybeSingle();
  return data;
}

async function useBlankMap(page: Page) {
  await page.route("https://tiles.openfreemap.org/**", (route) => route.fulfill({ json: BLANK_STYLE }));
}

test.describe("administrator managing stops", () => {
  test.beforeEach(async ({ page, context }) => {
    await useBlankMap(page);
    await signInBrowser(context, admin);
  });

  test("lists stops with their position and shows them on the map", async ({ page }) => {
    await page.goto("/stops");
    await expect(page.getByRole("heading", { name: "Stops", level: 1 })).toBeVisible();

    const row = page.getByRole("row").filter({ hasText: `${prefix} existing` });
    await expect(row).toContainText("3.84800, 11.50210");
    await expect(row).toContainText("Active");

    // The marker is a link named after the stop.
    await expect(page.getByRole("link", { name: `${prefix} existing` }).first()).toBeVisible();
  });

  test("adds a stop by typing the coordinates", async ({ page }) => {
    await page.goto("/stops/new");
    await page.getByLabel("Name").fill(`${prefix} typed`);
    await page.getByLabel("Latitude").fill("3.9012345");
    await page.getByLabel("Longitude").fill("11.4567891");
    await page.getByRole("button", { name: "Add stop" }).click();

    await expect(page.getByRole("status")).toContainText("Stop added.");
    const stop = await stopByName(`${prefix} typed`);
    expect(stop?.active).toBe(true);
    const point = parsePoint(stop?.location);
    expect(point?.lat).toBeCloseTo(3.9012345, 6);
    expect(point?.lng).toBeCloseTo(11.4567891, 6);
  });

  test("adds a stop by clicking the map", async ({ page }) => {
    await page.goto("/stops/new");
    const canvas = page.locator(".maplibregl-canvas");
    await expect(canvas).toBeVisible();

    await canvas.click();
    await expect(page.getByLabel("Latitude")).not.toHaveValue("");
    await expect(page.locator(".maplibregl-marker")).toBeVisible();

    const lat = Number(await page.getByLabel("Latitude").inputValue());
    const lng = Number(await page.getByLabel("Longitude").inputValue());
    expect(lat).toBeGreaterThan(-90);
    expect(lat).toBeLessThan(90);

    await page.getByLabel("Name").fill(`${prefix} clicked`);
    await page.getByRole("button", { name: "Add stop" }).click();
    await expect(page.getByRole("status")).toContainText("Stop added.");

    const point = parsePoint((await stopByName(`${prefix} clicked`))?.location);
    expect(point?.lat).toBeCloseTo(lat, 5);
    expect(point?.lng).toBeCloseTo(lng, 5);
  });

  test("typing coordinates moves the pin", async ({ page }) => {
    await page.goto("/stops/new");
    await expect(page.locator(".maplibregl-canvas")).toBeVisible();
    await expect(page.locator(".maplibregl-marker")).toHaveCount(0);

    await page.getByLabel("Latitude").fill("3.9");
    await page.getByLabel("Longitude").fill("11.5");
    await expect(page.locator(".maplibregl-marker")).toBeVisible();
  });

  test("edits a stop and makes it inactive", async ({ page }) => {
    await page.goto(`/stops/${existingId}`);
    await page.getByLabel("Name").fill(`${prefix} renamed`);
    await page.getByLabel("Active").uncheck();
    await page.getByRole("button", { name: "Save stop" }).click();

    await expect(page.getByRole("status")).toContainText("Stop saved.");
    const stop = await stopByName(`${prefix} renamed`);
    expect(stop?.id).toBe(existingId);
    expect(stop?.active).toBe(false);

    await page.goto("/stops");
    await expect(page.getByRole("row").filter({ hasText: `${prefix} renamed` })).toContainText("Inactive");
  });

  test("refuses a name that is already used", async ({ page }) => {
    await page.goto("/stops/new");
    await page.getByLabel("Name").fill(`${prefix} typed`);
    await page.getByLabel("Latitude").fill("3.8");
    await page.getByLabel("Longitude").fill("11.4");
    await page.getByRole("button", { name: "Add stop" }).click();

    await expect(page.getByRole("alert").filter({ hasText: "Another stop already has this name." })).toBeVisible();
  });

  test("the browser blocks an impossible latitude", async ({ page }) => {
    await page.goto("/stops/new");
    await page.getByLabel("Name").fill(`${prefix} invalid`);
    await page.getByLabel("Latitude").fill("99");
    await page.getByLabel("Longitude").fill("11.4");
    await page.getByRole("button", { name: "Add stop" }).click();

    await expect(page).toHaveURL(/\/stops\/new$/);
    expect(await stopByName(`${prefix} invalid`)).toBeNull();
  });

  test("an unknown or malformed id shows the not-found page", async ({ page }) => {
    await page.goto("/stops/not-a-uuid");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
    await page.goto("/stops/a1000000-0000-4000-8000-0000000000ff");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  });

  test("the pages are available in French", async ({ page }) => {
    await page.goto("/stops");
    await page.getByRole("button", { name: "Français" }).click();
    await expect(page.getByRole("heading", { name: "Arrêts", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "Ajouter un arrêt" })).toBeVisible();
    await page.getByRole("button", { name: "English" }).click();
  });
});

for (const [label, who] of [
  ["a student", () => student],
  ["a staff member", () => staff],
] as const) {
  test(`${label} cannot open the stops pages`, async ({ page, context }) => {
    await useBlankMap(page);
    await signInBrowser(context, who());
    for (const path of ["/stops", "/stops/new", `/stops/${existingId}`]) {
      await page.goto(path);
      await expect(page).toHaveURL(/\/no-access$/);
    }
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/stops");
  await expect(page).toHaveURL(/\/login$/);
});
