import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { createUser, deleteUser, serviceClient, signInBrowser, type TestUser, chooseOption, setLanguage } from "./support";

const tag = randomBytes(3).toString("hex");

let admin: TestUser;
let staff: TestUser;
let promote: TestUser;
let suspend: TestUser;
let plainStudent: TestUser;

const nameOf = (label: string) => `E2E ${label}`;

test.beforeAll(async () => {
  admin = await createUser(`ppl-admin-${tag}`, "admin");
  staff = await createUser(`ppl-staff-${tag}`, "staff");
  promote = await createUser(`promote-${tag}`, "staff");
  suspend = await createUser(`suspend-${tag}`, "student");
  plainStudent = await createUser(`plain-${tag}`, "student");
});

test.afterAll(async () => {
  // Audit rows point at the acting admin, so they go before the users do.
  await serviceClient().from("audit_log").delete().eq("actor_id", admin?.id ?? "");
  for (const user of [admin, staff, promote, suspend, plainStudent]) {
    if (user) await deleteUser(user);
  }
});

test.describe("administrator managing people", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("lists people and filters by role", async ({ page }) => {
    await page.goto("/people");
    await expect(page.getByRole("heading", { name: "People", level: 1 })).toBeVisible();

    const filters = page.getByRole("navigation", { name: "Filter by role" });
    await filters.getByRole("link", { name: "Staff" }).click();
    await expect(page).toHaveURL(/role=staff/);
    await expect(page.getByRole("row").filter({ hasText: nameOf(`ppl-staff-${tag}`) })).toBeVisible();
    await expect(page.getByRole("row").filter({ hasText: nameOf(`plain-${tag}`) })).toHaveCount(0);

    await filters.getByRole("link", { name: "Students" }).click();
    await expect(page.getByRole("row").filter({ hasText: nameOf(`plain-${tag}`) })).toBeVisible();
    await expect(page.getByRole("row").filter({ hasText: nameOf(`ppl-staff-${tag}`) })).toHaveCount(0);
  });

  test("the number of people per page can be chosen, and it stays with the search", async ({ page }) => {
    await page.goto("/people");
    const perPage = page.getByRole("navigation", { name: "Items per page" });
    await expect(perPage.getByRole("link", { name: "20", exact: true })).toHaveAttribute("aria-current", "true");
    await perPage.getByRole("link", { name: "10", exact: true }).click();
    await expect(page).toHaveURL(/[?&]size=10/);
    await expect(page.getByRole("navigation", { name: "Items per page" }).getByRole("link", { name: "10", exact: true })).toHaveAttribute("aria-current", "true");
    expect(await page.locator("tbody tr").count()).toBeLessThanOrEqual(10);

    await page.getByRole("searchbox").fill("a");
    await page.getByRole("searchbox").press("Enter");
    await expect(page).toHaveURL(/[?&]size=10/);
  });

  test("searches by name, and odd characters do not break the page", async ({ page }) => {
    await page.goto("/people");
    await page.getByRole("searchbox").fill(`promote-${tag}`);
    await page.getByRole("button", { name: "Search" }).click();
    await expect(page.getByRole("row").filter({ hasText: nameOf(`promote-${tag}`) })).toBeVisible();
    await expect(page.getByRole("row").filter({ hasText: nameOf(`plain-${tag}`) })).toHaveCount(0);

    await page.goto("/people?q=" + encodeURIComponent("a,b)(%*\\\"'"));
    await expect(page.getByRole("heading", { name: "People", level: 1 })).toBeVisible();
    await expect(page.getByRole("alert").filter({ hasText: "could not be loaded" })).toHaveCount(0);
  });

  test("changing a role is stored and audited", async ({ page }) => {
    await page.goto("/people");
    await page.getByRole("searchbox").fill(`promote-${tag}`);
    await page.getByRole("button", { name: "Search" }).click();
    await page.getByRole("row").filter({ hasText: nameOf(`promote-${tag}`) }).getByRole("link").first().click();

    // Staff and administrator are swapped here; a student is not offered a role at all (see the next test).
    await chooseOption(page, "New role", "Administrator");
    await page.getByRole("button", { name: "Change role" }).click();
    await expect(page.getByRole("status")).toContainText("Role changed.");

    const db = serviceClient();
    expect((await db.from("profiles").select("role").eq("id", promote.id).single()).data?.role).toBe("admin");

    const { data: entries } = await db
      .from("audit_log")
      .select("action, actor_id, details")
      .eq("target_id", promote.id)
      .eq("action", "user.role_changed");
    expect(entries).toHaveLength(1);
    expect(entries?.[0].actor_id).toBe(admin.id);
    expect(entries?.[0].details).toMatchObject({ from: "staff", to: "admin" });
  });

  test("a student has no role to change, and a suspended person can only be restored", async ({ page }) => {
    // A student keeps the student role: no role form, and the page says why.
    await page.goto("/people");
    await page.getByRole("searchbox").fill(`plain-${tag}`);
    await page.getByRole("button", { name: "Search" }).click();
    await page.getByRole("row").filter({ hasText: nameOf(`plain-${tag}`) }).getByRole("link").first().click();
    await expect(page.getByText("Students keep the student role.")).toBeVisible();
    await expect(page.getByRole("button", { name: "Change role" })).toHaveCount(0);

    // Suspended: frozen. Only Restore is left, with the reason.
    const db = serviceClient();
    await db.from("profiles").update({ status: "suspended" }).eq("id", plainStudent.id);
    try {
      await page.reload();
      await expect(page.getByText("This account is suspended. Nothing can be changed on it until you restore it.")).toBeVisible();
      await expect(page.getByRole("button", { name: "Restore this account" })).toBeVisible();
      await expect(page.getByText("Suspend this account")).toHaveCount(0);
    } finally {
      await db.from("profiles").update({ status: "verified" }).eq("id", plainStudent.id);
    }
  });

  test("a suspended staff member's role cannot be changed either", async ({ page }) => {
    const db = serviceClient();
    await db.from("profiles").update({ status: "suspended" }).eq("id", staff.id);
    try {
      await page.goto(`/people/${staff.id}`);
      await expect(page.getByText("This account is suspended.")).toBeVisible();
      await expect(page.getByRole("button", { name: "Change role" })).toHaveCount(0);
    } finally {
      await db.from("profiles").update({ status: "verified" }).eq("id", staff.id);
    }
  });

  test("suspending and restoring an account", async ({ page }) => {
    await page.goto(`/people/${suspend.id}`);
    await page.getByText("Suspend this account").click();
    await page.getByRole("button", { name: "Confirm suspension" }).click();
    await expect(page.getByRole("status").filter({ hasText: "Account suspended." })).toBeVisible();

    const db = serviceClient();
    expect((await db.from("profiles").select("status").eq("id", suspend.id).single()).data?.status).toBe("suspended");

    await page.getByRole("button", { name: "Restore this account" }).click();
    await expect(page.getByRole("status").filter({ hasText: "Account restored." })).toBeVisible();
    expect((await db.from("profiles").select("status").eq("id", suspend.id).single()).data?.status).toBe("verified");
  });

  test("an administrator cannot change their own account", async ({ page }) => {
    await page.goto(`/people/${admin.id}`);
    await expect(page.getByRole("note")).toContainText("You cannot change your own role or status");
    await expect(page.getByRole("button", { name: "Change role" })).toHaveCount(0);
    await expect(page.getByText("Suspend this account")).toHaveCount(0);
  });

  test("a malformed or unknown id shows the not-found page", async ({ page }) => {
    await page.goto("/people/not-a-uuid");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
    await page.goto("/people/a1000000-0000-4000-8000-0000000000ff");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  });

  test("the search field always shows a placeholder and the tabs count people for the search", async ({ page }) => {
    await page.goto("/people");
    await expect(page.getByLabel("Search by name, email or matricule")).toHaveAttribute("placeholder", "Name, email or matricule...");
    const tabs = page.getByRole("navigation", { name: "Filter by role" });
    const everyone = await tabs.getByRole("link", { name: /Everyone/ }).textContent();
    expect(Number(everyone?.match(/\d+/)?.[0])).toBeGreaterThan(0);

    await page.goto("/people?q=zzz-nobody-has-this-name");
    await expect(page.getByText("No one matches this search.")).toBeVisible();
    await expect(tabs.getByRole("link", { name: /Everyone/ })).toContainText("0");
  });

  test("the help button explains people with examples", async ({ page }) => {
    await page.goto("/people");
    await page.getByRole("button", { name: "Help" }).click();
    await expect(page.getByRole("dialog", { name: "How people work" }).getByText("A new driver joins")).toBeVisible();
  });

  test("the pages are available in French", async ({ page }) => {
    await setLanguage(page, "fr");
    await page.goto("/people");
    await expect(page.getByRole("heading", { name: "Personnes", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "Étudiants" })).toBeVisible();
    await setLanguage(page, "en");
  });
});

