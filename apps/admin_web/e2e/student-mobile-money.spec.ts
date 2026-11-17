import { randomBytes } from "node:crypto";

import { expect, test, type Page } from "@playwright/test";

import { SEED, createUser, deletePaymentsOf, deleteUser, serviceClient, setMobileMoney, signInBrowser, userClient, type TestUser } from "./support";

// Paying by mobile money in the student web app (ADR 0029). The local stack has no pawaPay key, so starting a payment is
// refused as "not available" and the request stays waiting; a payment that goes through is opened with start_payment as
// the student and settled with the service role, as pawaPay's callback would.
const tag = randomBytes(3).toString("hex");
let student: TestUser;
let failing: TestUser;
let parts: TestUser;
let wasOn = false;
const PNG = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==", "base64");

test.use({ viewport: { width: 390, height: 844 } });
test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  wasOn = setMobileMoney(SEED.schoolId, false);
  student = await createUser(`web-momo-${tag}`, "student");
  failing = await createUser(`web-momo-f-${tag}`, "student");
  await serviceClient().from("profiles").update({ matricule: `MOM1${tag}`, phone: "+237677123456", full_name: "Amara Ngono" }).eq("id", student.id);
  await serviceClient().from("profiles").update({ matricule: `MOM2${tag}`, phone: "+237699123456", full_name: "Brice Ekane" }).eq("id", failing.id);
  parts = await createUser(`web-momo-p-${tag}`, "student");
  await serviceClient().from("profiles").update({ matricule: `MOM3${tag}`, phone: "+237650123456", full_name: "Chantal Mbia" }).eq("id", parts.id);
});

test.afterAll(async () => {
  setMobileMoney(SEED.schoolId, wasOn);
  const db = serviceClient();
  for (const user of [student, failing, parts]) {
    if (!user) continue;
    const { data } = await db.storage.from("proofs").list(`${SEED.schoolId}/${user.id}`);
    if (data?.length) await db.storage.from("proofs").remove(data.map((f) => `${SEED.schoolId}/${user.id}/${f.name}`));
    deletePaymentsOf(user.id);
    await deleteUser(user);
  }
});

async function chooseStop(page: Page) {
  const { data } = await serviceClient().from("stops").select("name").eq("id", SEED.stopId).single();
  await page.getByRole("button", { name: /Your stop/ }).click();
  await page.getByRole("dialog").getByLabel("Search stops").fill(data!.name.slice(0, 5));
  await page.getByRole("dialog").getByRole("button", { name: data!.name }).click();
}

test("offers only the receipt while the school does not take mobile money", async ({ page, context }) => {
  await signInBrowser(context, student);
  await page.goto("/app/subscription");
  await expect(page.getByText("Subscribe for Fall 2026")).toBeVisible();
  await expect(page.getByRole("button", { name: "Send request" })).toBeVisible();
  await expect(page.getByRole("radiogroup", { name: "How will you pay?" })).toHaveCount(0);
  await expect(page.getByTestId("momo-number")).toHaveCount(0);
});

