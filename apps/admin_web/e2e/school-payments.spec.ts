import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import {
  SEED,
  activePayoutAccounts,
  createSubscription,
  createUser,
  deleteLedgerRowsByNote,
  deletePaymentsOf,
  deleteUser,
  restorePayoutAccounts,
  schoolBalance,
  serviceClient,
  setMobileMoney,
  signInBrowser,
  userClient,
  type TestUser,
} from "./support";

// The school's payment screens (ADR 0029): who pays the fees and the breakdown on Billing, the Payments page (balance,
// refunds to decide, payments, payout number, invoices, the ledger export) and mobile money on a subscription. Payments
// and refunds are written with the service role as pawaPay's results would leave them; ledger lines this test adds carry
// its own note and are removed at the end.
const tag = randomBytes(3).toString("hex");
const NOTE = `e2e-pay-${tag}`;
let admin: TestUser;
let colleague: TestUser;
let partStudent: TestUser;
let declineStudent: TestUser;
let waitingStudent: TestUser;
let wasOn = false;
let activeBefore: string[] = [];
let schoolBefore: { fees_paid_by: string; price_xaf: number | null } | null = null;
let partRefund = "";
let declineRefund = "";
let declineSubscription = "";
let waitingSubscription = "";
let invoiceId = "";

test.describe.configure({ mode: "serial" });

/** An approved subscription paid by mobile money: the payment as pawaPay completed it, and its line in the ledger. */
async function paidSubscription(student: TestUser, amount: number, n: number): Promise<{ subscription: string; payment: string }> {
  const db = serviceClient();
  const subscription = await createSubscription(student.id, SEED.stopId, false);
  await db.from("subscriptions").update({ payment_method: "mobile_money", status: "approved", reviewed_at: new Date().toISOString() }).eq("id", subscription);
  const { data, error } = await db
    .from("payments")
    .insert({
      school_id: SEED.schoolId,
      paid_by: student.id,
      purpose: "subscription",
      subscription_id: subscription,
      item_key: `subscription:${subscription}`,
      amount_xaf: amount,
      fee_xaf: 300,
      provider: "MTN_MOMO_CMR",
      payer_masked: "2376*****456",
      status: "completed",
      outcome: "applied",
      receipt_no: `BI-E2E-${tag}-${n}`,
      completed_at: new Date().toISOString(),
    })
    .select("id")
    .single();
  if (error || !data) throw new Error(`could not create a payment: ${error?.message}`);
  await db.from("school_ledger").insert({ school_id: SEED.schoolId, kind: "payment", amount_xaf: amount, payment_id: data.id, available_at: new Date(Date.now() + 7 * 86_400_000).toISOString() });
  return { subscription, payment: data.id };
}

async function askRefund(student: TestUser, payment: string, amount: number, reason: string): Promise<string> {
  const { data, error } = await serviceClient()
    .from("refunds")
    .insert({ school_id: SEED.schoolId, payment_id: payment, student_id: student.id, kind: "student", reason, amount_xaf: amount, status: "requested", requested_by: student.id })
    .select("id")
    .single();
  if (error || !data) throw new Error(`could not ask for a refund: ${error?.message}`);
  return data.id;
}

test.beforeAll(async () => {
  wasOn = setMobileMoney(SEED.schoolId, true);
  activeBefore = activePayoutAccounts(SEED.schoolId);
  const db = serviceClient();
  const { data: school } = await db.from("schools").select("fees_paid_by, price_xaf").eq("id", SEED.schoolId).single();
  schoolBefore = school;

  admin = await createUser(`pay-admin-${tag}`, "admin");
  colleague = await createUser(`pay-admin2-${tag}`, "admin");
  partStudent = await createUser(`pay-part-${tag}`, "student");
  declineStudent = await createUser(`pay-decline-${tag}`, "student");
  waitingStudent = await createUser(`pay-wait-${tag}`, "student");
  await db.from("profiles").update({ full_name: "Amara Ngono", matricule: `PAY1${tag}` }).eq("id", partStudent.id);
  await db.from("profiles").update({ full_name: "Brice Ekane", matricule: `PAY2${tag}` }).eq("id", declineStudent.id);
  await db.from("profiles").update({ full_name: "Chantal Mbia", matricule: `PAY3${tag}` }).eq("id", waitingStudent.id);

  const a = await paidSubscription(partStudent, 30000, 1);
  const b = await paidSubscription(declineStudent, 30000, 2);
  declineSubscription = b.subscription;
  partRefund = await askRefund(partStudent, a.payment, 30000, "I moved to another campus and no longer take the bus.");
  declineRefund = await askRefund(declineStudent, b.payment, 30000, "I would like my money back for the semester please.");

  // A request the student chose to pay by mobile money, not paid yet.
  waitingSubscription = await createSubscription(waitingStudent.id, SEED.stopId, false);
  await db.from("subscriptions").update({ payment_method: "mobile_money" }).eq("id", waitingSubscription);

  // Balance lines of this test: some available now, some still on hold.
  const { error: ledgerError } = await db.from("school_ledger").insert([
    { school_id: SEED.schoolId, kind: "adjustment", amount_xaf: 12345, note: NOTE, available_at: new Date().toISOString() },
    { school_id: SEED.schoolId, kind: "adjustment", amount_xaf: 6789, note: NOTE, available_at: new Date(Date.now() + 3 * 86_400_000).toISOString() },
  ]);
  if (ledgerError) throw new Error(`could not write the ledger: ${ledgerError.message}`);

  // An invoice from BusIn, in a month long past so it never meets a real one.
  const { data: invoice, error } = await db
    .from("busin_invoices")
    .insert({ school_id: SEED.schoolId, number: `BF-E2E-${tag}`, month: "2020-01-01", amount_xaf: 1400, due_date: "2020-01-15" })
    .select("id")
    .single();
  if (error || !invoice) throw new Error(`could not create an invoice: ${error?.message}`);
  invoiceId = invoice.id;
});

