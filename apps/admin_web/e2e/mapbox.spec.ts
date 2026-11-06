import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, signInBrowser, type TestUser } from "./support";

// These tests call Mapbox, which bills per map load, so they only run on purpose. Use a free port so
// Playwright starts its own server with the right provider and does not reuse one you have running:
//   E2E_PROD=1 E2E_PORT=3100 MAP_PROVIDER=mapbox npx playwright test e2e/mapbox.spec.ts
// Each run costs about two map loads.
test.skip(process.env.MAP_PROVIDER !== "mapbox", "Set MAP_PROVIDER=mapbox to run the Mapbox tests.");

const tag = randomBytes(3).toString("hex");
let admin: TestUser;

test.beforeAll(async () => {
  admin = await createUser(`mapbox-${tag}`, "admin");
});

test.afterAll(async () => {
  await deleteUser(admin);
});

test.use({ viewport: { width: 1280, height: 800 } });

test("one map is created for the tab and reused across the stops pages", async ({ page, context }) => {
  await signInBrowser(context, admin);
  const styleRequests: string[] = [];
  page.on("request", (request) => {
    if (/api\.mapbox\.com\/styles\/v1\//.test(request.url())) styleRequests.push(request.url());
  });

  await page.goto("/stops");
  await expect(page.locator(".mapboxgl-canvas")).toBeVisible({ timeout: 30_000 });

  // Soft navigation to a page without a map and back: the same map moves with the page.
  const nav = page.getByRole("navigation", { name: "Main navigation" });
  await nav.getByRole("link", { name: "Trips", exact: true }).click();
  await expect(page).toHaveURL(/\/trips$/);
  await nav.getByRole("link", { name: "Profile", exact: true }).click();
  await page.getByRole("link", { name: /^Stops/ }).click();
  await expect(page).toHaveURL(/\/stops$/);
  await expect(page.locator(".mapboxgl-canvas")).toBeVisible({ timeout: 30_000 });

  expect(styleRequests.length).toBe(1);
  const loads = await page.evaluate(() => JSON.parse(localStorage.getItem("busin-map-loads") ?? "[]") as number[]);
  expect(loads).toHaveLength(1);
});

test("falls back to the free map, without calling Mapbox, once the browser's budget is spent", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await context.addInitScript(() => {
    localStorage.setItem("busin-map-loads", JSON.stringify(Array.from({ length: 30 }, (_, i) => Date.now() - i * 1000)));
  });
  const mapboxStyleRequests: string[] = [];
  page.on("request", (request) => {
    if (/api\.mapbox\.com\/styles\/v1\//.test(request.url())) mapboxStyleRequests.push(request.url());
  });

  await page.goto("/stops");
  await expect(page.locator(".maplibregl-canvas")).toBeVisible({ timeout: 30_000 });
  await expect(page.locator(".mapboxgl-canvas")).toHaveCount(0);
  expect(mapboxStyleRequests).toHaveLength(0);
});
