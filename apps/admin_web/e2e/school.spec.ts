import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import type { Database } from "../lib/database.types";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

const tag = randomBytes(3).toString("hex");
let admin: TestUser;
let student: TestUser;
type Saved = Database["public"]["Tables"]["schools"]["Update"];
let before: Saved;

const COLUMNS = "open_signup_domains, name, short_name, website, contact_email, phone, address, city, country, about, logo_path, accepts_open_signup, public_listing, terms_version, terms_accepted_at, terms_accepted_by";

test.beforeAll(async () => {
  admin = await createUser(`school-admin-${tag}`, "admin");
  student = await createUser(`school-student-${tag}`, "student");
  const { data } = await serviceClient().from("schools").select(COLUMNS).eq("id", SEED.schoolId).single();
  before = data as Saved;
  // Start from a school that has not accepted the terms.
  await serviceClient().from("schools").update({ public_listing: false, terms_accepted_at: null, terms_version: null, terms_accepted_by: null }).eq("id", SEED.schoolId);
});

test.afterAll(async () => {
  const { data } = await serviceClient().from("schools").select("logo_path").eq("id", SEED.schoolId).single();
  if (data?.logo_path && data.logo_path !== before.logo_path) await serviceClient().storage.from("school-logos").remove([data.logo_path]);
  await serviceClient().from("schools").update(before).eq("id", SEED.schoolId);
  for (const user of [admin, student]) if (user) await deleteUser(user);
});

