import { expect, test } from "@playwright/test";

import { serviceClient } from "./support";

const rowsFor = async (email: string) => {
  const { data } = await serviceClient().from("interest_requests").select("kind, name, organisation, locale").eq("email", email);
  return data ?? [];
};

test.describe("the landing page's interest form", () => {
  const stamp = Date.now();

  test.afterAll(async () => {
    await serviceClient().from("interest_requests").delete().like("email", `%${stamp}%`);
  });

  test("with no app link set, each platform offers Get notified, and the request is stored once", async ({ page }) => {
    const email = `notify${stamp}@example.com`;
    await page.goto("/");
    await expect(page.locator("[data-interest=notify_android]")).toHaveText("Get notified");
    await expect(page.locator("[data-interest=notify_ios]")).toHaveText("Get notified");

    await page.locator("[data-interest=notify_android]").click();
    const dialog = page.getByRole("dialog", { name: "Tell me when it is on Android" });
    await dialog.getByRole("button", { name: "Send" }).click();
    await expect(dialog.getByText("Fill this in.")).toBeVisible();
    await dialog.getByLabel("Email").fill("not-an-email");
    await dialog.getByRole("button", { name: "Send" }).click();
    await expect(dialog.getByText("This does not look like an email address.")).toBeVisible();

    await dialog.getByLabel("Email").fill(email);
    await dialog.getByRole("button", { name: "Send" }).click();
    await expect(page.getByText("Thank you. We will be in touch.")).toBeVisible();
    await expect(dialog).toBeHidden();
    expect(await rowsFor(email)).toEqual([{ kind: "notify_android", name: null, organisation: null, locale: "en" }]);

    // Asking again is answered kindly and not stored twice.
    await page.locator("[data-interest=notify_android]").click();
    await page.getByRole("dialog").getByLabel("Email").fill(email);
    await page.getByRole("dialog").getByRole("button", { name: "Send" }).click();
    await expect(page.getByText("You already asked, and we have it.")).toBeVisible();
    expect(await rowsFor(email)).toHaveLength(1);
  });

  test("a request with the hidden field filled in looks sent but is not stored", async ({ page }) => {
    const email = `bot${stamp}@example.com`;
    await page.goto("/");
    await page.locator("[data-interest=notify_ios]").click();
    const dialog = page.getByRole("dialog");
    await dialog.getByLabel("Email").fill(email);
    await dialog.locator("input[name=website]").fill("http://spam.example", { force: true });
    await dialog.getByRole("button", { name: "Send" }).click();
    await expect(page.getByText("Thank you. We will be in touch.")).toBeVisible();
    expect(await rowsFor(email)).toHaveLength(0);
  });

  test("the fourth request in an hour from one address is refused", async ({ page }) => {
    const email = `busy${stamp}@example.com`;
    for (const kind of ["notify_android", "notify_ios", "school"]) {
      await serviceClient().from("interest_requests").insert({ kind, email, name: "A", organisation: "B" });
    }
    await page.goto("/");
    await page.locator("[data-interest=notify_ios]").click();
    await page.getByRole("dialog").getByLabel("Email").fill(email);
    await page.getByRole("dialog").getByRole("button", { name: "Send" }).click();
    await expect(page.getByText("Too many requests just now.")).toBeVisible();
    await expect(page.getByRole("dialog")).toBeVisible();
  });
});