test("pays by mobile money by default: the number, its network, the price, then waits when mobile money is down", async ({ page, context }) => {
  setMobileMoney(SEED.schoolId, true);
  await signInBrowser(context, student);
  await page.goto("/app/subscription");
  await expect(page.getByRole("radio", { name: "Mobile money" })).toHaveAttribute("aria-checked", "true");
  await expect(page.getByRole("radio", { name: "Upload a receipt" })).toHaveAttribute("aria-checked", "false");
  // No receipt field with mobile money; the profile's number, its network recognised.
  await expect(page.getByTestId("proof-input")).toHaveCount(0);
  const number = page.getByLabel("Mobile money number");
  await expect(number).toHaveValue("6 77 12 34 56");
  await expect(page.getByTestId("operator-badge")).toContainText("MTN Mobile Money");

  // The network follows the number as it is typed, and can be changed.
  await number.fill("699 12 34 56");
  await expect(page.getByTestId("operator-badge")).toContainText("Orange Money");
  await page.getByRole("button", { name: "Change" }).click();
  await page.getByRole("radiogroup", { name: "Network" }).getByRole("radio", { name: /MTN Mobile Money/ }).click();
  await expect(page.getByTestId("operator-badge")).toContainText("MTN Mobile Money");
  await number.fill("6 77 12 34 56");

  // What paying comes to, from the school's price breakdown.
  const db = await userClient(student);
  const { data: breakdown } = await db.rpc("price_breakdown", {});
  const mtn = breakdown!.find((r) => r.method === "MTN_MOMO_CMR")!;
  const receipt = breakdown!.find((r) => r.method === "receipt")!;
  await expect(page.getByTestId("price-total")).toContainText(`${mtn.student_pays.toLocaleString("en")} XAF`);
  if (mtn.student_pays > receipt.student_pays) await expect(page.getByTestId("price-fee")).toContainText(`${(mtn.student_pays - receipt.student_pays).toLocaleString("en")} XAF`);

  // A number that is not a Cameroonian mobile one is said so, and nothing can be sent.
  await chooseStop(page);
  await number.fill("2 22 12 34");
  await number.blur();
  await expect(page.getByText("Enter a Cameroonian mobile number, like 6 77 12 34 56.")).toBeVisible();
  await expect(page.getByRole("button", { name: "Send and pay" })).toBeDisabled();
  await number.fill("6 77 12 34 56");

  await page.getByRole("button", { name: "Send and pay" }).click();
  // No pawaPay key locally: the request is made without a receipt, and waits.
  await expect(page.getByTestId("status-card")).toContainText("Waiting for your payment");
  await expect(page.getByText("Mobile money is not available right now. You can upload a receipt instead.")).toBeVisible();
  await expect(page.getByRole("button", { name: "Send a receipt instead" })).toBeVisible();
  const { data: sub } = await serviceClient().from("subscriptions").select("status, proof_path, payment_method").eq("student_id", student.id).single();
  expect(sub).toMatchObject({ status: "pending", proof_path: null, payment_method: "mobile_money" });

  // After a reload the request offers to pay again.
  await page.reload();
  await expect(page.getByTestId("status-card")).toContainText("Waiting for your payment");
  await expect(page.getByTestId("momo-form")).toContainText("Pay now");
  await expect(page.getByLabel("Mobile money number")).toHaveValue("6 77 12 34 56");
});

test("follows a payment and shows it paid, with its receipt", async ({ page, context }) => {
  const db = serviceClient();
  const { data: sub } = await db.from("subscriptions").select("id").eq("student_id", student.id).single();
  const mine = await userClient(student);
  const { data: started, error } = await mine.rpc("start_payment", { p_purpose: "subscription", p_target: sub!.id, p_provider: "MTN_MOMO_CMR", p_phone: "237677123456" });
  expect(error).toBeNull();
  const payment = started![0];

  await signInBrowser(context, student);
  await page.goto("/app/subscription");
  await expect(page.getByTestId("momo-waiting")).toContainText("Check your phone");
  await expect(page.getByTestId("momo-waiting")).toContainText(`${payment.total_xaf.toLocaleString("en")} XAF`);
  await expect(page.getByTestId("momo-waiting")).toContainText("+2376*****456");
  await page.waitForTimeout(1500); // let the live channel join

  const txn = `e2e-${tag}`;
  const { error: settled } = await db.rpc("settle_payment", { p_id: payment.id, p_status: "COMPLETED", p_amount: String(payment.total_xaf), p_currency: "XAF", p_provider_txn: txn });
  expect(settled).toBeNull();
  await expect(page.getByTestId("status-card")).toContainText("You are subscribed", { timeout: 30_000 });
  const receipt = page.getByTestId("payment-receipt");
  await expect(receipt).toContainText(/Receipt BI-\d{4}-\d{6}/);
  await expect(receipt).toContainText("Paid");
  await expect(receipt).toContainText(`${payment.total_xaf.toLocaleString("en")} XAF`);
  await expect(receipt).toContainText("MTN Mobile Money");
  await expect(receipt).toContainText("+2376*****456");
  await expect(receipt).toContainText(txn);
});