test.afterAll(async () => {
  const db = serviceClient();
  setMobileMoney(SEED.schoolId, wasOn);
  if (schoolBefore) await db.from("schools").update(schoolBefore).eq("id", SEED.schoolId);
  deleteLedgerRowsByNote(NOTE);
  if (invoiceId) {
    await db.from("payments").delete().eq("invoice_id", invoiceId);
    await db.from("busin_invoices").delete().eq("id", invoiceId);
  }
  restorePayoutAccounts([admin, colleague].filter(Boolean).map((u) => u.id), activeBefore);
  for (const user of [partStudent, declineStudent, waitingStudent]) {
    if (!user) continue;
    deletePaymentsOf(user.id);
    await deleteUser(user);
  }
  for (const user of [admin, colleague]) if (user) await deleteUser(user);
});

test("Billing: who pays the fees is saved, and the breakdown follows the price as it is typed", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/billing");
  await expect(page.getByRole("heading", { name: "Who pays the fees?" })).toBeVisible();
  await expect(page.getByTestId("price-breakdown")).toBeVisible();

  await page.getByRole("radio", { name: /^The school/ }).check();
  await expect(page.getByText("Saved: the school pays the fees.")).toBeVisible();
  await expect.poll(async () => (await serviceClient().from("schools").select("fees_paid_by").eq("id", SEED.schoolId).single()).data?.fees_paid_by).toBe("school");

  await page.getByRole("radio", { name: /^Students/ }).check();
  await expect(page.getByText("Saved: students pay the fees.")).toBeVisible();

  // The figures come from the database, for the typed price, before it is saved.
  await page.getByLabel("Price of one period, in XAF").fill("25000");
  const mine = await userClient(admin);
  const { data: expected } = await mine.rpc("price_breakdown", { p_price: 25000 });
  const receipt = expected!.find((r) => r.method === "receipt")!;
  const breakdown = page.getByTestId("price-breakdown");
  const receiptRow = breakdown.getByRole("row", { name: /Receipt/ });
  await expect(receiptRow).toContainText(`${receipt.student_pays.toLocaleString("en")} XAF`);
  await expect(receiptRow).toContainText(`${receipt.school_receives.toLocaleString("en")} XAF`);
  const mtn = expected!.find((r) => r.method === "MTN_MOMO_CMR");
  if (mtn) await expect(breakdown.getByRole("row", { name: /MTN Mobile Money/ })).toContainText(`${mtn.student_pays.toLocaleString("en")} XAF`);

  await page.getByLabel("Price of one period, in XAF").fill("");
  await expect(page.getByText("Type a price to see the breakdown.")).toBeVisible();
  // Nothing was saved: the price is still the school's.
  const { data: school } = await serviceClient().from("schools").select("price_xaf").eq("id", SEED.schoolId).single();
  expect(school?.price_xaf).toBe(schoolBefore?.price_xaf);
});

