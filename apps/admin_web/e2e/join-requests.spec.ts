import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// Students without the school's email (ADR 0012): they ask to join, and an admin verifies or declines them in People.
let admin: TestUser;
let asking: TestUser;
let declined: TestUser;
let schoolBefore: { accepts_open_signup: boolean; open_signup_domains: string[] } | null = null;

test.beforeAll(async () => {
  const db = serviceClient();
  const { data } = await db.from("schools").select("accepts_open_signup, open_signup_domains").eq("id", SEED.schoolId).single();
  schoolBefore = data;
  // The seed school accepts students with other emails, so a gmail account may sign up.
  await db.from("schools").update({ accepts_open_signup: true, open_signup_domains: [] }).eq("id", SEED.schoolId);
  admin = await createUser(`join-admin-${Date.now()}`, "admin");
  asking = await createUser("join-ama", "student", "pending", "gmail.com");
  declined = await createUser("join-kofi", "student", "pending", "gmail.com");
  // Each asks to join the seed school (what request_school does in the app).
  for (const user of [asking, declined]) {
    await db.from("profiles").update({ school_id: SEED.schoolId, join_requested_at: new Date().toISOString() }).eq("id", user.id);
  }
});

test.afterAll(async () => {
  for (const user of [admin, asking, declined]) if (user) await deleteUser(user);
  if (schoolBefore) await serviceClient().from("schools").update(schoolBefore).eq("id", SEED.schoolId);
});

test("an admin verifies one request and declines another with a reason", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/people");
  const tab = page.getByRole("link", { name: /To verify/ });
  await expect(tab).toContainText(/[2-9]|\d{2,}/);
  await tab.click();
  await expect(page).toHaveURL(/role=verify/);

  const amaRow = page.getByRole("row").filter({ hasText: asking.email });
  await amaRow.getByRole("button", { name: "Verify" }).click();
  await expect(page.getByRole("status")).toContainText("Student verified.");
  await expect(page.getByRole("row").filter({ hasText: asking.email })).toHaveCount(0);

  await page.getByRole("row").filter({ hasText: declined.email }).getByRole("button", { name: "Decline" }).click();
  const dialog = page.getByRole("dialog", { name: "Decline this request?" });
  await dialog.getByLabel("Reason (optional)").fill("We could not find you in our student list.");
  await dialog.getByRole("button", { name: "Decline the request" }).click();
  await expect(page.getByRole("status")).toContainText("Request declined.");

  const db = serviceClient();
  const ama = await db.from("profiles").select("status, school_id").eq("id", asking.id).single();
  expect(ama.data).toEqual({ status: "verified", school_id: SEED.schoolId });
  const kofi = await db.from("profiles").select("status, school_id, join_decline_note, join_declined_school").eq("id", declined.id).single();
  expect(kofi.data).toEqual({ status: "pending", school_id: null, join_decline_note: "We could not find you in our student list.", join_declined_school: SEED.schoolId });
});
