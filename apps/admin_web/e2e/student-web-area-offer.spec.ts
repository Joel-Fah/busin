import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, userClient, type TestUser } from "./support";

// My area is offered once to a student who never added it (ADR 0023), when the notification offer is not showing.
const tag = randomBytes(3).toString("hex");
let student: TestUser;

test.use({ viewport: { width: 390, height: 844 } });
test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  const db = serviceClient();
  student = await createUser(`web-area-${tag}`, "student");
  await db.from("profiles").update({ matricule: `AR${tag}`, phone: "+237600000041", full_name: "Amara Ngono" }).eq("id", student.id);
  await db.from("subscriptions").insert({ school_id: SEED.schoolId, student_id: student.id, semester_id: SEED.semesterId, stop_id: SEED.stopId, status: "approved" });
});

test.afterAll(async () => {
  if (student) await deleteUser(student);
});

test.beforeEach(async ({ context }) => {
  await signInBrowser(context, student);
  // The notification offer already answered, so this one may show.
  await context.addInitScript(() => window.localStorage.setItem("busin-push-offer", "later"));
});

test("the card opens My area", async ({ page }) => {
  await page.goto("/app/subscription");
  const card = page.getByTestId("area-offer");
  await expect(card).toBeVisible();
  await card.getByRole("link", { name: "Add my area" }).click();
  await expect(page).toHaveURL(/\/app\/settings\/area$/);
  await expect(page.getByRole("heading", { name: "My area" })).toBeVisible();
});

test("answered once, it is not offered again", async ({ page, context }) => {
  await context.addInitScript(() => window.localStorage.removeItem("busin-area-offer"));
  await page.goto("/app/subscription");
  const card = page.getByTestId("area-offer");
  await expect(card).toBeVisible();
  await card.getByRole("button", { name: "Not now" }).click();
  await expect(card).toHaveCount(0);
  expect(await page.evaluate(() => window.localStorage.getItem("busin-area-offer"))).toBe("done");
});

test("a student who has an area is not asked", async ({ page, context }) => {
  await context.addInitScript(() => window.localStorage.removeItem("busin-area-offer"));
  // Set as the student would, at the seeded campus (an area far from every bus is refused).
  const client = await userClient(student);
  const { error } = await client.rpc("set_my_area", { p_lat: 3.95, p_lng: 11.52, p_label: "Bastos", p_source: "search" });
  if (error) throw new Error(error.message);
  await page.goto("/app/subscription");
  await page.waitForLoadState("networkidle");
  await expect(page.getByTestId("area-offer")).toHaveCount(0);
});