test("Payments: the tiles show the balance, and the open invoice offers mobile money", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/profile");
  await page.getByRole("link", { name: /^Payments/ }).click();
  await expect(page).toHaveURL(/\/payments$/);
  await expect(page.getByRole("heading", { name: "Payments", level: 1 })).toBeVisible();

  const balance = schoolBalance(SEED.schoolId);
  expect(balance.available).toBeGreaterThanOrEqual(12345);
  expect(balance.onHold).toBeGreaterThanOrEqual(6789);
  await expect(page.getByTestId("tile-available")).toContainText(`${balance.available.toLocaleString("en")} XAF`);
  await expect(page.getByTestId("tile-on-hold")).toContainText(`${balance.onHold.toLocaleString("en")} XAF`);
  await expect(page.getByTestId("tile-on-hold")).toContainText("Available 7 days after each payment.");
  await expect(page.getByTestId("tile-payout")).toBeVisible();
  await expect(page.getByTestId("months")).toContainText("This month");

  // The payments list shows the two paid requests with their receipts.
  const list = page.locator("#payments-list");
  await expect(list.getByRole("row", { name: new RegExp(`BI-E2E-${tag}-1`) })).toContainText("Amara Ngono");
  await list.getByRole("link", { name: /Waiting/ }).click();
  await expect(page).toHaveURL(/status=waiting/);
  await expect(list.getByRole("row", { name: new RegExp(`BI-E2E-${tag}`) })).toHaveCount(0);

  // BusIn's invoice: the number, the network it is on, and a refusal when mobile money is not reachable (no key locally).
  const invoices = page.getByTestId("invoices");
  await expect(invoices).toContainText(`BF-E2E-${tag}`);
  await invoices.getByLabel("Mobile money number").fill("6 77 12 34 56");
  await expect(invoices.getByRole("radio", { name: "MTN Mobile Money" })).toBeChecked();
  await invoices.getByRole("button", { name: /^Pay/ }).click();
  await expect(invoices.getByText("Mobile money is not available right now.")).toBeVisible();
});

test("refunds: approving part of one, and declining another with a reason", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/payments");
  const waiting = page.getByTestId("refunds-to-decide");
  await expect(waiting).toContainText("Amara Ngono");
  await expect(waiting).toContainText("Brice Ekane");

  // Part of it.
  await waiting.getByRole("listitem").filter({ hasText: "Amara Ngono" }).getByRole("button", { name: "Decide" }).click();
  const sheet = page.getByTestId("refund-sheet").filter({ visible: true });
  await sheet.getByRole("radio", { name: "Refund part of it" }).check();
  await sheet.getByLabel("Amount to refund, in XAF").fill("10 000");
  await sheet.getByRole("button", { name: "Refund this amount" }).click();
  await expect(page.getByText("Refund approved.")).toBeVisible();
  await expect.poll(async () => (await serviceClient().from("refunds").select("status, amount_xaf").eq("id", partRefund).single()).data).toEqual({ status: "queued", amount_xaf: 10000 });

  // Declined, with a reason the student reads; too short first.
  await page.getByTestId("refunds-to-decide").getByRole("listitem").filter({ hasText: "Brice Ekane" }).getByRole("button", { name: "Decide" }).click();
  const second = page.getByTestId("refund-sheet").filter({ visible: true });
  await second.getByRole("radio", { name: "Decline" }).check();
  const note = second.getByLabel("Why you decline");
  await note.evaluate((el) => (el as HTMLTextAreaElement).removeAttribute("minlength"));
  await note.fill("no");
  await second.getByRole("button", { name: "Decline the refund" }).click();
  await expect(second.getByText("Write at least 10 characters.")).toBeVisible();
  await note.fill("The refund period has ended for this semester.");
  await second.getByRole("button", { name: "Decline the refund" }).click();
  await expect(page.getByText("Refund declined.")).toBeVisible();
  await expect
    .poll(async () => (await serviceClient().from("refunds").select("status, decision_note").eq("id", declineRefund).single()).data)
    .toEqual({ status: "declined", decision_note: "The refund period has ended for this semester." });

  await expect(page.getByTestId("refunds-to-decide")).toHaveCount(0);
  const recent = page.getByTestId("recent-refunds");
  await expect(recent.getByRole("listitem").filter({ hasText: "Brice Ekane" })).toContainText("Declined");
  await expect(recent.getByRole("listitem").filter({ hasText: "Amara Ngono" })).toContainText("Being sent");
});

