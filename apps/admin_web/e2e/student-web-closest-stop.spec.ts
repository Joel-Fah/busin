import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, serviceClient, signInBrowser, userClient, type TestUser } from "./support";

// When subscribing, each stop says how far it is from the student's area, and the nearest is suggested, never chosen.
const tag = randomBytes(3).toString("hex");
let withArea: TestUser;
let withoutArea: TestUser;

test.use({ viewport: { width: 390, height: 844 } });
test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  withArea = await createUser(`web-near-${tag}`, "student");
  withoutArea = await createUser(`web-noarea-${tag}`, "student");
  for (const [user, n] of [
    [withArea, 61],
    [withoutArea, 62],
  ] as const) {
    await serviceClient().from("profiles").update({ matricule: `NR${n}${tag}`, phone: `+2376000000${n}`, full_name: "Amara Ngono" }).eq("id", user.id);
  }
  // Near the seeded stop Shell Nsimeyong.
  const { error } = await (await userClient(withArea)).rpc("set_my_area", { p_lat: 3.838, p_lng: 11.494, p_label: "Nsimeyong", p_source: "search" });
  if (error) throw new Error(error.message);
});

test.afterAll(async () => {
  for (const user of [withArea, withoutArea]) if (user) await deleteUser(user);
});

test("the nearest stop is suggested with its distance, and nothing is chosen", async ({ page, context }) => {
  await signInBrowser(context, withArea);
  await page.goto("/app/subscription");
  await page.getByRole("button", { name: /Your stop/ }).click();
  const dialog = page.getByRole("dialog");
  const suggested = dialog.getByRole("list", { name: "Suggested" });
  await expect(suggested).toContainText("Shell Nsimeyong");
  await expect(suggested).toContainText("Closest to your area");
  await expect(dialog.getByText(/km from your area/).first()).toBeVisible();
  await dialog.getByRole("button", { name: "Close", exact: true }).click();
  await expect(page.getByRole("button", { name: /Your stop/ })).toContainText("Choose where you board");
});

test("without an area the list is as before, with a way to add one", async ({ page, context }) => {
  await signInBrowser(context, withoutArea);
  await page.goto("/app/subscription");
  await page.getByRole("button", { name: /Your stop/ }).click();
  const dialog = page.getByRole("dialog");
  await expect(dialog.getByText("Add your area to see which stop is closest")).toBeVisible();
  await expect(dialog.getByText("Suggested")).toHaveCount(0);
  await expect(dialog.getByText(/km from your area/)).toHaveCount(0);
});
