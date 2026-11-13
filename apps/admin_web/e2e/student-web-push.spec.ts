import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// Push in the student web app (ADR 0021). The service worker runs only in a production build:
// E2E_PROD=1 E2E_PORT=3100 npx playwright test e2e/student-web-push.spec.ts
// A real FCM delivery needs the Firebase web config; here the browser's DevTools hand the worker a push message directly.
const tag = randomBytes(3).toString("hex");
let student: TestUser;

test.use({ viewport: { width: 390, height: 844 } });
test.skip(process.env.E2E_PROD !== "1", "the service worker is registered only in a production build");

test.beforeAll(async () => {
  const db = serviceClient();
  student = await createUser(`web-push-${tag}`, "student");
  await db.from("profiles").update({ matricule: `PU${tag}`, phone: "+237600000051", full_name: "Amara Ngono" }).eq("id", student.id);
  await db.from("subscriptions").insert({ school_id: SEED.schoolId, student_id: student.id, semester_id: SEED.semesterId, stop_id: SEED.stopId, status: "approved" });
});

test.afterAll(async () => {
  if (student) await deleteUser(student);
});

test("a push that arrives while a page is on screen is said there, not as a notification", async ({ page, context }) => {
  await context.grantPermissions(["notifications"]);
  await signInBrowser(context, student);
  const cdp = await context.newCDPSession(page);
  const registration = new Promise<string>((resolve) => {
    cdp.on("ServiceWorker.workerRegistrationUpdated", ({ registrations }) => {
      const ours = registrations.find((r: { scopeURL: string; isDeleted: boolean }) => r.scopeURL.endsWith("/app/") && !r.isDeleted);
      if (ours) resolve(ours.registrationId);
    });
  });
  await cdp.send("ServiceWorker.enable");
  await page.goto("/app/profile");
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
    if (!navigator.serviceWorker.controller) await new Promise((resolve) => navigator.serviceWorker.addEventListener("controllerchange", resolve, { once: true }));
  });
  const registrationId = await registration;
  const origin = new URL(page.url()).origin;
  await cdp.send("ServiceWorker.deliverPushMessage", {
    origin,
    registrationId,
    data: JSON.stringify({ notification: { title: "Your bus is almost here", body: "It is a few minutes from your stop." }, data: { kind: "bus_near_stop", ref_id: "trip" } }),
  });
  await expect(page.getByText("Your bus is a few minutes from your stop.")).toBeVisible();
});

test("every student is offered notifications once on the subscription tab, and Not now is remembered", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/subscription");
  const offer = page.getByTestId("push-opt-in");
  await expect(offer).toBeVisible();
  // The headless browser has no notifications at all, so the card explains instead of offering the switch; in a real
  // browser it shows "Turn on notifications". Either way "Not now" is there and remembered.
  await offer.getByRole("button", { name: "Not now" }).click();
  await expect(offer).toBeHidden();
  await page.reload();
  await expect(page.getByTestId("status-card")).toBeVisible();
  await expect(page.getByTestId("push-opt-in")).toHaveCount(0);
  // The settings page still has the full card.
  await page.goto("/app/settings/notifications");
  await expect(page.getByTestId("push-opt-in")).toBeVisible();
});