test("payout number: proposed by one administrator, refused to the same one, confirmed by another", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/payments");
  const card = page.getByTestId("payout-account");
  await card.getByRole("button", { name: /payout number|Change the number/ }).click();
  const sheet = page.getByTestId("payout-sheet");
  await sheet.getByLabel("Mobile money number").fill("6 99 12 34 56");
  await expect(sheet.getByRole("radio", { name: "Orange Money" })).toBeChecked();
  await sheet.getByLabel("Account holder's name").fill("ICT University Transport");
  await sheet.getByRole("button", { name: "Propose this number" }).click();
  await expect(page.getByText("Number proposed.")).toBeVisible();

  const proposal = page.getByTestId("payout-proposal");
  await expect(proposal).toContainText("+2376*****456");
  await expect(proposal).toContainText("Proposed by you");
  await expect(proposal.getByRole("button", { name: "Confirm this number" })).toHaveCount(0);
  await expect(proposal).toContainText("Another administrator must confirm it.");

  // The database refuses the same administrator even past the page.
  const { data: row } = await serviceClient().from("school_payout_accounts").select("id").eq("proposed_by", admin.id).eq("status", "proposed").single();
  const mine = await userClient(admin);
  const { error } = await mine.rpc("admin_confirm_payout_account", { p_account: row!.id });
  expect(error?.message).toBe("same_admin");

  // Another administrator confirms it.
  await context.clearCookies();
  await signInBrowser(context, colleague);
  await page.goto("/payments");
  await page.getByTestId("payout-proposal").getByRole("button", { name: "Confirm this number" }).click();
  await page.getByRole("dialog", { name: "Confirm this payout number?" }).getByRole("button", { name: "Confirm this number" }).click();
  await expect(page.getByText("Payout number confirmed.")).toBeVisible();
  await expect(page.getByTestId("payout-proposal")).toHaveCount(0);
  await expect(page.getByTestId("payout-account")).toContainText("+2376*****456");
  await expect(page.getByTestId("payout-account")).toContainText("ICT University Transport");
  const { data: confirmed } = await serviceClient().from("school_payout_accounts").select("status, confirmed_by").eq("id", row!.id).single();
  expect(confirmed).toEqual({ status: "active", confirmed_by: colleague.id });
});

test("the ledger downloads as CSV with its header and the school's rows", async ({ page, context }) => {
  await signInBrowser(context, admin);
  const response = await page.request.get("/payments/export");
  expect(response.status()).toBe(200);
  expect(response.headers()["content-type"]).toContain("text/csv");
  expect(response.headers()["content-disposition"]).toMatch(/attachment; filename="busin-ledger-[a-z0-9-]+-\d{4}-\d{2}-\d{2}\.csv"/);
  const body = (await response.body()).toString("utf8");
  expect(body.startsWith("﻿Date,Movement,Amount (XAF),Available from,Payment receipt,Refund receipt,Note\r\n")).toBe(true);
  expect(body).toMatch(new RegExp(`,Adjustment,12345,[^,]*,,,${NOTE}\\r\\n`));
  expect(body).toContain(`,Payment,30000,`);
  expect(body).toContain(`BI-E2E-${tag}-1`);
});

test("Subscriptions: a request waiting for mobile money says so, and a paid one can be refunded", async ({ page, context }) => {
  await signInBrowser(context, admin);
  await page.goto("/subscriptions?q=Chantal");
  await expect(page.getByRole("row", { name: /Chantal Mbia/ })).toContainText("Mobile money");

  await page.goto(`/subscriptions/${waitingSubscription}`);
  await expect(page.getByTestId("momo-state")).toContainText("Waiting for mobile money payment");
  await expect(page.getByRole("button", { name: "Approve" })).toBeDisabled();

  // While a payment is going through, deciding is refused.
  const { error } = await serviceClient()
    .from("payments")
    .insert({
      school_id: SEED.schoolId,
      paid_by: waitingStudent.id,
      purpose: "subscription",
      subscription_id: waitingSubscription,
      item_key: `subscription:${waitingSubscription}`,
      amount_xaf: 30000,
      fee_xaf: 300,
      provider: "MTN_MOMO_CMR",
      payer_masked: "2376*****456",
    });
  expect(error).toBeNull();
  await page.reload();
  await expect(page.getByTestId("momo-state")).toContainText("A payment is going through now.");
  await page.getByText("Reject with a reason").click();
  await page.getByLabel("Reason for rejection").fill("The receipt is for a different semester.");
  await page.getByRole("button", { name: "Confirm rejection" }).click();
  await expect(page.getByRole("alert").filter({ hasText: "A mobile money payment for this request is going through now." })).toBeVisible();

  // The declined refund left Brice's payment refundable: the school refunds part of it itself.
  await page.goto(`/subscriptions/${declineSubscription}`);
  const momo = page.getByTestId("momo-payments");
  await expect(momo).toContainText("Paid by mobile money");
  await expect(momo).toContainText(`Receipt BI-E2E-${tag}-2`);
  await momo.getByRole("button", { name: "Refund" }).click();
  const sheet = page.getByTestId("school-refund-sheet");
  await sheet.getByLabel("Amount to refund, in XAF").fill("5000");
  await sheet.getByRole("textbox", { name: "Why you refund it" }).fill("The student stopped using the bus.");
  await sheet.getByRole("button", { name: "Refund this amount" }).click();
  await expect(page.getByText("Refund sent.")).toBeVisible();
  const { data: refunds } = await serviceClient().from("refunds").select("kind, status, amount_xaf").eq("student_id", declineStudent.id).eq("kind", "school");
  expect(refunds).toEqual([{ kind: "school", status: "queued", amount_xaf: 5000 }]);
  await expect(page.getByTestId("momo-payments")).toContainText("Refund being sent: 5,000 XAF");
});
