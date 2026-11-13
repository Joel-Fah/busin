import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// The student web app at /app (ADR 0021): its door, its gates and its shell.
const tag = randomBytes(3).toString("hex");
let student: TestUser;
let staff: TestUser;
let admin: TestUser;

test.use({ viewport: { width: 390, height: 844 } });

test.beforeAll(async () => {
  student = await createUser(`web-student-${tag}`, "student");
  staff = await createUser(`web-staff-${tag}`, "staff");
  admin = await createUser(`web-admin-${tag}`, "admin");
  // The details the school needs, so the student is past setup.
  const { error } = await serviceClient().from("profiles").update({ matricule: `ICT${tag}`, phone: "+237600000001" }).eq("id", student.id);
  if (error) throw new Error(error.message);
});

test.afterAll(async () => {
  for (const user of [student, staff, admin]) if (user) await deleteUser(user);
});

test("the very first visit is welcomed once, and the welcome does not come back", async ({ page }) => {
  await page.goto("/app/sign-in");
  const welcome = page.getByRole("dialog", { name: "BusIn just hopped onto the web" });
  await expect(welcome).toBeVisible();
  await welcome.getByRole("button", { name: "Hop on" }).click();
  await expect(welcome).toBeHidden();
  await page.reload();
  await expect(page.getByRole("heading", { name: "Hop on. BusIn handles the rest." })).toBeVisible();
  await expect(page.getByRole("dialog")).toHaveCount(0);
});

test("a signed-out visitor to the app is sent to its own sign-in page", async ({ page, context }) => {
  await context.addInitScript(() => window.localStorage.setItem("busin-welcomed", "1"));
  await page.goto("/app/code");
  await expect(page).toHaveURL(/\/app\/sign-in$/);
  await expect(page.getByRole("heading", { name: "Hop on. BusIn handles the rest." })).toBeVisible();
  await expect(page.getByRole("button", { name: "Continue with Google" })).toBeVisible();
});

test("an error from Google comes back to the app's sign-in page in the student's words", async ({ page, context }) => {
  await context.addInitScript(() => window.localStorage.setItem("busin-welcomed", "1"));
  await page.goto("/app/sign-in?error=notAllowed");
  await expect(page.getByRole("alert").filter({ hasText: "not allowed" })).toHaveText("This Google account is not allowed here. Use your school account.");
});

test("a shared link to the app shows its own card, readable without signing in", async ({ page, request }) => {
  await page.goto("/app/sign-in");
  await expect(page.locator('meta[property="og:title"]')).toHaveAttribute("content", "BusIn, right in your browser");
  const image = await page.locator('meta[property="og:image"]').getAttribute("content");
  const response = await request.get(new URL(image!).pathname + new URL(image!).search);
  expect(response.status()).toBe(200);
  expect(response.headers()["content-type"]).toContain("image/png");
});

test("the app can be installed: a manifest scoped to /app and a service worker", async ({ request }) => {
  const manifest = await (await request.get("/app/manifest.webmanifest")).json();
  expect(manifest).toMatchObject({ start_url: "/app", scope: "/app/", display: "standalone" });
  expect(manifest.icons.map((icon: { purpose: string }) => icon.purpose)).toEqual(["any", "any", "maskable"]);
  for (const icon of manifest.icons) expect((await request.get(icon.src)).status()).toBe(200);
  // iOS reads apple-touch icons, not the manifest; some versions fetch the root addresses first.
  for (const path of ["/app-icons/apple-touch-180.png", "/app-icons/apple-touch-167.png", "/app-icons/apple-touch-152.png", "/apple-touch-icon.png", "/apple-touch-icon-precomposed.png"]) {
    const icon = await request.get(path);
    expect(icon.status(), path).toBe(200);
    expect(icon.headers()["content-type"], path).toContain("image/png");
  }
  const worker = await request.get("/app/sw.js");
  expect(worker.status()).toBe(200);
  expect(worker.headers()["cache-control"]).toContain("no-cache");
  expect((await request.get("/app/offline")).status()).toBe(200);
});

test.describe("a verified student", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, student);
  });

  test("opens on the subscription tab, with four tabs at the bottom", async ({ page }) => {
    await page.goto("/app");
    await expect(page).toHaveURL(/\/app\/subscription$/);
    const tabs = page.getByRole("navigation", { name: "BusIn" });
    await expect(tabs.getByRole("link")).toHaveCount(4);
    await expect(tabs.getByRole("link", { name: "Subscription" })).toHaveAttribute("aria-current", "page");
    await tabs.getByRole("link", { name: "Boarding code" }).click();
    await expect(page).toHaveURL(/\/app\/code$/);
    await expect(page.getByRole("heading", { name: "Boarding code", level: 1 })).toBeVisible();
  });

  test("is sent from the portal to the app", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveURL(/\/app\/subscription$/);
    await page.goto("/login");
    await expect(page).toHaveURL(/\/app\/subscription$/);
  });

  test("sees their profile, can switch to French, and signs out to the app's sign-in", async ({ page }) => {
    await page.goto("/app/profile");
    await expect(page.getByText(student.email)).toBeVisible();
    await page.getByRole("button", { name: "Français" }).click();
    await expect(page.getByRole("heading", { name: "Votre profil" })).toBeVisible();
    await page.getByRole("button", { name: "English" }).click();
    await expect(page.getByRole("heading", { name: "Your profile" })).toBeVisible();
    await page.getByRole("button", { name: "Sign out" }).click();
    await expect(page).toHaveURL(/\/app\/sign-in$/);
  });
});

test("a staff member is told the app is for students", async ({ page, context }) => {
  await signInBrowser(context, staff);
  await page.goto("/app");
  await expect(page).toHaveURL(/\/app\/blocked$/);
  await expect(page.getByRole("heading", { name: "This app is for students" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Open the admin portal" })).toHaveCount(0);
});

test("an administrator who opens the app is pointed to the portal", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/app/bus");
  await expect(page).toHaveURL(/\/app\/blocked$/);
  await expect(page.getByRole("link", { name: "Open the admin portal" })).toHaveAttribute("href", "/");
});
