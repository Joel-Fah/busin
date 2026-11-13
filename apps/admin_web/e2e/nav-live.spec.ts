import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createSubscription, createUser, deleteUser, signInBrowser, type TestUser } from "./support";

// The navigation's badges follow what happens without a reload (Realtime on the school's subscriptions and accounts).
const tag = randomBytes(3).toString("hex");
let admin: TestUser;
let student: TestUser;

test.beforeAll(async () => {
  admin = await createUser(`nav-admin-${tag}`, "admin");
  student = await createUser(`nav-student-${tag}`, "student");
});

test.afterAll(async () => {
  for (const user of [admin, student]) if (user) await deleteUser(user);
});

test("a new subscription request raises the badge while the admin is on another page", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/buses");
  const link = page.locator('nav a[href="/subscriptions"]:visible').first();
  await expect(link).toBeVisible();
  // The exact number is in the link's description for screen readers (the badge itself stops at 9+).
  const waiting = page.locator("#nav-waiting-subscriptions-bar");
  const before = Number(((await waiting.textContent()) ?? "0").match(/\d+/)?.[0] ?? 0);
  await page.waitForTimeout(1500); // let the live channel join
  await createSubscription(student.id, SEED.stopId);
  await expect(waiting).toContainText(`${before + 1} waiting`, { timeout: 15_000 });
});
