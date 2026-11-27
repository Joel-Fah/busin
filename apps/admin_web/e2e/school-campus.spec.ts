import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { parsePoint } from "@/lib/geo";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");

let admin: TestUser;
// The school's campus, put back after the test.
let original: { campus: unknown; campusName: string | null };

test.beforeAll(async () => {
  admin = await createUser(`campus-admin-${tag}`, "admin");
  const { data } = await serviceClient().from("schools").select("campus_location, campus_name").eq("id", SEED.schoolId).single();
  original = { campus: data?.campus_location ?? null, campusName: data?.campus_name ?? null };
});

test.afterAll(async () => {
  await serviceClient().from("schools").update({ campus_location: original.campus as string | null, campus_name: original.campusName }).eq("id", SEED.schoolId);
  if (admin) await deleteUser(admin);
});

test("an administrator sets the campus from the school profile, then changes it", async ({ page, context }) => {
  const db = serviceClient();
  await db.from("schools").update({ campus_location: null, campus_name: null }).eq("id", SEED.schoolId);

  await signInBrowser(context, admin);
  await page.goto("/school");
  await expect(page.getByRole("heading", { level: 1, name: "School profile" })).toBeVisible();

  // Empty state: what the campus is for.
  await expect(page.getByText("No campus set yet")).toBeVisible();
  await expect(page.getByText(/"arrived on campus" alert/)).toBeVisible();
  await page.getByRole("button", { name: "Set the campus" }).click();

  // The picker map is shown; the coordinates can also be typed.
  await expect(page.getByRole("region", { name: /Map to place the campus/ }).or(page.getByText(/You can still type the coordinates/))).toBeVisible();
  await page.getByLabel("Campus name").fill(`Campus ${tag}`);
  await page.getByLabel("Latitude").fill("3,915");
  await page.getByLabel("Longitude").fill("11.515");
  await page.getByRole("button", { name: "Save the campus" }).click();
  await expect(page.getByRole("status").filter({ hasText: "Campus saved." })).toBeVisible();

  // Back to the read view, with the saved point.
  await expect(page.getByRole("button", { name: "Change the campus" })).toBeVisible();
  await expect(page.getByText(`Campus ${tag}`, { exact: true })).toBeVisible();
  await expect(page.getByText("3.91500, 11.51500")).toBeVisible();
  const saved = await db.from("schools").select("campus_location, campus_name").eq("id", SEED.schoolId).single();
  expect(saved.data?.campus_name).toBe(`Campus ${tag}`);
  expect(parsePoint(saved.data?.campus_location)).toEqual({ lat: 3.915, lng: 11.515 });

  // A name is required.
  await page.getByRole("button", { name: "Change the campus" }).click();
  await expect(page.getByLabel("Latitude")).toHaveValue("3.915000");
  await page.getByLabel("Campus name").fill("   ");
  await page.getByRole("button", { name: "Save the campus" }).click();
  await expect(page.getByRole("alert").filter({ hasText: "Give the campus a name." })).toBeVisible();

  // Changing it keeps the route editor in step.
  await page.getByLabel("Campus name").fill(`North campus ${tag}`);
  await page.getByLabel("Longitude").fill("11.52");
  await page.getByRole("button", { name: "Save the campus" }).click();
  await expect(page.getByText(`North campus ${tag}`, { exact: true })).toBeVisible();
  await expect(page.getByText("3.91500, 11.52000")).toBeVisible();

  await page.getByRole("link", { name: "Open the bus route" }).click();
  await expect(page).toHaveURL(/\/stops\/route$/);
  await expect(page.getByRole("heading", { level: 1, name: "Bus route" })).toBeVisible();
  await expect(page.getByRole("complementary", { name: "The route" }).getByLabel("Name")).toHaveValue(`North campus ${tag}`);
});
