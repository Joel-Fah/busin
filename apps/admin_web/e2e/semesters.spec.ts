import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");
// A year far from the seed data, so runs cannot collide with real semesters.
const YEAR = 2040 + (parseInt(tag, 16) % 50);

let admin: TestUser;
let staff: TestUser;
let student: TestUser;
let existingId: string;

test.beforeAll(async () => {
  admin = await createUser(`sem-admin-${tag}`, "admin");
  staff = await createUser(`sem-staff-${tag}`, "staff");
  student = await createUser(`sem-student-${tag}`, "student");

  const { data, error } = await serviceClient()
    .from("semesters")
    .insert({
      school_id: SEED.schoolId,
      name: "spring",
      year: YEAR,
      start_date: `${YEAR}-02-01`,
      end_date: `${YEAR}-06-15`,
    })
    .select("id")
    .single();
  if (error || !data) throw new Error(`could not create a semester: ${error?.message}`);
  existingId = data.id;
});

test.afterAll(async () => {
  await serviceClient().from("semesters").delete().eq("school_id", SEED.schoolId).gte("year", 2040);
  for (const user of [admin, staff, student]) {
    if (user) await deleteUser(user);
  }
});

async function semester(name: "fall" | "spring" | "summer", year: number) {
  const { data } = await serviceClient()
    .from("semesters")
    .select("id, name, year, start_date, end_date")
    .eq("school_id", SEED.schoolId)
    .eq("name", name)
    .eq("year", year)
    .maybeSingle();
  return data;
}

test.describe("administrator managing semesters", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("lists semesters with their dates and phase", async ({ page }) => {
    await page.goto("/semesters");
    await expect(page.getByRole("heading", { name: "Semesters", level: 1 })).toBeVisible();
    const row = page.getByRole("row").filter({ hasText: `Spring ${YEAR}` });
    await expect(row).toContainText(`${YEAR}-02-01 - ${YEAR}-06-15`);
    await expect(row).toContainText("Upcoming");
  });

  test("adds a semester", async ({ page }) => {
    await page.goto("/semesters/new");
    await page.getByLabel("Semester").selectOption("fall");
    await page.getByLabel("Year").fill(String(YEAR));
    await page.getByLabel("First day").fill(`${YEAR}-09-01`);
    await page.getByLabel("Last day").fill(`${YEAR}-12-20`);
    await page.getByRole("button", { name: "Add semester" }).click();

    await expect(page.getByRole("status")).toContainText("Semester added.");
    const row = await semester("fall", YEAR);
    expect(row?.start_date).toBe(`${YEAR}-09-01`);
    expect(row?.end_date).toBe(`${YEAR}-12-20`);
  });

  test("edits the dates of a semester", async ({ page }) => {
    await page.goto(`/semesters/${existingId}`);
    await page.getByLabel("Last day").fill(`${YEAR}-06-30`);
    await page.getByRole("button", { name: "Save semester" }).click();

    await expect(page.getByRole("status")).toContainText("Semester saved.");
    expect((await semester("spring", YEAR))?.end_date).toBe(`${YEAR}-06-30`);
  });

  test("refuses a last day that is not after the first day", async ({ page }) => {
    await page.goto("/semesters/new");
    await page.getByLabel("Semester").selectOption("summer");
    await page.getByLabel("Year").fill(String(YEAR));
    await page.getByLabel("First day").fill(`${YEAR}-07-10`);
    await page.getByLabel("Last day").fill(`${YEAR}-07-01`);
    await page.getByRole("button", { name: "Add semester" }).click();

    await expect(page.getByRole("alert").filter({ hasText: "The last day must be after the first day." })).toBeVisible();
    expect(await semester("summer", YEAR)).toBeNull();
  });

  test("refuses a semester that already exists", async ({ page }) => {
    await page.goto("/semesters/new");
    await page.getByLabel("Semester").selectOption("spring");
    await page.getByLabel("Year").fill(String(YEAR));
    await page.getByLabel("First day").fill(`${YEAR}-02-01`);
    await page.getByLabel("Last day").fill(`${YEAR}-05-01`);
    await page.getByRole("button", { name: "Add semester" }).click();

    await expect(page.getByRole("alert").filter({ hasText: "This semester already exists for that year." })).toBeVisible();
  });

  test("the browser blocks a missing date", async ({ page }) => {
    await page.goto("/semesters/new");
    await page.getByLabel("Year").fill(String(YEAR));
    await page.getByRole("button", { name: "Add semester" }).click();
    await expect(page).toHaveURL(/\/semesters\/new$/);
  });

  test("an unknown or malformed id shows the not-found page", async ({ page }) => {
    await page.goto("/semesters/not-a-uuid");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
    await page.goto("/semesters/a1000000-0000-4000-8000-0000000000ff");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  });

  test("the pages are available in French", async ({ page }) => {
    await page.goto("/semesters");
    await page.getByRole("button", { name: "Français" }).click();
    await expect(page.getByRole("heading", { name: "Semestres", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "Ajouter un semestre" })).toBeVisible();
    await page.getByRole("button", { name: "English" }).click();
  });
});

for (const [label, who] of [
  ["a student", () => student],
  ["a staff member", () => staff],
] as const) {
  test(`${label} cannot open the semesters pages`, async ({ page, context }) => {
    await signInBrowser(context, who());
    for (const path of ["/semesters", "/semesters/new", `/semesters/${existingId}`]) {
      await page.goto(path);
      await expect(page).toHaveURL(/\/no-access$/);
    }
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/semesters");
  await expect(page).toHaveURL(/\/login$/);
});
