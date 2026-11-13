import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// The student web app without a connection (ADR 0021). Needs a production build, the only one that registers the
// service worker: E2E_PROD=1 E2E_PORT=3100 npx playwright test e2e/student-web-offline.spec.ts
const tag = randomBytes(3).toString("hex");
let student: TestUser;

test.use({ viewport: { width: 390, height: 844 } });
test.skip(process.env.E2E_PROD !== "1", "the service worker is registered only in a production build");

test.beforeAll(async () => {
  const db = serviceClient();
  student = await createUser(`web-off-${tag}`, "student");
  await db.from("profiles").update({ matricule: `OFF${tag}`, phone: "+237600000041", full_name: "Amara Ngono" }).eq("id", student.id);
  await db.from("subscriptions").insert({ school_id: SEED.schoolId, student_id: student.id, semester_id: SEED.semesterId, stop_id: SEED.stopId, status: "approved" });
});

test.afterAll(async () => {
  if (student) await deleteUser(student);
});

test("opened once online, the pass and the code still show without a connection", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/subscription");
  // Wait until the service worker controls the page, then open the pages so it keeps them.
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
    if (!navigator.serviceWorker.controller) await new Promise((resolve) => navigator.serviceWorker.addEventListener("controllerchange", resolve, { once: true }));
  });
  await page.goto("/app/subscription");
  await expect(page.getByTestId("status-card")).toContainText("You are subscribed");
  await page.goto("/app/code");
  await expect(page.getByTestId("boarding-qr")).toHaveAttribute("data-code", /^busin2\./);

  await context.setOffline(true);
  await page.reload();
  await expect(page.getByTestId("offline-banner")).toBeVisible();
  await expect(page.getByTestId("boarding-qr")).toHaveAttribute("data-code", /^busin2\./);

  await page.goto("/app/subscription");
  await expect(page.getByTestId("status-card")).toContainText("You are subscribed");

  // A page never opened online has no saved copy: the offline page says so.
  await page.goto("/app/history");
  await expect(page.getByRole("heading", { name: "No connection" })).toBeVisible();
  await context.setOffline(false);
});

test("when a new version takes over while the app is open, a note offers a reload", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/profile");
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
    if (!navigator.serviceWorker.controller) await new Promise((resolve) => navigator.serviceWorker.addEventListener("controllerchange", resolve, { once: true }));
  });
  await page.reload();
  await expect(page.getByRole("heading", { name: "Your profile" })).toBeVisible();
  await page.waitForLoadState("networkidle"); // the page is listening once it has hydrated
  // A new worker script, as after a release: it installs and takes over this page.
  await page.evaluate(() => navigator.serviceWorker.register("/app/sw.js?release=next", { scope: "/app/" }));
  const notice = page.getByTestId("update-notice");
  await expect(notice).toContainText("BusIn was updated.");
  await notice.getByRole("button", { name: "Reload" }).click();
  await expect(page.getByRole("heading", { name: "Your profile" })).toBeVisible();
  await expect(page.getByTestId("update-notice")).toHaveCount(0);
});
