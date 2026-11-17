import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteSchool, deleteUser, searchAndChoose, serviceClient, setPlatformAdmin, signInBrowser, signUpAs, type TestUser } from "./support";

// School onboarding from the platform console (ADR 0027, slice 4).
const tag = randomBytes(3).toString("hex");
const schoolName = `E2E Onboarding ${tag}`;
const domain = `onboard-${tag}.edu`;
const adminEmail = `registrar-${tag}@example.org`;
let owner: TestUser;
let schoolId: string | null = null;

test.beforeAll(async () => {
  owner = await createUser(`onboard-owner-${tag}`, "admin");
  setPlatformAdmin(owner.id, true);
});

test.afterAll(async () => {
  setPlatformAdmin(owner.id, false);
  // The school's own accounts (the invited administrator) go with it.
  if (schoolId) deleteSchool(schoolId);
  await deleteUser(owner);
});

test.use({ viewport: { width: 1280, height: 900 } });
test.describe.configure({ mode: "serial" });

test("a school is created with its domain and its first administrator invited", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform/schools");
  await page.getByRole("link", { name: "New school" }).click();
  await expect(page).toHaveURL(/\/platform\/schools\/new$/);

  await page.getByLabel("Name", { exact: true }).fill(schoolName);
  await page.getByLabel("Short name").fill("EOS");
  await page.getByLabel("City").fill("Lagos");
  await searchAndChoose(page, "Time zone", "Lagos", /^Africa\/Lagos/);
  const domains = page.getByLabel("Student email domains");
  await domains.fill(domain);
  await domains.press("Enter");
  await page.getByLabel("Their Google email").fill(adminEmail);
  await page.getByRole("button", { name: "Create the school" }).click();

  await expect(page).toHaveURL(/\/platform\/schools\/[0-9a-f-]{36}/);
  schoolId = page.url().match(/schools\/([0-9a-f-]{36})/)?.[1] ?? null;
  await expect(page.getByText("School created, and its administrator invited.")).toBeVisible();
  await expect(page.getByRole("heading", { name: schoolName, level: 1 })).toBeVisible();
  await expect(page.getByTestId("admin-invites")).toContainText(adminEmail);

  const { data } = await serviceClient().from("schools").select("timezone, city, short_name, school_domains(domain)").eq("id", schoolId!).single();
  expect(data).toMatchObject({ timezone: "Africa/Lagos", city: "Lagos", short_name: "EOS", school_domains: [{ domain }] });
});

test("the same name is refused, and the form keeps what was typed", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform/schools/new");
  await page.getByLabel("Name", { exact: true }).fill(schoolName.toUpperCase());
  await page.getByLabel("Short name").fill("DUP");
  await searchAndChoose(page, "Time zone", "Lagos", /^Africa\/Lagos/);
  await page.getByRole("button", { name: "Create the school" }).click();
  await expect(page.getByText("A school with this name already exists.")).toBeVisible();
  await expect(page.getByLabel("Short name")).toHaveValue("DUP");
  await expect(page.getByRole("combobox", { name: "Time zone" })).toHaveText("Africa/Lagos");
});

test("the invited administrator's first sign-in opens the new school's portal", async ({ browser }) => {
  const invited = await signUpAs(adminEmail);
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  await signInBrowser(context, invited);
  const page = await context.newPage();
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Overview", level: 1 })).toBeVisible();
  await expect(page.getByText(schoolName).first()).toBeVisible();
  await context.close();
});

test("a school is switched off after a confirmation, and back on", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto(`/platform/schools/${schoolId}`);
  await page.getByRole("button", { name: "Switch off" }).click();
  const dialog = page.getByRole("dialog", { name: `Switch ${schoolName} off?` });
  await expect(dialog).toContainText("People already in keep their access.");
  await dialog.getByRole("button", { name: "Switch off" }).click();
  await expect(page.getByText("School switched off.")).toBeVisible();
  await expect(page.getByTestId("sticky-header")).toContainText("Switched off");
  await expect(page.getByRole("heading", { name: "Reach out" })).toHaveCount(0);

  await page.getByRole("button", { name: "Switch on" }).click();
  await page.getByRole("dialog", { name: `Switch ${schoolName} back on?` }).getByRole("button", { name: "Switch on" }).click();
  await expect(page.getByText("School switched back on.")).toBeVisible();
});

test("on a phone, the country and time zone lists open on screen, above the navigation, and pick by search and keys", async ({ browser }) => {
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, reducedMotion: "reduce" });
  await signInBrowser(context, owner);
  const page = await context.newPage();
  await page.goto("/platform/schools/new");
  const open = page.locator("[popover]:popover-open");

  // The panel is wholly on screen, and nothing (the floating navigation, the header) covers its middle.
  const onTop = async () => {
    await expect(open).toBeVisible();
    const box = (await open.boundingBox())!;
    expect(box.x).toBeGreaterThanOrEqual(0);
    expect(box.y).toBeGreaterThanOrEqual(0);
    expect(box.x + box.width).toBeLessThanOrEqual(390);
    expect(box.y + box.height).toBeLessThanOrEqual(844);
    const covered = await open.evaluate((el) => {
      const r = el.getBoundingClientRect();
      const hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
      return !hit || !el.contains(hit);
    });
    expect(covered).toBe(false);
  };

  const country = page.getByRole("combobox", { name: "Country" });
  await country.click();
  await onTop();
  await page.getByRole("searchbox").fill("nigeria");
  await page.keyboard.press("Enter");
  await expect(country).toHaveText("Nigeria");
  await expect(page.locator('input[type="hidden"][name="country"]')).toHaveValue("Nigeria");

  // The time zone is picked from the list too, never a free text box with the browser's own suggestions.
  await expect(page.locator("datalist")).toHaveCount(0);
  const zone = page.getByRole("combobox", { name: "Time zone" });
  await expect(zone).toHaveText("Choose a time zone");
  await zone.scrollIntoViewIfNeeded();
  await zone.click();
  await onTop();
  // The long list scrolls inside the panel.
  expect(await page.getByRole("listbox", { name: "Time zone" }).evaluate((el) => el.scrollHeight > el.clientHeight)).toBe(true);
  // Searched in the middle of a name, with spaces for underscores; picked with the keys.
  await page.getByRole("searchbox").fill("new york");
  await expect(page.getByRole("option")).toHaveCount(1);
  // The shorter panel stays on its side, touching the field, not floating where the full list ended.
  await expect
    .poll(async () => {
      const [p, f] = [(await open.boundingBox())!, (await zone.boundingBox())!];
      return (await open.getAttribute("data-side")) === "top" ? f.y - (p.y + p.height) : p.y - (f.y + f.height);
    })
    .toBeLessThanOrEqual(12);
  await page.keyboard.press("Enter");
  await expect(open).toHaveCount(0);
  await expect(zone).toHaveText("America/New York");
  await expect(zone).toBeFocused();
  await expect(page.locator('input[type="hidden"][name="timezone"]')).toHaveValue("America/New_York");

  // Escape and a tap outside both close it, keeping the choice.
  await zone.press("ArrowDown");
  await expect(page.getByRole("option", { name: /America\/New York/ })).toHaveAttribute("aria-selected", "true");
  await page.keyboard.press("Escape");
  await expect(open).toHaveCount(0);
  await zone.click();
  await expect(open).toBeVisible();
  await page.mouse.click(5, 5);
  await expect(open).toHaveCount(0);
  await expect(page.locator('input[type="hidden"][name="timezone"]')).toHaveValue("America/New_York");

  // No sideways scroll on a phone.
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(390);
  await context.close();
});
