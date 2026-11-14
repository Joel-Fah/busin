import { randomBytes } from "node:crypto";

import { expect, test } from "@playwright/test";

import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser } from "./support";

// The student web app's gates before the tabs (ADR 0021, ADR 0012): choose a school, wait for it, give your details.
const tag = randomBytes(3).toString("hex");
let outsider: TestUser;
let newcomer: TestUser;
let schoolBefore: { accepts_open_signup: boolean; open_signup_domains: string[] } | null = null;
let schoolName = "";

test.use({ viewport: { width: 390, height: 844 } });

test.beforeAll(async () => {
  const db = serviceClient();
  const { data } = await db.from("schools").select("name, accepts_open_signup, open_signup_domains").eq("id", SEED.schoolId).single();
  schoolBefore = data ? { accepts_open_signup: data.accepts_open_signup, open_signup_domains: data.open_signup_domains } : null;
  schoolName = data?.name ?? "";
  // The seed school accepts students with other emails, so a gmail account may sign up and ask.
  await db.from("schools").update({ accepts_open_signup: true, open_signup_domains: [] }).eq("id", SEED.schoolId);
  outsider = await createUser(`web-join-${tag}`, "student", "pending", "gmail.com");
  newcomer = await createUser(`web-setup-${tag}`, "student");
});

test.afterAll(async () => {
  for (const user of [outsider, newcomer]) if (user) await deleteUser(user);
  if (schoolBefore) await serviceClient().from("schools").update(schoolBefore).eq("id", SEED.schoolId);
});

test("a student without a school email chooses a school, waits, and cannot change at once", async ({ page, context }) => {
  await signInBrowser(context, outsider);
  await page.goto("/app");
  await expect(page).toHaveURL(/\/app\/join$/);
  await expect(page.getByRole("heading", { name: "Choose your school" })).toBeVisible();

  await page.getByLabel("Search for your school").fill("no such school anywhere");
  await expect(page.getByText("No school matches your search.")).toBeVisible();
  await page.getByLabel("Search for your school").fill(schoolName.slice(0, 4));
  await page.getByRole("button", { name: new RegExp(schoolName) }).click();
  await expect(page.getByRole("dialog")).toContainText(`Ask to join ${schoolName}?`);
  await page.getByRole("dialog").getByRole("button", { name: "Ask to join" }).click();

  await expect(page).toHaveURL(/\/app\/waiting$/);
  await expect(page.getByRole("heading", { name: `Waiting for ${schoolName}` })).toBeVisible();
  const { data } = await serviceClient().from("profiles").select("school_id, status").eq("id", outsider.id).single();
  expect(data).toEqual({ school_id: SEED.schoolId, status: "pending" });

  // The server allows one change every 30 seconds.
  await page.getByRole("button", { name: "Choose another school" }).click();
  await expect(page.getByText("Wait a few seconds before changing your request.")).toBeVisible();
  await expect(page).toHaveURL(/\/app\/waiting$/);

  // Accepted meanwhile: checking again sends them on (to give their details).
  await serviceClient().from("profiles").update({ status: "verified" }).eq("id", outsider.id);
  await page.getByRole("button", { name: "Check again" }).click();
  await expect(page).toHaveURL(/\/app\/setup$/);
});

test("a verified student gives the details the school needs before the tabs", async ({ page, context }) => {
  await signInBrowser(context, newcomer);
  await page.goto("/app/code");
  await expect(page).toHaveURL(/\/app\/setup$/);
  await expect(page.getByText(`You are joining ${schoolName}`)).toBeVisible();
  // The school's lists come in the order program, faculty, department.
  const top = async (label: string) => (await page.getByText(label, { exact: true }).first().boundingBox())!.y;
  expect(await top("Program")).toBeLessThan(await top("Faculty"));
  expect(await top("Faculty")).toBeLessThan(await top("Department"));

  await page.getByLabel("Full name").fill("A");
  await page.getByLabel("Student number").fill("");
  await page.getByLabel("Phone number").fill("67 12");
  await page.getByRole("button", { name: "Save and continue" }).click();
  await expect(page.getByText("That looks too short.").first()).toBeVisible();
  await expect(page.getByText("This field is required.")).toBeVisible();

  await page.getByLabel("Full name").fill("Amara Ngono");
  await page.getByLabel("Student number").fill(`ICT2026-${tag}`);
  await page.getByLabel("Phone number").fill("+237 677 12 34 56");
  await page.getByRole("button", { name: "Save and continue" }).click();
  // My area is offered once, right after setup (ADR 0023); "Not now" goes on to the subscription.
  await expect(page).toHaveURL(/\/app\/settings\/area\?intro=1$/);
  await expect(page.getByRole("heading", { name: "One more thing: where do you live?" })).toBeVisible();
  await page.getByRole("link", { name: "Not now" }).click();
  await expect(page).toHaveURL(/\/app\/subscription$/);
  await expect(page.getByTestId("area-offer")).toHaveCount(0);

  const { data } = await serviceClient().from("profiles").select("full_name, matricule, phone").eq("id", newcomer.id).single();
  expect(data).toEqual({ full_name: "Amara Ngono", matricule: `ICT2026-${tag}`, phone: "+237677123456" });
});
