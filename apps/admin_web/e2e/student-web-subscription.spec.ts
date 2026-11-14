import { randomBytes } from "node:crypto";

import { expect, test, type Page } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// The student web app's subscription tab (ADR 0021): ask for a subscription with a proof, and see the school's decision live.
const tag = randomBytes(3).toString("hex");
let student: TestUser;
const PNG = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==", "base64");

test.use({ viewport: { width: 390, height: 844 } });
test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  student = await createUser(`web-sub-${tag}`, "student");
  await serviceClient().from("profiles").update({ matricule: `SUB${tag}`, phone: "+237600000004", full_name: "Amara Ngono" }).eq("id", student.id);
});

test.afterAll(async () => {
  const db = serviceClient();
  const { data } = await db.storage.from("proofs").list(`${SEED.schoolId}/${student.id}`);
  if (data?.length) await db.storage.from("proofs").remove(data.map((f) => `${SEED.schoolId}/${student.id}/${f.name}`));
  if (student) await deleteUser(student);
});

async function stopName(): Promise<string> {
  const { data } = await serviceClient().from("stops").select("name").eq("id", SEED.stopId).single();
  return data!.name;
}

async function chooseStop(page: Page, name: string) {
  await page.getByRole("button", { name: /Your stop/ }).click();
  await page.getByRole("dialog").getByLabel("Search stops").fill(name.slice(0, 5));
  await page.getByRole("dialog").getByRole("button", { name }).click();
}

test("refuses a file that is not a photo", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/subscription");
  await expect(page.getByText("Subscribe for Fall 2026")).toBeVisible();
  await page.getByTestId("proof-input").setInputFiles({ name: "receipt.pdf", mimeType: "application/pdf", buffer: Buffer.from("%PDF-1.7 not a photo") });
  await expect(page.getByText("Use a JPEG, PNG or WebP photo.")).toBeVisible();
  await expect(page.getByRole("button", { name: "Send request" })).toBeDisabled();
});

test("sends a request with a stop and a photo of the receipt", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/subscription");
  const stop = await stopName();
  await chooseStop(page, stop);
  await page.getByTestId("proof-input").setInputFiles({ name: "receipt.png", mimeType: "image/png", buffer: PNG });
  await expect(page.getByText("Photo added")).toBeVisible();
  // The seed school offers installments; In full is chosen by default, and sending in full asks nothing more (ADR 0022).
  await expect(page.getByRole("radio", { name: "In full" })).toHaveAttribute("aria-checked", "true");
  await page.getByRole("button", { name: "Send request" }).click();

  await expect(page.getByTestId("status-card")).toContainText("Request sent");
  await expect(page.getByTestId("status-card")).toContainText(stop);
  const { data } = await serviceClient().from("subscriptions").select("status, proof_path, semester_id").eq("student_id", student.id).single();
  expect(data?.status).toBe("pending");
  expect(data?.semester_id).toBe(SEED.semesterId);
  expect(data?.proof_path).toMatch(new RegExp(`^${SEED.schoolId}/${student.id}/[0-9a-f]{32}\\.jpg$`));
  await expect(page.getByRole("heading", { name: "Your requests this semester" })).toBeVisible();
});

test("sees the approval arrive live and is offered the boarding code", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/subscription");
  await expect(page.getByTestId("status-card")).toContainText("Request sent");
  await page.waitForTimeout(1500); // let the live channel join
  await serviceClient().from("subscriptions").update({ status: "approved", reviewed_at: new Date().toISOString() }).eq("student_id", student.id);
  await expect(page.getByText("Your subscription was approved.")).toBeVisible();
  await expect(page.getByTestId("status-card")).toContainText("You are subscribed");
  await expect(page.getByRole("link", { name: "Show boarding code" })).toHaveAttribute("href", "/app/code");
  // The proof opens over the page at its own size, not on another page.
  await page.getByTestId("proof-thumbnail").click();
  await expect(page.getByTestId("proof-full")).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(page.getByTestId("proof-full")).toBeHidden();
});

test("after a revocation reads the school's reason and can ask again", async ({ page, context }) => {
  await serviceClient().from("subscriptions").update({ status: "revoked", review_note: "Payment was reversed by the bank." }).eq("student_id", student.id);
  await signInBrowser(context, student);
  await page.goto("/app/subscription");
  await expect(page.getByTestId("status-card")).toContainText("Subscription ended by your school");
  await expect(page.getByTestId("status-card")).toContainText("Payment was reversed by the bank.");
  await page.getByRole("link", { name: "Request again" }).click();
  await expect(page.getByRole("button", { name: "Send request" })).toBeVisible();
});
