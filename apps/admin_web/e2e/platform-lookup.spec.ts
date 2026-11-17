import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, serviceClient, setPlatformAdmin, signInBrowser, type TestUser } from "./support";

// Account lookup in the platform console (ADR 0027, slice 7).
const tag = randomBytes(3).toString("hex");
let owner: TestUser;
let student: TestUser;

test.beforeAll(async () => {
  owner = await createUser(`lookup-owner-${tag}`, "admin");
  student = await createUser(`lookup-student-${tag}`, "student", "pending");
  setPlatformAdmin(owner.id, true);
});

test.afterAll(async () => {
  setPlatformAdmin(owner.id, false);
  await deleteUser(student);
  await deleteUser(owner);
});

test.use({ viewport: { width: 1280, height: 900 } });

test("an account is found by its exact email, and the lookup is recorded", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform/lookup");
  await page.getByLabel("Exact email").fill(student.email.toUpperCase());
  await page.getByRole("button", { name: "Look up" }).click();

  const result = page.getByTestId("lookup-result");
  await expect(result).toContainText(student.email);
  await expect(result).toContainText("Student");
  await expect(result).toContainText("Pending");
  await expect(result.getByRole("link", { name: "ICT University" })).toHaveAttribute("href", /\/platform\/schools\//);
  // The email never goes into the address.
  expect(page.url()).not.toContain("@");

  const { data } = await serviceClient().from("platform_audit").select("action, target_id, details").eq("actor_id", owner.id).eq("action", "account.lookup");
  expect(data).toEqual([{ action: "account.lookup", target_id: student.id, details: { found: true } }]);
});

test("an unknown email finds nothing", async ({ context, page }) => {
  await signInBrowser(context, owner);
  await page.goto("/platform/lookup");
  await page.getByLabel("Exact email").fill(`nobody-${tag}@example.org`);
  await page.getByRole("button", { name: "Look up" }).click();
  await expect(page.getByTestId("lookup-result")).toContainText("No account with this email.");
});

test("on a small phone the result's header stacks: nothing spills out of the card, the name has its own lines", async ({ browser }) => {
  const long = await createUser(`lookup-long-registrar-office-${tag}`, "admin", "pending");
  setPlatformAdmin(long.id, true);
  const { error } = await serviceClient().from("profiles").update({ full_name: "Marie-Claire Nkongho Tchakounte Abena Fotso" }).eq("id", long.id);
  expect(error).toBeNull();
  try {
    for (const width of [360, 1280]) {
      const context = await browser.newContext({ viewport: { width, height: 800 }, reducedMotion: "reduce" });
      await signInBrowser(context, owner);
      const page = await context.newPage();
      await page.goto("/platform/lookup");
      await page.getByLabel("Exact email").fill(long.email);
      await page.getByRole("button", { name: "Look up" }).click();
      const result = page.getByTestId("lookup-result");
      await expect(result.getByTestId("lookup-chips")).toContainText("Also a platform admin");

      const layout = await result.evaluate((root) => {
        const box = (el: Element | null) => el!.getBoundingClientRect();
        const card = box(root.firstElementChild);
        const spills = [...root.querySelectorAll("*")].filter((el) => {
          const r = el.getBoundingClientRect();
          return r.width > 0 && (r.left < card.left - 0.5 || r.right > card.right + 0.5);
        }).length;
        const header = root.querySelector('[data-testid="lookup-header"]')!;
        const name = box(root.querySelector('[data-testid="lookup-name"]'));
        const avatar = box(header.firstElementChild);
        const chips = box(root.querySelector('[data-testid="lookup-chips"]'));
        return { spills, scroll: document.documentElement.scrollWidth, nameTop: name.top, nameBottom: name.bottom, avatarBottom: avatar.bottom, chipsTop: chips.top };
      });
      expect(layout.spills).toBe(0);
      expect(layout.scroll).toBeLessThanOrEqual(width);
      if (width === 360) {
        // Avatar, then the name, then the chips below it: nothing shares the name's lines.
        expect(layout.nameTop).toBeGreaterThanOrEqual(layout.avatarBottom);
        expect(layout.chipsTop).toBeGreaterThanOrEqual(layout.nameBottom);
      } else {
        // On a desktop it stays one row: the chips sit beside the name.
        expect(layout.chipsTop).toBeLessThan(layout.nameBottom);
        expect(layout.nameTop).toBeLessThan(layout.avatarBottom);
      }
      await context.close();
    }
  } finally {
    setPlatformAdmin(long.id, false);
    await deleteUser(long);
  }
});

test("a school admin cannot open it", async ({ context, page }) => {
  const admin = await createUser(`lookup-admin-${tag}`, "admin");
  try {
    await signInBrowser(context, admin);
    await page.goto("/platform/lookup");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  } finally {
    await deleteUser(admin);
  }
});
