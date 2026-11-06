import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createSubscription, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");

let admin: TestUser;
let student: TestUser;
let firstId: string;
let secondId = "";

test.beforeAll(async () => {
  admin = await createUser(`hist-admin-${tag}`, "admin");
  student = await createUser(`hist-student-${tag}`, "student");
  firstId = await createSubscription(student.id);
});

test.afterAll(async () => {
  const db = serviceClient();
  await db.from("audit_log").delete().in("target_id", [firstId, secondId].filter(Boolean));
  for (const user of [admin, student]) {
    if (user) await deleteUser(user);
  }
});

test("every operation on a student's requests of the semester is kept, and a revoked subscription can be given back", async ({ context, page }) => {
  await signInBrowser(context, admin);
  await page.goto(`/subscriptions/${firstId}`);

  // Approve, then revoke with a reason.
  await page.getByRole("button", { name: "Approve", exact: true }).click();
  await expect(page.getByText("Subscription approved.")).toBeVisible();
  await page.getByText("Revoke this subscription").click();
  await page.getByLabel("Reason for revoking").fill("Payment reversed");
  await page.getByRole("button", { name: "Confirm revocation" }).click();
  await expect(page.getByText("Subscription revoked.")).toBeVisible();

  // The student asks again: a second request in the same semester.
  secondId = await createSubscription(student.id);

  // The first one cannot be given back while the newer request is live.
  await page.goto(`/subscriptions/${firstId}`);
  await page.getByText("Give this subscription back").click();
  await page.getByRole("button", { name: "Reinstate subscription" }).click();
  await expect(page.getByText("The student already has a live subscription for this semester. Deal with that one first.")).toBeVisible();

  // Decline the newer one with a reason, then give the first back with a note.
  await page.goto(`/subscriptions/${secondId}`);
  await page.getByText("Reject with a reason").click();
  await page.getByLabel("Reason for rejection").fill("Receipt unreadable");
  await page.getByRole("button", { name: /Confirm|Reject/ }).last().click();
  await expect(page.getByText("Subscription rejected.")).toBeVisible();

  await page.goto(`/subscriptions/${firstId}`);
  await page.getByText("Give this subscription back").click();
  await page.getByLabel("Note for the student (optional)").fill("Paid in cash");
  await page.getByRole("button", { name: "Reinstate subscription" }).click();
  await expect(page.getByText("Subscription reinstated.")).toBeVisible();

  // The history: two requests, the latest (the declined one) open, the first closed, with all its operations inside.
  const accordions = page.locator("details", { has: page.getByText(/^Request of/) });
  await expect(accordions).toHaveCount(2);
  await expect(accordions.nth(0)).toHaveAttribute("open", "");
  await expect(accordions.nth(1)).not.toHaveAttribute("open", "");

  await accordions.nth(1).getByText(/^Request of/).click();
  const operations = accordions.nth(1).locator("li");
  await expect(operations).toHaveCount(4);
  // The latest operation first.
  await expect(operations.nth(0)).toContainText("Reinstated");
  await expect(operations.nth(0)).toContainText("Paid in cash");
  await expect(operations.nth(1)).toContainText("Revoked");
  await expect(operations.nth(1)).toContainText("Payment reversed");
  await expect(operations.nth(2)).toContainText("Approved");
  await expect(operations.nth(3)).toContainText("Request sent");

  await expect(accordions.nth(0).locator("li").nth(0)).toContainText("Declined");
  await expect(accordions.nth(0).locator("li").nth(0)).toContainText("Receipt unreadable");
});

test("an accordion eases its height instead of jumping", async ({ context, page }) => {
  // The suite runs with reduced motion on; this check needs the real durations.
  await page.emulateMedia({ reducedMotion: "no-preference" });
  await signInBrowser(context, admin);
  await page.goto(`/subscriptions/${firstId}`);
  const closed = page.locator("details.accordion:not([open])").first();
  await expect(closed).toBeVisible();

  // Sample the height on every frame after the click: it grows over several frames, it does not jump.
  const samples = await closed.evaluate(async (el) => {
    const seen: number[] = [el.getBoundingClientRect().height];
    (el.querySelector("summary") as HTMLElement).click();
    for (let i = 0; i < 30; i++) {
      await new Promise((r) => requestAnimationFrame(() => r(null)));
      seen.push(el.getBoundingClientRect().height);
    }
    return seen;
  });
  const end = samples[samples.length - 1];
  const between = samples.filter((h) => h > samples[0] + 2 && h < end - 2);
  expect(between.length, `heights per frame: ${samples.join(", ")}`).toBeGreaterThan(3);
});