test.describe("the school profile", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("is reached from the profile, saves details and refuses a bad website", async ({ page }) => {
    await page.goto("/profile");
    await page.getByRole("link", { name: /School profile/ }).click();
    await expect(page.getByRole("heading", { level: 1, name: "School profile" })).toBeVisible();
    await expect(page.getByRole("listitem").filter({ hasText: `@${SEED.domain}` }).first()).toBeVisible();

    await page.getByLabel("Website").fill("http://not-secure.example");
    await page.getByRole("button", { name: "Save the profile" }).click();
    await expect(page.getByText("Enter a website address that starts with https://")).toBeVisible();

    await page.getByLabel("Website").fill("https://www.ictuniversity.example");
    await page.getByLabel("City").fill(`Yaounde ${tag}`);
    await page.getByLabel("Contact email").fill("Transport@ICTU.example");
    await page.getByRole("button", { name: "Save the profile" }).click();
    await expect(page.getByRole("status")).toContainText("School profile saved.");
    const { data } = await serviceClient().from("schools").select("website, city, contact_email").eq("id", SEED.schoolId).single();
    expect(data).toEqual({ website: "https://www.ictuniversity.example", city: `Yaounde ${tag}`, contact_email: "transport@ictu.example" });
  });

  test("allowed domains are typed as tags: comma or space makes a tag, a click edits it, and they are saved", async ({ page }) => {
    await page.goto("/school");
    const open = page.getByRole("switch", { name: /Also accept students with other email addresses/ });
    if (await open.isChecked()) await open.uncheck();
    await expect(page.getByLabel("Allowed email domains")).toBeHidden();
    await open.check();

    const field = page.getByLabel("Allowed email domains");
    await field.pressSequentially("@Gmail.com,yahoo.fr ");
    const tags = page.locator("[data-tag]");
    await expect(tags).toHaveText(["gmail.com", "yahoo.fr"]);

    // Click a tag to edit it, change it, and press Enter.
    await page.getByRole("button", { name: "yahoo.fr", exact: true }).click();
    await expect(field).toHaveValue("yahoo.fr");
    await field.fill("hotmail.com");
    await field.press("Enter");
    await expect(tags).toHaveText(["gmail.com", "hotmail.com"]);

    await page.getByRole("button", { name: "Remove gmail.com" }).click();
    await expect(tags).toHaveText(["hotmail.com"]);
    await page.getByRole("button", { name: "Save the profile" }).click();
    await expect(page.getByRole("status")).toContainText("School profile saved.");
    const { data } = await serviceClient().from("schools").select("accepts_open_signup, open_signup_domains").eq("id", SEED.schoolId).single();
    expect(data).toEqual({ accepts_open_signup: true, open_signup_domains: ["hotmail.com"] });
  });

  test("the school is listed publicly only after accepting the terms", async ({ page }) => {
    await page.goto("/school");
    await expect(page.getByRole("switch", { name: /Show our school publicly/ })).toBeDisabled();
    await page.getByText("Read the terms").click();
    await expect(page.getByText("By accepting these terms you allow BusIn to show your school")).toBeVisible();
    await page.getByRole("button", { name: "Accept the terms" }).click();
    await expect(page.getByRole("status")).toContainText("Terms accepted.");

    await page.getByRole("switch", { name: /Show our school publicly/ }).check();
    await page.getByRole("button", { name: "Save the profile" }).click();
    await expect(page.getByRole("status")).toContainText("School profile saved.");
    const { data } = await serviceClient().from("schools").select("public_listing, terms_version").eq("id", SEED.schoolId).single();
    expect(data).toEqual({ public_listing: true, terms_version: "2026-11-11" });
  });

  test("an administrator turns off starting trips from the ops app, and back on", async ({ page }) => {
    const db = serviceClient();
    try {
      await page.goto("/school");
      const toggle = page.getByRole("switch", { name: /Let staff start a trip that was not scheduled/ });
      await expect(toggle).toBeChecked();
      await toggle.uncheck();
      await page.getByRole("button", { name: "Save", exact: true }).click();
      await expect(page.getByRole("status")).toContainText("Saved.");
      expect((await db.from("schools").select("allow_field_trips").eq("id", SEED.schoolId).single()).data?.allow_field_trips).toBe(false);

      await page.goto("/school");
      await page.getByRole("switch", { name: /Let staff start a trip that was not scheduled/ }).check();
      await page.getByRole("button", { name: "Save", exact: true }).click();
      await expect(page.getByRole("status")).toContainText("Saved.");
      expect((await db.from("schools").select("allow_field_trips").eq("id", SEED.schoolId).single()).data?.allow_field_trips).toBe(true);
    } finally {
      await db.from("schools").update({ allow_field_trips: true }).eq("id", SEED.schoolId);
    }
  });

  test("a logo is shrunk, stored in the school's folder and can be removed", async ({ page }) => {
    await page.goto("/school");
    // A 900 by 600 PNG made in the browser, as an admin would pick from their computer.
    const png = await page.evaluate(async () => {
      const canvas = Object.assign(document.createElement("canvas"), { width: 900, height: 600 });
      const context = canvas.getContext("2d")!;
      context.fillStyle = "#0c5d6d";
      context.fillRect(0, 0, 900, 600);
      const blob = await new Promise<Blob>((resolve) => canvas.toBlob((b) => resolve(b!), "image/png"));
      return Array.from(new Uint8Array(await blob.arrayBuffer()));
    });
    await page.locator("input[type=file]").setInputFiles({ name: "logo.png", mimeType: "image/png", buffer: Buffer.from(png) });
    await expect(page.getByText("Logo saved.")).toBeVisible();
    const { data } = await serviceClient().from("schools").select("logo_path").eq("id", SEED.schoolId).single();
    expect(data?.logo_path).toMatch(new RegExp(`^${SEED.schoolId}/logo-\\d+\\.webp$`));

    await page.getByRole("button", { name: "Remove", exact: true }).click();
    await expect(page.getByText("Logo removed.")).toBeVisible();
    const after = await serviceClient().from("schools").select("logo_path").eq("id", SEED.schoolId).single();
    expect(after.data?.logo_path).toBeNull();
  });
});

test("a student cannot open the school profile", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/school");
  await expect(page).not.toHaveURL(/\/school$/);
});