for (const [label, who] of [
  ["a student", () => plainStudent],
  ["a staff member", () => staff],
] as const) {
  test(`${label} cannot open the people pages`, async ({ page, context }) => {
    await signInBrowser(context, who());
    // Staff are shown the no-access page; a student is sent to their own app instead (ADR 0021).
    const away = label === "a student" ? /\/app\// : /\/no-access$/;
    for (const path of ["/people", `/people/${admin.id}`]) {
      // The student app may still be moving on from the last page; a navigation it cuts short is fine.
      await page.goto(path).catch(() => undefined);
      await expect(page).toHaveURL(away);
    }
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/people");
  await expect(page).toHaveURL(/\/login$/);
});

test.describe("the sticky toolbar", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  /** Enough people that the list is taller than a short screen, so it scrolls. */
  async function withManyPeople(run: () => Promise<void>) {
    const extra: TestUser[] = [];
    try {
      for (let i = 0; i < 14; i++) extra.push(await createUser(`stick-${tag}-${i}`, "student"));
      await run();
    } finally {
      for (const user of extra) await deleteUser(user);
    }
  }

  const centreY = (box: { y: number; height: number }) => box.y + box.height / 2;

  test("sticks when the list scrolls, realigned into one row, and relaxes back at the top", async ({ page }) => {
    await withManyPeople(async () => {
      await page.setViewportSize({ width: 1280, height: 560 });
      await page.goto("/people");
      const bar = page.locator(".sticky-toolbar");
      const search = page.getByRole("search");
      const tabs = page.getByRole("navigation", { name: "Filter by role" });

      // At the top: roomy, the search on one line and the tabs below it.
      await expect(bar).toHaveAttribute("data-stuck", "false");
      const roomySearch = (await search.boundingBox())!;
      const roomyTabs = (await tabs.boundingBox())!;
      expect(roomyTabs.y).toBeGreaterThanOrEqual(roomySearch.y + roomySearch.height - 2);

      // Scrolled: compact, both on one line, resting near the top while the list moves behind.
      await page.mouse.wheel(0, 700);
      await expect(bar).toHaveAttribute("data-stuck", "true");
      await expect.poll(async () => Math.abs(centreY((await tabs.boundingBox())!) - centreY((await search.boundingBox())!))).toBeLessThan(24);
      const resting = (await bar.boundingBox())!;
      expect(resting.y).toBeGreaterThanOrEqual(8);
      expect(resting.y).toBeLessThanOrEqual(40);
      expect(await page.evaluate(() => window.scrollY)).toBeGreaterThan(300);

      // Both controls still work while stuck.
      await expect(search.getByLabel("Search by name, email or matricule")).toHaveAttribute("placeholder", /./);
      await expect(tabs.getByRole("link", { name: /Students/ })).toBeVisible();

      // Back at the top: roomy again.
      await page.mouse.wheel(0, -3000);
      await expect(bar).toHaveAttribute("data-stuck", "false");
      await expect.poll(async () => (await tabs.boundingBox())!.y).toBeGreaterThanOrEqual(roomySearch.y + roomySearch.height - 2);
    });
  });

  test("the list below does not jump when the toolbar shrinks", async ({ page }) => {
    await withManyPeople(async () => {
      await page.setViewportSize({ width: 1280, height: 560 });
      await page.goto("/people");
      const bar = page.locator(".sticky-toolbar");
      const table = page.getByRole("table");
      const before = (await table.boundingBox())!.y + (await page.evaluate(() => window.scrollY));
      await page.mouse.wheel(0, 700);
      await expect(bar).toHaveAttribute("data-stuck", "true");
      const after = (await table.boundingBox())!.y + (await page.evaluate(() => window.scrollY));
      // The table sits at the same place on the page: the space the roomy toolbar needed is held.
      expect(Math.abs(after - before)).toBeLessThan(2);
    });
  });
});

