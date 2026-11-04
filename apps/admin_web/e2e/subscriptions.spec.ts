import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import {
  createSubscription,
  createUser,
  deleteUser,
  serviceClient,
  signInBrowser,
  type TestUser,
  setLanguage,
} from "./support";

const tag = randomBytes(3).toString("hex");

let admin: TestUser;
let staff: TestUser;
let studentApprove: TestUser;
let studentReject: TestUser;
let studentView: TestUser;
let approveId: string;
let rejectId: string;
// Used only to look at the review page, so no other test decides it.
let viewId: string;

const nameOf = (label: string) => `E2E ${label}`;

test.beforeAll(async () => {
  admin = await createUser(`rev-admin-${tag}`, "admin");
  staff = await createUser(`rev-staff-${tag}`, "staff");
  studentApprove = await createUser(`approve-${tag}`, "student");
  studentReject = await createUser(`reject-${tag}`, "student");
  approveId = await createSubscription(studentApprove.id);
  rejectId = await createSubscription(studentReject.id);
  studentView = await createUser(`view-${tag}`, "student");
  viewId = await createSubscription(studentView.id);
});

test.afterAll(async () => {
  const db = serviceClient();
  await db.from("audit_log").delete().in("target_id", [approveId, rejectId].filter(Boolean));
  for (const user of [admin, staff, studentApprove, studentReject, studentView]) {
    if (user) await deleteUser(user);
  }
});

