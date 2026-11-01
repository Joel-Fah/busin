import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import {
  createSubscription,
  createUser,
  deleteUser,
  serviceClient,
  signInBrowser,
  type TestUser,
} from "./support";

const tag = randomBytes(3).toString("hex");

let admin: TestUser;
let staff: TestUser;
let studentApprove: TestUser;
let studentReject: TestUser;
let approveId: string;
let rejectId: string;

const nameOf = (label: string) => `E2E ${label}`;

test.beforeAll(async () => {
  admin = await createUser(`rev-admin-${tag}`, "admin");
  staff = await createUser(`rev-staff-${tag}`, "staff");
  studentApprove = await createUser(`approve-${tag}`, "student");
  studentReject = await createUser(`reject-${tag}`, "student");
  approveId = await createSubscription(studentApprove.id);
  rejectId = await createSubscription(studentReject.id);
});

test.afterAll(async () => {
  const db = serviceClient();
  await db.from("audit_log").delete().in("target_id", [approveId, rejectId].filter(Boolean));
  for (const user of [admin, staff, studentApprove, studentReject]) {
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

  test("the pages are available in French", async ({ page }) => {
    await page.goto("/subscriptions?status=all");
    await page.getByRole("button", { name: "Français" }).click();
    await expect(page.getByRole("heading", { name: "Abonnements", level: 1 })).toBeVisible();
    await expect(page.getByRole("link", { name: "À examiner" })).toBeVisible();
    await page.getByRole("button", { name: "English" }).click();
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
