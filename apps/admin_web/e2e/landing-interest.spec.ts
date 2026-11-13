import { expect, test } from "@playwright/test";

import { SEED, serviceClient } from "./support";

const rowsFor = async (email: string) => {
  const { data } = await serviceClient().from("interest_requests").select("kind, name, organisation, locale").eq("email", email);
  return data ?? [];
};

test.describe("the landing page's interest form", () => {
  const stamp = Date.now();

  // The wall shows only schools that accepted the terms and chose to be listed: list the seeded school for these tests.
  let listedBefore: { public_listing: boolean; terms_accepted_at: string | null; terms_version: string | null } | null = null;
  test.beforeAll(async () => {
    const { data } = await serviceClient().from("schools").select("public_listing, terms_accepted_at, terms_version").eq("id", SEED.schoolId).single();
    listedBefore = data;
    await serviceClient().from("schools").update({ terms_accepted_at: data?.terms_accepted_at ?? new Date().toISOString(), terms_version: data?.terms_version ?? "2026-11", public_listing: true }).eq("id", SEED.schoolId);
  });

  test.afterAll(async () => {
    if (listedBefore) await serviceClient().from("schools").update(listedBefore).eq("id", SEED.schoolId);
    await serviceClient().from("interest_requests").delete().like("email", `%${stamp}%`);
  });

  test("with no app link set, the student card offers one Get notified, and the request is stored once", async ({ page }) => {
    const email = `notify${stamp}@example.com`;
    await page.goto("/");
    // One button, whichever phone the visitor has.
    await expect(page.locator("section[aria-labelledby=download] [data-interest=notify]")).toHaveCount(1);
    await expect(page.locator("section[aria-labelledby=download] [data-interest=notify]")).toHaveText("Get notified");
    // The student web app has its own card, available now (ADR 0021).
    await expect(page.locator("section[aria-labelledby=download]").getByRole("link", { name: "Open BusIn" })).toHaveAttribute("href", "/app");

    await page.locator("section[aria-labelledby=download] [data-interest=notify]").click();
    const dialog = page.getByRole("dialog", { name: "Tell me when the app is out" });
    await dialog.getByRole("button", { name: "Send" }).click();
    await expect(dialog.getByText("Fill this in.")).toBeVisible();
    await dialog.getByLabel("Email").fill("not-an-email");
    await dialog.getByRole("button", { name: "Send" }).click();
    await expect(dialog.getByText("This does not look like an email address.")).toBeVisible();

    await dialog.getByLabel("Email").fill(email);
    await dialog.getByRole("button", { name: "Send" }).click();
    await expect(page.getByText("Thank you. We will be in touch.")).toBeVisible();
    await expect(dialog).toBeHidden();
    expect(await rowsFor(email)).toEqual([{ kind: "notify", name: null, organisation: null, locale: "en" }]);

    // Asking again is answered kindly and not stored twice.
    await page.locator("section[aria-labelledby=download] [data-interest=notify]").click();
    await page.getByRole("dialog").getByLabel("Email").fill(email);
    await page.getByRole("dialog").getByRole("button", { name: "Send" }).click();
    await expect(page.getByText("You already asked, and we have it.")).toBeVisible();
    expect(await rowsFor(email)).toHaveLength(1);
  });

  test("a school is invited from the wall, with its name, the school and a message", async ({ page }) => {
    const email = `head${stamp}@school.example`;
    await page.goto("/");
    await page.locator("#schools").scrollIntoViewIfNeeded();
    await expect(page.getByText("Rides with BusIn")).toBeVisible();
    await page.locator("section[aria-labelledby=schools] [data-interest=school]").click();
    const dialog = page.getByRole("dialog", { name: "Bring BusIn to your school" });
    await dialog.getByLabel("Email").fill(email);
    await dialog.getByRole("button", { name: "Send" }).click();
    await expect(dialog.getByText("Fill this in.")).toHaveCount(2);
    await dialog.getByLabel("Your name").fill("Ada Head");
    await dialog.getByLabel("School", { exact: true }).fill("Hill School");
    await dialog.getByLabel("Anything to add").fill("Two buses, 300 students.");
    await dialog.getByRole("button", { name: "Send" }).click();
    await expect(page.getByText("Thank you. We will be in touch.")).toBeVisible();
    expect(await rowsFor(email)).toEqual([{ kind: "school", name: "Ada Head", organisation: "Hill School", locale: "en" }]);
  });

  test("the questions open one at a time, the first one already open", async ({ page }) => {
    await page.goto("/");
    const first = page.getByText("The app costs you nothing.");
    const other = page.getByText(/The app reads your position only when you ask/);
    await expect(first).toBeVisible();
    await expect(other).toBeHidden();
    await page.getByRole("heading", { name: "Does BusIn know where I am?" }).click();
    await expect(other).toBeVisible();
    await expect(first).toBeHidden();
  });

  test("a request with the hidden field filled in looks sent but is not stored", async ({ page }) => {
    const email = `bot${stamp}@example.com`;
    await page.goto("/");
    await page.locator("section[aria-labelledby=download] [data-interest=notify]").click();
    const dialog = page.getByRole("dialog");
    await dialog.getByLabel("Email").fill(email);
    await dialog.locator("input[name=website]").fill("http://spam.example", { force: true });
    await dialog.getByRole("button", { name: "Send" }).click();
    await expect(page.getByText("Thank you. We will be in touch.")).toBeVisible();
    expect(await rowsFor(email)).toHaveLength(0);
  });

  test("the fourth request in an hour from one address is refused", async ({ page }) => {
    const email = `busy${stamp}@example.com`;
    for (const organisation of ["B", "C", "D"]) {
      await serviceClient().from("interest_requests").insert({ kind: "school", email, name: "A", organisation });
    }
    await page.goto("/");
    await page.locator("section[aria-labelledby=download] [data-interest=notify]").click();
    await page.getByRole("dialog").getByLabel("Email").fill(email);
    await page.getByRole("dialog").getByRole("button", { name: "Send" }).click();
    await expect(page.getByText("Too many requests just now.")).toBeVisible();
    await expect(page.getByRole("dialog")).toBeVisible();
  });
});