test("after a failed payment says why, that nothing was taken, and takes a receipt instead", async ({ page, context }) => {
  setMobileMoney(SEED.schoolId, true);
  const mine = await userClient(failing);
  const { data: sub, error } = await mine
    .from("subscriptions")
    .insert({ school_id: SEED.schoolId, student_id: failing.id, semester_id: SEED.semesterId, stop_id: SEED.stopId, payment_mode: "full", payment_method: "mobile_money" })
    .select("id")
    .single();
  expect(error).toBeNull();
  const { data: started } = await mine.rpc("start_payment", { p_purpose: "subscription", p_target: sub!.id, p_provider: "ORANGE_CMR", p_phone: "237699123456" });
  await serviceClient().rpc("settle_payment", { p_id: started![0].id, p_status: "FAILED", p_failure_code: "INSUFFICIENT_BALANCE", p_failure_message: "staff only" });

  await signInBrowser(context, failing);
  await page.goto("/app/subscription");
  const failed = page.getByTestId("momo-failed");
  await expect(failed).toContainText("The payment did not go through");
  await expect(failed).toContainText("There is not enough money in this account.");
  await expect(failed).toContainText("Nothing was taken from your account.");
  await expect(page.getByText("staff only")).toHaveCount(0);

  // Try again opens the form with the student's number and its network.
  await failed.getByRole("button", { name: "Try again" }).click();
  await expect(page.getByLabel("Mobile money number")).toHaveValue("6 99 12 34 56");
  await expect(page.getByTestId("operator-badge")).toContainText("Orange Money");

  await page.getByTestId("receipt-instead-input").setInputFiles({ name: "receipt.png", mimeType: "image/png", buffer: PNG });
  await expect(page.getByTestId("status-card")).toContainText("Request sent");
  const { data: now } = await serviceClient().from("subscriptions").select("status, proof_path, payment_method").eq("id", sub!.id).single();
  expect(now?.status).toBe("pending");
  expect(now?.payment_method).toBe("receipt");
  expect(now?.proof_path).toMatch(new RegExp(`^${SEED.schoolId}/${failing.id}/[0-9a-f]{32}\\.jpg$`));
});

test("pays a later installment part by mobile money, and lists its receipt", async ({ page, context }) => {
  setMobileMoney(SEED.schoolId, true);
  const db = serviceClient();
  // An approved request paid in installments (the seed school's 40-30-30 plan): part 2 is due.
  const { data: sub, error } = await db
    .from("subscriptions")
    .insert({ school_id: SEED.schoolId, student_id: parts.id, semester_id: SEED.semesterId, stop_id: SEED.stopId, payment_mode: "installments", proof_path: `${SEED.schoolId}/${parts.id}/e2e-proof.jpg` })
    .select("id")
    .single();
  expect(error).toBeNull();
  await db.from("subscriptions").update({ status: "approved", reviewed_at: new Date().toISOString() }).eq("id", sub!.id);
  const { data: part } = await db.from("subscription_installments").select("id, amount_xaf").eq("subscription_id", sub!.id).eq("seq", 2).single();

  await signInBrowser(context, parts);
  await page.goto("/app/subscription");
  const second = page.getByTestId("part-2");
  await expect(second.getByRole("button", { name: "Send proof of payment" })).toBeVisible();
  await second.getByRole("button", { name: "Pay with mobile money" }).click();
  await expect(second.getByLabel("Mobile money number")).toHaveValue("6 50 12 34 56");
  await expect(second.getByTestId("operator-badge")).toContainText("MTN Mobile Money");
  const { data: quote } = await (await userClient(parts)).rpc("payment_quote", { p_purpose: "installment", p_target: part!.id, p_provider: "MTN_MOMO_CMR" });
  await expect(second.getByTestId("price-total")).toContainText(`${quote![0].total_xaf.toLocaleString("en")} XAF`);
  await second.getByRole("button", { name: /^Pay / }).click();
  await expect(second.getByText("Mobile money is not available right now. You can upload a receipt instead.")).toBeVisible();

  // Paid from the phone (opened as the student, settled as pawaPay's callback would): the part is paid, with its receipt.
  const { data: started } = await (await userClient(parts)).rpc("start_payment", { p_purpose: "installment", p_target: part!.id, p_provider: "MTN_MOMO_CMR", p_phone: "237650123456" });
  await page.reload();
  await expect(second.getByTestId("momo-waiting")).toContainText("Check your phone");
  await expect(second.getByRole("button", { name: "Send proof of payment" })).toHaveCount(0);
  await page.waitForTimeout(1500); // let the live channel join
  await db.rpc("settle_payment", { p_id: started![0].id, p_status: "COMPLETED", p_amount: String(started![0].total_xaf), p_currency: "XAF" });
  await expect(second).toContainText("Paid", { timeout: 30_000 });
  await expect(page.getByTestId("payment-receipt")).toContainText("Part 2");
  await expect(page.getByTestId("payment-receipt")).toContainText(`${started![0].total_xaf.toLocaleString("en")} XAF`);
});