test.describe("the sticky toolbar with motion", () => {
  test.use({ reducedMotion: "no-preference" });

  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("glides between the two layouts instead of jumping", async ({ page }) => {
    const extra: TestUser[] = [];
    try {
      for (let i = 0; i < 14; i++) extra.push(await createUser(`glide-${tag}-${i}`, "student"));
      await page.setViewportSize({ width: 1280, height: 560 });
      await page.goto("/people");
      await page.mouse.click(5, 5); // skip the logo intro, so only the toolbar moves
      await expect(page.locator(".brand-intro")).toBeHidden({ timeout: 8000 });
      await expect(page.getByRole("navigation", { name: "Main navigation" })).toHaveCSS("opacity", "1", { timeout: 8000 });

      // Record how far across the tabs are on every frame, inside the page, starting before the scroll that triggers the change.
      const frames = await page.evaluate(
        () =>
          new Promise<number[]>((resolve) => {
            const nav = document.querySelector('nav[aria-label="Filter by role"]')!;
            const out: number[] = [];
            const start = performance.now();
            let scrolled = false;
            const tick = () => {
              out.push(Math.round(nav.getBoundingClientRect().x));
              if (!scrolled && performance.now() - start > 150) {
                scrolled = true;
                window.scrollTo(0, 700);
              }
              if (performance.now() - start < 1500) requestAnimationFrame(tick);
              else resolve(out);
            };
            tick();
          }),
      );

      const last = frames[frames.length - 1];
      const first = frames[0];
      // They end up well to the right of where they started (beside the search, not under it)...
      expect(last).toBeGreaterThan(first + 200);
      // ...and on the way they were seen at places in between, not only at the two ends.
      const onTheWay = frames.filter((x) => x > first + 40 && x < last - 40);
      expect(onTheWay.length).toBeGreaterThanOrEqual(3);
    } finally {
      for (const user of extra) await deleteUser(user);
    }
  });
});
