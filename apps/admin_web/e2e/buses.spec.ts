import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex").toUpperCase();
const prefix = `E2E-${tag}`;

let admin: TestUser;
let staff: TestUser;
let student: TestUser;
let existingId: string;

test.beforeAll(async () => {
  admin = await createUser(`bus-admin-${tag}`, "admin");
  staff = await createUser(`bus-staff-${tag}`, "staff");
  student = await createUser(`bus-student-${tag}`, "student");

  const { data, error } = await serviceClient()
    .from("buses")
    .insert({ school_id: SEED.schoolId, plate: `${prefix} EXISTING`, capacity: 40 })
    .select("id")
    .single();
  if (error || !data) throw new Error(`could not create a bus: ${error?.message}`);
  existingId = data.id;
});

test.afterAll(async () => {
  await serviceClient().from("buses").delete().like("plate", `${prefix}%`);
  for (const user of [admin, staff, student]) {
    if (user) await deleteUser(user);
  }
});

async function busByPlate(plate: string) {
  const { data } = await serviceClient()
    .from("buses")
    .select("id, plate, capacity, in_service")
    .eq("plate", plate)
    .maybeSingle();
  return data;
}

test.describe("administrator managing buses", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("lists buses with seats and status", async ({ page }) => {
    await page.goto("/buses");
    await expect(page.getByRole("heading", { name: "Buses", level: 1 })).toBeVisible();
    const row = page.getByRole("row").filter({ hasText: `${prefix} EXISTING` });
    await expect(row).toContainText("40");
    await expect(row).toContainText("In service");
  });

  test("adds a bus and stores the plate in capitals", async ({ page }) => {
    await page.goto("/buses/new");
    await page.getByLabel("Plate").fill(`  ${prefix.toLowerCase()}   new `);
    await page.getByLabel("Seats").fill("55");
    await page.getByRole("button", { name: "Add bus" }).click();

    await expect(page.getByRole("status")).toContainText("Bus added.");
    const bus = await busByPlate(`${prefix} NEW`);
    expect(bus?.capacity).toBe(55);
    expect(bus?.in_service).toBe(true);
  });

  test("edits a bus and takes it out of service", async ({ page }) => {
    await page.goto(`/buses/${existingId}`);
    await page.getByLabel("Seats").fill("45");
    await page.getByLabel("In service").uncheck();
    await page.getByRole("button", { name: "Save bus" }).click();

    await expect(page.getByRole("status")).toContainText("Bus saved.");
    const bus = await busByPlate(`${prefix} EXISTING`);
    expect(bus?.capacity).toBe(45);
    expect(bus?.in_service).toBe(false);

    await page.goto("/buses");
    await expect(page.getByRole("row").filter({ hasText: `${prefix} EXISTING` })).toContainText("Out of service");
  });

  test("refuses a plate that is already used", async ({ page }) => {
    await page.goto("/buses/new");
    await page.getByLabel("Plate").fill(`${prefix} EXISTING`);
    await page.getByLabel("Seats").fill("30");
    await page.getByRole("button", { name: "Add bus" }).click();

    await expect(page.getByRole("alert").filter({ hasText: "Another bus already has this plate." })).toBeVisible();
  });

  test("the browser blocks zero seats", async ({ page }) => {
    await page.goto("/buses/new");
    await page.getByLabel("Plate").fill(`${prefix} ZERO`);
    await page.getByLabel("Seats").fill("0");
    await page.getByRole("button", { name: "Add bus" }).click();

    await expect(page).toHaveURL(/\/buses\/new$/);
    expect(await busByPlate(`${prefix} ZERO`)).toBeNull();
  });

  test("an unknown or malformed id shows the not-found page", async ({ page }) => {
    await page.goto("/buses/not-a-uuid");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
    await page.goto("/buses/a1000000-0000-4000-8000-0000000000ff");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  });

  test("the pages are available in French", async ({ page }) => {
    await page.goto("/buses");
    await page.getByRole("button", { name: "Français" }).click();
    await expect(page.getByRole("heading", { name: "Bus", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "Ajouter un bus" })).toBeVisible();
    await page.getByRole("button", { name: "English" }).click();
  });
});

for (const [label, who] of [
  ["a student", () => student],
  ["a staff member", () => staff],
] as const) {
  test(`${label} cannot open the buses pages`, async ({ page, context }) => {
    await signInBrowser(context, who());
    for (const path of ["/buses", "/buses/new", `/buses/${existingId}`]) {
      await page.goto(path);
      await expect(page).toHaveURL(/\/no-access$/);
    }
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/buses");
  await expect(page).toHaveURL(/\/login$/);
});