test.describe("administrator reviewing", () => {
  test.beforeEach(async ({ context }) => {
    await signInBrowser(context, admin);
  });

  test("sees pending requests in the review queue and opens one", async ({ page }) => {
    await page.goto("/subscriptions");
    await expect(page.getByRole("heading", { name: "Subscriptions", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "To review" })).toHaveAttribute("aria-current", "page");

    const row = page.getByRole("row").filter({ hasText: nameOf(`approve-${tag}`) });
    await expect(row).toBeVisible();
    await expect(row.getByText("Pending")).toBeVisible();

    await row.getByRole("link").click();
    await expect(page).toHaveURL(new RegExp(`/subscriptions/${approveId}$`));
    await expect(page.getByText("No proof was uploaded.")).toBeVisible();
  });

  test("the approved filter does not list a pending request", async ({ page }) => {
    await page.goto("/subscriptions?status=approved");
    await expect(page.getByRole("link", { name: "Approved" })).toHaveAttribute("aria-current", "page");
    await expect(page.getByRole("row").filter({ hasText: nameOf(`approve-${tag}`) })).toHaveCount(0);
  });

  test("approving records the decision and writes the audit log", async ({ page }) => {
    await page.goto(`/subscriptions/${approveId}`);
    await page.getByRole("button", { name: "Approve" }).click();

    await expect(page.getByRole("status")).toContainText("Subscription approved.");
    await expect(page.getByText("Approved").first()).toBeVisible();
    // Decided requests no longer offer the buttons.
    await expect(page.getByRole("button", { name: "Approve" })).toHaveCount(0);

    const db = serviceClient();
    const { data: row } = await db.from("subscriptions").select("status, reviewed_by").eq("id", approveId).single();
    expect(row?.status).toBe("approved");
    expect(row?.reviewed_by).toBe(admin.id);

    const { count } = await db
      .from("audit_log")
      .select("id", { count: "exact", head: true })
      .eq("target_id", approveId)
      .eq("action", "subscription.approved");
    expect(count).toBe(1);

    await page.goto("/subscriptions");
    await expect(page.getByRole("row").filter({ hasText: nameOf(`approve-${tag}`) })).toHaveCount(0);
  });

  test("rejecting needs a reason, then stores it for the student", async ({ page }) => {
    await page.goto(`/subscriptions/${rejectId}`);
    await page.getByText("Reject with a reason").click();

    // The browser stops an empty reason before anything is sent.
    await page.getByRole("button", { name: "Confirm rejection" }).click();
    await expect(page).toHaveURL(new RegExp(`/subscriptions/${rejectId}$`));
    const db = serviceClient();
    expect((await db.from("subscriptions").select("status").eq("id", rejectId).single()).data?.status).toBe("pending");

    await page.getByLabel("Reason for rejection").fill("The receipt is unreadable. Upload a clearer photo.");
    await page.getByRole("button", { name: "Confirm rejection" }).click();

    await expect(page.getByRole("status")).toContainText("Subscription rejected.");
    await expect(page.getByText("The receipt is unreadable. Upload a clearer photo.")).toBeVisible();

    const { data: row } = await db.from("subscriptions").select("status, review_note").eq("id", rejectId).single();
    expect(row?.status).toBe("rejected");
    expect(row?.review_note).toBe("The receipt is unreadable. Upload a clearer photo.");
  });

  test("an unknown or malformed id shows the not-found page", async ({ page }) => {
    await page.goto("/subscriptions/not-a-uuid");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
    await page.goto("/subscriptions/a1000000-0000-4000-8000-0000000000ff");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  });

  test("odd filter and page values fall back safely", async ({ page }) => {
    await page.goto("/subscriptions?status=%27%3Bdrop&page=-5");
    await expect(page.getByRole("heading", { name: "Subscriptions", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "To review" })).toHaveAttribute("aria-current", "page");
  });

  test("filters by stop and semester from the headings, with chips", async ({ page }) => {
    await page.goto("/subscriptions?status=all");
    await page.getByRole("button", { name: "Stop", exact: true }).click();
    await page.getByRole("dialog", { name: "Stop" }).getByRole("link", { name: "Sample stop A" }).click();
    await expect(page).toHaveURL(/stop=00000000-0000-4000-8000-000000000021/);
    await expect(page.getByRole("group", { name: "Active filters" }).getByRole("link", { name: /Stop Sample stop A/ })).toBeVisible();
    await expect(page.getByRole("row").filter({ hasText: `E2E view-${tag}` })).toHaveCount(1);

    // Another stop has none of these students.
    await page.goto("/subscriptions?status=all&stop=00000000-0000-4000-8000-000000000022");
    await expect(page.getByRole("row").filter({ hasText: `E2E view-${tag}` })).toHaveCount(0);
    await expect(page.getByText("Try removing a filter above the table.")).toBeVisible();

    await page.goto("/subscriptions?status=all");
    await page.getByRole("button", { name: "Semester", exact: true }).click();
    await page.getByRole("dialog", { name: "Semester" }).getByRole("link", { name: "Fall 2026" }).click();
    await expect(page).toHaveURL(/semester=00000000-0000-4000-8000-000000000011/);
    await expect(page.getByRole("row").filter({ hasText: `E2E view-${tag}` })).toHaveCount(1);
  });

  test("the tab numbers follow the filters", async ({ page }) => {
    await page.goto("/subscriptions?stop=00000000-0000-4000-8000-000000000022");
    const tabs = page.getByRole("navigation", { name: "Filter by status" });
    await expect(tabs.getByRole("link", { name: /To review/ })).toContainText("0");
  });

  test("each tab shows how many subscriptions are behind it, matching the database", async ({ page }) => {
    const db = serviceClient();
    const total = async (status?: "pending" | "approved" | "rejected" | "expired") => {
      let query = db.from("subscriptions").select("id", { count: "exact", head: true });
      if (status) query = query.eq("status", status);
      const { count } = await query;
      return count ?? 0;
    };
    await page.goto("/subscriptions");
    const tabs = page.getByRole("navigation", { name: "Filter by status" });
    await expect(tabs.getByRole("link", { name: /To review/ })).toContainText(String(await total("pending")));
    await expect(tabs.getByRole("link", { name: /Approved/ })).toContainText(String(await total("approved")));
    await expect(tabs.getByRole("link", { name: /Rejected/ })).toContainText(String(await total("rejected")));
    await expect(tabs.getByRole("link", { name: /All/ })).toContainText(String(await total()));
  });

  test("the queue tab is in the warning tone and approved is in the ok tone, with the label beside the colour", async ({ page }) => {
    await page.goto("/subscriptions");
    const tabs = page.getByRole("navigation", { name: "Filter by status" });
    const colourOf = (name: RegExp) =>
      tabs.getByRole("link", { name }).locator("span").last().evaluate((el) => getComputedStyle(el).backgroundColor);
    expect(await colourOf(/To review/)).not.toBe(await colourOf(/Approved/));
    await expect(tabs.getByRole("link", { name: /To review/ })).toContainText("To review");
  });

  test("the help button explains reviewing with examples", async ({ page }) => {
    await page.goto("/subscriptions");
    await page.getByRole("button", { name: "Help" }).click();
    const sheet = page.getByRole("dialog", { name: "How reviewing works" });
    await expect(sheet).toBeVisible();
    await expect(sheet.getByText("The receipt is unreadable")).toBeVisible();
  });

  test("an empty page shows a friendly empty state with an illustration, not a bare line", async ({ page }) => {
    await page.goto("/subscriptions?status=approved&page=50");
    await expect(page.getByText("No subscriptions here")).toBeVisible();
    await expect(page.getByText("Try another tab.")).toBeVisible();
    await expect(page.locator("img[src*='papers']")).toBeVisible();
  });

  test("the review page uses the design system: back button, status chip, proof card and a field with an icon", async ({ page }) => {
    await page.goto(`/subscriptions/${viewId}`);
    await expect(page.getByRole("link", { name: "Back to subscriptions" })).toBeVisible();
    await expect(page.getByRole("heading", { name: nameOf(`view-${tag}`), level: 1 })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Payment proof" })).toBeVisible();
    await page.getByText("Reject with a reason").click();
    const reason = page.getByLabel("Reason for rejection");
    await expect(reason).toHaveAttribute("placeholder", /receipt is unreadable/);
    await expect(reason).toHaveAttribute("maxlength", "500");
    // The reject button is the danger style.
    const isDanger = await page.getByRole("button", { name: "Confirm rejection" }).evaluate((el) => {
      const probe = document.createElement("span");
      probe.style.color = "var(--bad)";
      document.body.append(probe);
      const same = getComputedStyle(el).color === getComputedStyle(probe).color;
      probe.remove();
      return same;
    });
    expect(isDanger).toBe(true);
  });

  test("the pages are available in French", async ({ page }) => {
    await setLanguage(page, "fr");
    await page.goto("/subscriptions?status=all");
    await expect(page.getByRole("heading", { name: "Abonnements", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "À examiner" })).toBeVisible();
    await setLanguage(page, "en");
  });
});

for (const [label, who] of [
  ["a student", () => studentReject],
  ["a staff member", () => staff],
] as const) {
  test(`${label} cannot open the review pages`, async ({ page, context }) => {
    await signInBrowser(context, who());
    await page.goto("/subscriptions");
    await expect(page).toHaveURL(/\/no-access$/);
    await page.goto(`/subscriptions/${rejectId}`);
    await expect(page).toHaveURL(/\/no-access$/);
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/subscriptions");
  await expect(page).toHaveURL(/\/login$/);
});
