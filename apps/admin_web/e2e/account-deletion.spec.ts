import { randomBytes, randomUUID } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createSubscription, createUser, deleteSchool, deleteUser, serviceClient, setPlatformAdmin, signInBrowser } from "./support";

// Account deletion (ADR 0028): asked from the portal, the student web app and the console; the public page; the erasure.
const tag = randomBytes(3).toString("hex");
test.use({ viewport: { width: 1280, height: 900 } });

test("an administrator asks for the deletion of their account, then keeps it", async ({ context, page }) => {
  const admin = await createUser(`del-admin-${tag}`, "admin");
  try {
    await signInBrowser(context, admin);
    await page.goto("/profile");
    await page.getByRole("button", { name: "Delete my account" }).click();
    const dialog = page.getByRole("dialog", { name: "Delete your account?" });
    await expect(dialog).toContainText("Your school keeps its records without your name");
    await dialog.getByRole("button", { name: "Delete in 7 days" }).click();
    await expect(page.getByText("Your account will be deleted in 7 days.")).toBeVisible();
    await expect(page.locator("#delete-account")).toContainText("Your account will be deleted on");

    await page.getByRole("button", { name: "Keep my account" }).click();
    await expect(page.getByText("Deletion cancelled. Your account stays.")).toBeVisible();
    await expect(page.getByRole("button", { name: "Delete my account" })).toBeVisible();
  } finally {
    await deleteUser(admin);
  }
});

test("the last administrator of a school is asked to hand it over first", async ({ context, page }) => {
  const schoolId = randomUUID();
  const created = await serviceClient().from("schools").insert({ id: schoolId, name: `E2E Last Admin ${tag}` });
  if (created.error) throw created.error;
  const only = await createUser(`del-only-${tag}`, "student", "pending", "example.org");
  await serviceClient().from("profiles").update({ school_id: schoolId, role: "admin", status: "verified" }).eq("id", only.id);
  try {
    await signInBrowser(context, only);
    await page.goto("/profile");
    await page.getByRole("button", { name: "Delete my account" }).click();
    await page.getByRole("dialog", { name: "Delete your account?" }).getByRole("button", { name: "Delete in 7 days" }).click();
    await expect(page.locator("#delete-account")).toContainText("You are the last administrator of your school.");
  } finally {
    deleteSchool(schoolId);
  }
});

test("a student asks from the web app; once erased, the school keeps the records without a name", async ({ context, page }) => {
  const student = await createUser(`del-student-${tag}`, "student");
  const admin = serviceClient();
  // A student who finished setup (the web app asks for a phone and a matricule first).
  await admin.from("profiles").update({ matricule: `DEL${tag}`, phone: "+237600000077" }).eq("id", student.id);
  const subscription = await createSubscription(student.id);
  try {
    await signInBrowser(context, student);
    await page.goto("/app/profile");
    await page.getByRole("button", { name: "Delete my account" }).click();
    await page.getByRole("dialog", { name: "Delete your account?" }).getByRole("button", { name: "Delete in 7 days" }).click();
    await expect(page.locator("#delete-account")).toContainText("Your account will be deleted on");

    // The night's job, by hand: the sign-in account soft-deleted, then the profile erased.
    await admin.from("profiles").update({ deletion_due_at: new Date(Date.now() - 1000).toISOString() }).eq("id", student.id);
    const removed = await admin.auth.admin.deleteUser(student.id, true);
    expect(removed.error).toBeNull();
    const erased = await admin.rpc("erase_account", { p_user_id: student.id });
    expect(erased.error).toBeNull();

    const { data: profile } = await admin.from("profiles").select("full_name, email, phone, deleted_at").eq("id", student.id).single();
    expect(profile).toMatchObject({ full_name: "Deleted account", email: `deleted-${student.id}@deleted.invalid`, phone: null });
    expect(profile?.deleted_at).not.toBeNull();
    const { data: kept } = await admin.from("subscriptions").select("id, proof_path").eq("id", subscription).single();
    expect(kept).toEqual({ id: subscription, proof_path: null });
  } finally {
    await admin.from("subscriptions").delete().eq("student_id", student.id);
    await admin.from("audit_log").delete().eq("target_id", student.id);
    await admin.from("profiles").delete().eq("id", student.id);
    await admin.auth.admin.deleteUser(student.id);
  }
});

test("the public page explains it, and someone who lost access can ask; the platform schedules it from Lookup", async ({ browser, page }) => {
  const email = `lost-${tag}@example.org`;
  await page.goto("/delete-account");
  await expect(page.getByRole("heading", { name: "Delete your BusIn account", level: 1 })).toBeVisible();
  await expect(page.getByText("Go to Profile, then Delete my account, and confirm.")).toBeVisible();
  const form = page.getByTestId("deletion-request");
  await form.getByLabel("Email of your account").fill(email);
  await form.getByRole("button", { name: "Ask for the deletion" }).click();
  await expect(form).toContainText("Received. We will write to that address to confirm.");

  const owner = await createUser(`del-owner-${tag}`, "admin");
  const target = await createUser(`del-target-${tag}`, "student");
  setPlatformAdmin(owner.id, true);
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  try {
    await signInBrowser(context, owner);
    const console = await context.newPage();
    await console.goto("/platform/leads?kind=deletion");
    await expect(console.getByTestId("leads")).toContainText(email);

    await console.goto("/platform/lookup");
    await console.getByLabel("Exact email").fill(target.email);
    await console.getByRole("button", { name: "Look up" }).click();
    await expect(console.getByTestId("lookup-deletion")).toContainText("None scheduled");
    await console.getByRole("button", { name: "Schedule the deletion" }).click();
    await console.getByRole("dialog", { name: "Schedule this deletion?" }).getByRole("button", { name: "Schedule the deletion" }).click();
    await expect(console.getByTestId("lookup-deletion")).toContainText("asked by BusIn");
    await console.getByRole("button", { name: "Cancel the deletion" }).click();
    await expect(console.getByTestId("lookup-deletion")).toContainText("None scheduled");
  } finally {
    await context.close();
    setPlatformAdmin(owner.id, false);
    await serviceClient().from("interest_requests").delete().eq("email", email);
    await deleteUser(target);
    await deleteUser(owner);
  }
});

test("People does not list erased accounts", async ({ context, page }) => {
  const admin = await createUser(`del-people-${tag}`, "admin");
  const gone = await createUser(`del-gone-${tag}`, "student");
  const service = serviceClient();
  await service.from("profiles").update({ deleted_at: new Date().toISOString(), full_name: "Deleted account" }).eq("id", gone.id);
  try {
    await signInBrowser(context, admin);
    await page.goto(`/people?q=${encodeURIComponent(gone.email.split("@")[0])}`);
    await expect(page.getByText(gone.email)).toHaveCount(0);
  } finally {
    await deleteUser(gone);
    await deleteUser(admin);
  }
  expect(SEED.schoolId).toBeTruthy();
});
