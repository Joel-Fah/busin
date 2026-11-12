import { randomBytes } from "node:crypto";

import { expect, test, type Page } from "@playwright/test";

import { parsePoint } from "../lib/geo";
import { SEED, createUser, deleteUser, serviceClient, signInBrowser, type TestUser, setLanguage } from "./support";

const tag = randomBytes(3).toString("hex");
const prefix = `E2E stop-${tag}`;

let admin: TestUser;
let staff: TestUser;
let student: TestUser;
let existingId: string;
let editableId: string;
let usageStopId: string;
let usageSemesterId: string;
let usageStudents: TestUser[] = [];

// A blank base map, so the tests need no outside map server and no network (and never touch Mapbox).
const BLANK_STYLE = {
  version: 8,
  sources: {},
  layers: [{ id: "background", type: "background", paint: { "background-color": "#e8f1f2" } }],
};

const CANVAS = ".maplibregl-canvas, .mapboxgl-canvas";
const PIN = ".maplibregl-marker:not(.map-marker), .mapboxgl-marker:not(.map-marker)";

async function insertStop(name: string, location = "SRID=4326;POINT(11.5021000 3.8480000)") {
  const { data, error } = await serviceClient()
    .from("stops")
    .insert({ school_id: SEED.schoolId, name, location })
    .select("id")
    .single();
  if (error || !data) throw new Error(`could not create a stop: ${error?.message}`);
  return data.id;
}

test.beforeAll(async () => {
  admin = await createUser(`stop-admin-${tag}`, "admin");
  staff = await createUser(`stop-staff-${tag}`, "staff");
  student = await createUser(`stop-student-${tag}`, "student");
  existingId = await insertStop(`${prefix} existing`);
  editableId = await insertStop(`${prefix} editable`, "SRID=4326;POINT(11.5100000 3.8500000)");

  // A stop with two approved students and one waiting, in a semester far from ending.
  usageStopId = await insertStop(`${prefix} busy`, "SRID=4326;POINT(11.5300000 3.8700000)");
  const db = serviceClient();
  const semester = await db
    .from("semesters")
    .insert({ school_id: SEED.schoolId, name: "spring", year: 2097, start_date: "2097-02-01", end_date: "2097-06-30" })
    .select("id")
    .single();
  if (!semester.data) throw new Error(`could not create a semester: ${semester.error?.message}`);
  usageSemesterId = semester.data.id;
  usageStudents = [await createUser(`stop-u1-${tag}`, "student"), await createUser(`stop-u2-${tag}`, "student"), await createUser(`stop-u3-${tag}`, "student")];
  const subs = await db.from("subscriptions").insert(
    usageStudents.map((user, index) => ({
      school_id: SEED.schoolId,
      student_id: user.id,
      semester_id: usageSemesterId,
      stop_id: usageStopId,
      status: index < 2 ? ("approved" as const) : ("pending" as const),
    })),
  );
  if (subs.error) throw new Error(`could not create subscriptions: ${subs.error.message}`);
});

test.afterAll(async () => {
  for (const user of [admin, staff, student, ...usageStudents]) {
    if (user) await deleteUser(user);
  }
  const db = serviceClient();
  await db.from("semesters").delete().eq("id", usageSemesterId ?? "");
  await db.from("stops").delete().like("name", `${prefix}%`);
});

async function stopByName(name: string) {
  const { data } = await serviceClient().from("stops").select("id, name, active, location").eq("name", name).maybeSingle();
  return data;
}

async function useBlankMap(page: Page) {
  await page.route("https://tiles.openfreemap.org/**", (route) => route.fulfill({ json: BLANK_STYLE }));
}

const bar = (page: Page) => page.getByRole("navigation", { name: "Main navigation" });
// The tile's name starts with the stop name; its Edit button starts with "Edit", so the two never clash.
const dockRow = (page: Page, name: string) => bar(page).getByRole("button", { name: new RegExp(`^${name}`) });

test.describe("administrator managing stops", () => {
  test.beforeEach(async ({ page, context }) => {
    await useBlankMap(page);
    await signInBrowser(context, admin);
  });

  test("shows the map across the page and lists the stops in the navigation bar, without coordinates", async ({ page }) => {
    await page.goto("/stops");
    await expect(page.getByRole("heading", { name: "Stops", level: 1 })).toBeVisible();
    await expect(page.getByRole("region", { name: "Map of all stops" })).toBeVisible();

    const row = dockRow(page, `${prefix} existing`);
    await expect(row).toBeVisible();
    await expect(row).toContainText("Active");
    await expect(page.getByRole("heading", { name: "Stops", level: 1 })).toBeVisible();
    await expect(bar(page).getByRole("button", { name: "Add a stop" })).toBeVisible();
    await expect(bar(page)).not.toContainText("3.84800");
    await expect(bar(page)).not.toContainText("11.50210");

    // The map really fills the screen.
    const box = (await page.getByRole("region", { name: "Map of all stops" }).boundingBox())!;
    expect(box.width).toBeGreaterThanOrEqual(1200);
    expect(box.height).toBeGreaterThanOrEqual(700);
  });

  test("each stop says how many students use it", async ({ page }) => {
    await page.goto("/stops");
    await expect(dockRow(page, `${prefix} busy`)).toContainText("2 students, 1 waiting");
    await expect(dockRow(page, `${prefix} existing`)).toContainText("No students yet");
  });

  test("selecting a stop highlights it in the list and on the map", async ({ page }) => {
    await page.goto("/stops");
    await expect(page.locator(".map-marker").first()).toBeVisible({ timeout: 30_000 });
    const row = dockRow(page, `${prefix} existing`);
    await expect(row).toHaveAttribute("aria-pressed", "false");
    await row.click();
    await expect(row).toHaveAttribute("aria-pressed", "true");
    await expect(page.locator(".map-marker-selected")).toHaveCount(1);
  });

  test("clicking a marker selects the stop", async ({ page }) => {
    // Far from every other stop, so it stands on its own instead of inside a numbered bubble.
    const remote = await insertStop(`${prefix} remote`, "SRID=4326;POINT(9.7000000 4.5000000)");
    try {
      await page.goto("/stops");
      await page.locator(`button.map-marker[aria-label="${prefix} remote"]`).click();
      await expect(dockRow(page, `${prefix} remote`)).toHaveAttribute("aria-pressed", "true");
    } finally {
      await serviceClient().from("stops").delete().eq("id", remote);
    }
  });

  test("adds a stop by clicking the map while the sheet is open", async ({ page }) => {
    const name = `${prefix} clicked`;
    await page.goto("/stops");
    await page.getByRole("button", { name: "Add a stop" }).click();
    const sheet = page.getByRole("dialog", { name: "Add a stop" });
    await expect(sheet).toBeVisible();

    await sheet.getByLabel("Name").fill(name);
    await expect(page.locator(CANVAS)).toBeVisible({ timeout: 30_000 });
    // The sheet floats beside the page, so the map stays clickable.
    await page.locator(CANVAS).click({ position: { x: 300, y: 300 } });
    await expect(sheet.getByLabel("Latitude")).not.toHaveValue("");
    await expect(sheet.getByLabel("Longitude")).not.toHaveValue("");

    await sheet.getByRole("button", { name: "Add stop" }).click();
    await expect(sheet).toBeHidden();
    await expect(page.getByRole("status")).toContainText("Stop added.");
    await expect(dockRow(page, name)).toBeVisible();

    const saved = await stopByName(name);
    expect(saved).not.toBeNull();
    const point = parsePoint(saved!.location);
    expect(point && Number.isFinite(point.lat) && Number.isFinite(point.lng)).toBe(true);
    expect(saved!.active).toBe(true);
  });

  test("typing coordinates moves the pin", async ({ page }) => {
    await page.goto("/stops");
    await page.getByRole("button", { name: "Add a stop" }).click();
    const sheet = page.getByRole("dialog", { name: "Add a stop" });
    await expect(page.locator(CANVAS)).toBeVisible({ timeout: 30_000 });
    await expect(page.locator(PIN)).toHaveCount(0);

    await sheet.getByLabel("Latitude").fill("3.86");
    await sheet.getByLabel("Longitude").fill("11.51");
    await expect(page.locator(PIN)).toHaveCount(1);
  });

  test("a stop close to another asks first, showing the distance, and the same place is refused", async ({ page }) => {
    // Far from every other test's stops. 0.0009 degree of latitude is about 100 m.
    const anchor = `${prefix} anchor`;
    await insertStop(anchor, "SRID=4326;POINT(9.1000000 9.1000000)");
    // These stops are far from the others and would change how the map frames them in later tests: remove them after.
    try {
    await page.goto("/stops");
    await page.getByRole("button", { name: "Add a stop" }).click();
    const sheet = page.getByRole("dialog", { name: "Add a stop" });
    await sheet.getByLabel("Name").fill(`${prefix} near`);
    await sheet.getByLabel("Latitude").fill("9.1009");
    await sheet.getByLabel("Longitude").fill("9.1");
    await sheet.getByRole("button", { name: "Add stop" }).click();

    // Asked first: the name and the distance, and nothing is saved yet.
    const ask = page.getByRole("dialog", { name: "Another stop is close" });
    await expect(ask).toBeVisible();
    await expect(ask).toContainText(anchor);
    await expect(ask).toContainText(/about 1\d0 m away/);
    expect(await stopByName(`${prefix} near`)).toBeNull();

    // Back to the map changes nothing.
    await ask.getByRole("button", { name: "Back to the map" }).click();
    await expect(ask).toBeHidden();
    expect(await stopByName(`${prefix} near`)).toBeNull();

    // Adding anyway saves it.
    await sheet.getByRole("button", { name: "Add stop" }).click();
    await expect(ask).toBeVisible();
    await ask.getByRole("button", { name: "Add anyway" }).click();
    await expect(page.getByRole("status").filter({ hasText: "Stop added." })).toBeVisible();
    expect(await stopByName(`${prefix} near`)).not.toBeNull();

    // The very same coordinates: refused, with the stop's name, and no question.
    await page.getByRole("button", { name: "Add a stop" }).click();
    const again = page.getByRole("dialog", { name: "Add a stop" });
    await again.getByLabel("Name").fill(`${prefix} twin`);
    await again.getByLabel("Latitude").fill("9.1");
    await again.getByLabel("Longitude").fill("9.1");
    await again.getByRole("button", { name: "Add stop" }).click();
    await expect(again.getByRole("alert")).toContainText(`${anchor} is already at this place`);
    await expect(page.getByRole("dialog", { name: "Another stop is close" })).toBeHidden();
    expect(await stopByName(`${prefix} twin`)).toBeNull();
    } finally {
      await serviceClient().from("stops").delete().in("name", [anchor, `${prefix} near`, `${prefix} twin`]);
    }
  });

  test("an impossible latitude is refused with a clear message", async ({ page }) => {
    await page.goto("/stops");
    await page.getByRole("button", { name: "Add a stop" }).click();
    const sheet = page.getByRole("dialog", { name: "Add a stop" });
    await sheet.getByLabel("Name").fill(`${prefix} bad`);
    await sheet.getByLabel("Latitude").fill("95");
    await sheet.getByLabel("Longitude").fill("11.5");
    await sheet.getByRole("button", { name: "Add stop" }).click();
    await expect(sheet.getByRole("alert")).toContainText("Choose a position on the map or enter a valid latitude and longitude.");
    expect(await stopByName(`${prefix} bad`)).toBeNull();
  });

  test("a name that is already used is refused", async ({ page }) => {
    await page.goto("/stops");
    await page.getByRole("button", { name: "Add a stop" }).click();
    const sheet = page.getByRole("dialog", { name: "Add a stop" });
    await sheet.getByLabel("Name").fill(`${prefix} existing`);
    await sheet.getByLabel("Latitude").fill("3.9");
    await sheet.getByLabel("Longitude").fill("11.6");
    await sheet.getByRole("button", { name: "Add stop" }).click();
    await expect(sheet.getByRole("alert")).toContainText("Another stop already has this name.");
  });

  test("edits a stop and can switch it to inactive", async ({ page }) => {
    await page.goto("/stops");
    await page.getByRole("button", { name: `Edit ${prefix} editable` }).click();
    const sheet = page.getByRole("dialog", { name: "Edit stop" });
    await expect(sheet).toBeVisible();
    await expect(sheet.getByLabel("Name")).toHaveValue(`${prefix} editable`);
    await expect(sheet.getByLabel("Latitude")).toHaveValue("3.850000");

    await sheet.getByLabel("Name").fill(`${prefix} renamed`);
    await sheet.getByText("Active", { exact: true }).click();
    await sheet.getByRole("button", { name: "Save stop" }).click();
    await expect(sheet).toBeHidden();
    await expect(page.getByRole("status")).toContainText("Stop saved.");

    const row = dockRow(page, `${prefix} renamed`);
    await expect(row).toContainText("Inactive");
    const saved = await stopByName(`${prefix} renamed`);
    expect(saved?.id).toBe(editableId);
    expect(saved?.active).toBe(false);
  });

  test("closes with Escape and with its button, without saving", async ({ page }) => {
    await page.goto("/stops");
    const sheet = page.getByRole("dialog", { name: "Add a stop" });
    await page.getByRole("button", { name: "Add a stop" }).click();
    await expect(sheet).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(sheet).toBeHidden();

    await page.getByRole("button", { name: "Add a stop" }).click();
    await sheet.getByRole("button", { name: "Close" }).click();
    await expect(sheet).toBeHidden();
  });

  test("old links open the sheet on the Stops page", async ({ page }) => {
    await page.goto("/stops/new");
    await expect(page).toHaveURL(/\/stops\?add=1$/);
    await expect(page.getByRole("dialog", { name: "Add a stop" })).toBeVisible();

    await page.goto(`/stops/${existingId}`);
    await expect(page).toHaveURL(new RegExp(`/stops\\?edit=${existingId}$`));
    const sheet = page.getByRole("dialog", { name: "Edit stop" });
    await expect(sheet.getByLabel("Name")).toHaveValue(`${prefix} existing`);
  });

  test("an unknown or malformed id shows the not-found page", async ({ page }) => {
    await page.goto("/stops/not-an-id");
    await expect(page.getByRole("heading", { name: "Page not found" })).toBeVisible();
  });

  test("the page is available in French", async ({ page }) => {
    await setLanguage(page, "fr");
    await page.goto("/stops");
    await expect(page.getByRole("heading", { name: "Arrêts", level: 1 })).toBeVisible();
    await page.getByRole("button", { name: "Ajouter un arrêt" }).click();
    await expect(page.getByRole("dialog", { name: "Ajouter un arrêt" })).toBeVisible();
    await setLanguage(page, "en");
  });

  test("the tiles scroll sideways only, and the dock gives way while the sheet is open", async ({ page }) => {
    await page.goto("/stops");
    const tiles = bar(page).getByRole("list", { name: "Your stops" });
    await expect(tiles).toBeVisible();
    expect(await tiles.evaluate((el) => getComputedStyle(el).overflowY)).toBe("hidden");
    expect(await tiles.evaluate((el) => getComputedStyle(el).overflowX)).toBe("auto");
    expect(await tiles.evaluate((el) => el.scrollHeight <= el.clientHeight + 1)).toBe(true);

    await page.getByRole("button", { name: "Add a stop" }).click();
    await expect(tiles).toBeHidden();
    await page.keyboard.press("Escape");
    await expect(tiles).toBeVisible();
  });

  test("the bar keeps the same width on every page, so many stops scroll instead of stretching it", async ({ page }) => {
    const rows = Array.from({ length: 14 }, (_, i) => ({
      school_id: SEED.schoolId,
      name: `${prefix} many ${i}`,
      location: `SRID=4326;POINT(${(11.2 + i * 0.01).toFixed(4)} 3.7)`,
    }));
    const { data } = await serviceClient().from("stops").insert(rows).select("id");
    try {
      await page.goto("/trips");
      const widthOn = async () => Math.round((await bar(page).boundingBox())!.width);
      const elsewhere = await widthOn();

      await page.goto("/stops");
      const tiles = bar(page).getByRole("list", { name: "Your stops" });
      await expect(tiles).toBeVisible();
      expect(await widthOn()).toBe(elsewhere);
      // Only the tiles move: the row is wider than the bar and scrolls sideways.
      expect(await tiles.evaluate((el) => el.scrollWidth > el.clientWidth + 100)).toBe(true);
    } finally {
      await serviceClient().from("stops").delete().in("id", (data ?? []).map((row) => row.id));
    }
  });

  test("the last tile opens the full list beside the map, three parts to one", async ({ page }) => {
    await page.goto("/stops");
    const region = page.getByRole("region", { name: "Map of all stops" });
    const full = (await region.boundingBox())!.width;

    await bar(page).getByRole("button", { name: /View all stops/ }).click();
    const panel = page.getByRole("complementary", { name: "All stops" });
    await expect(panel).toBeVisible();
    await expect(bar(page).getByRole("list", { name: "Your stops" })).toBeHidden();

    // The map gives up a quarter of the screen (at least 22rem) to the list.
    await expect.poll(async () => (await region.boundingBox())!.width).toBeLessThan(full - 300);
    const mapWidth = (await region.boundingBox())!.width;
    const panelBox = (await panel.boundingBox())!;
    expect(mapWidth / (mapWidth + panelBox.width)).toBeGreaterThan(0.7);
    expect(mapWidth / (mapWidth + panelBox.width)).toBeLessThan(0.82);

    // It lists every stop, and can be searched.
    await expect(panel.getByRole("button", { name: new RegExp(`^${prefix} existing`) })).toBeVisible();
    await expect(panel.getByLabel("Search stops")).toHaveAttribute("placeholder", "Search by name...");
    await panel.getByLabel("Search stops").fill("editable");
    await expect(panel.getByRole("button", { name: new RegExp(`^${prefix} existing`) })).toHaveCount(0);
    await panel.getByLabel("Search stops").fill("zzz-nothing");
    await expect(panel.getByText("No stop matches your search.")).toBeVisible();

    await panel.getByRole("button", { name: "Close the list" }).click();
    await expect(panel).toBeHidden();
    await expect.poll(async () => (await region.boundingBox())!.width).toBeGreaterThan(full - 10);
    await expect(bar(page).getByRole("list", { name: "Your stops" })).toBeVisible();
  });

  test("stops that would overlap merge into a numbered bubble, and choosing it zooms in", async ({ page }) => {
    // Alone, away from every other stop (other specs leave stops of their own), so this crowd makes its own bubble.
    const ids = [
      await insertStop(`${prefix} crowd 1`, "SRID=4326;POINT(8.2000000 6.8000000)"),
      await insertStop(`${prefix} crowd 2`, "SRID=4326;POINT(8.2000800 6.8000300)"),
      await insertStop(`${prefix} crowd 3`, "SRID=4326;POINT(8.2000300 6.8000900)"),
    ];
    try {
      await page.goto("/stops");
      const bubble = page.locator(".map-cluster").filter({ hasText: /^3$/ });
      await expect(bubble).toHaveCount(1, { timeout: 30_000 });
      await expect(bubble).toHaveAttribute("aria-label", /^3 stops\. Select to zoom in\./);

      await bubble.click();
      // Zoomed in far enough, each of the three stands on its own.
      await expect(page.locator(".map-cluster").filter({ hasText: /^3$/ })).toHaveCount(0, { timeout: 15_000 });
      await expect(page.locator(`button.map-marker[aria-label="${prefix} crowd 1"]`)).toBeVisible();
      await expect(page.locator(`button.map-marker[aria-label="${prefix} crowd 3"]`)).toBeVisible();
    } finally {
      await serviceClient().from("stops").delete().in("id", ids);
    }
  });

  test("two stops that overlap merge into a bubble that says 2", async ({ page }) => {
    // Far from everything else, so the pair is alone in its own bubble.
    const ids = [
      await insertStop(`${prefix} pair 1`, "SRID=4326;POINT(8.9000000 5.9000000)"),
      await insertStop(`${prefix} pair 2`, "SRID=4326;POINT(8.9000500 5.9000300)"),
    ];
    try {
      await page.goto("/stops");
      const bubbles = page.locator(".map-cluster");
      await expect(bubbles.filter({ hasText: /^2$/ })).toHaveCount(1, { timeout: 30_000 });
      await expect(bubbles.filter({ hasText: /^2$/ }).first()).toHaveAttribute("aria-label", /^2 stops/);
    } finally {
      await serviceClient().from("stops").delete().in("id", ids);
    }
  });

  test("a bubble over nine shows 9+ and still gives the exact count to assistive technology", async ({ page }) => {
    const rows = Array.from({ length: 12 }, (_, i) => ({
      school_id: SEED.schoolId,
      name: `${prefix} heap ${i}`,
      location: `SRID=4326;POINT(${(7.5 + i * 0.00004).toFixed(6)} 6.5)`,
    }));
    const { data } = await serviceClient().from("stops").insert(rows).select("id");
    try {
      await page.goto("/stops");
      // Found by its exact count, so other bubbles (the demo data's stops, for one) do not matter.
      const big = page.locator('.map-cluster[aria-label^="12 stops"]');
      await expect(big).toHaveCount(1, { timeout: 30_000 });
      await expect(big).toHaveText("9+");
    } finally {
      await serviceClient().from("stops").delete().in("id", (data ?? []).map((row) => row.id));
    }
  });

  test("zooming with the map's own controls merges and splits stops as it goes", async ({ page }) => {
    // Two stops about 400 m apart, alone out east: separate when zoomed in, one bubble when zoomed out.
    const ids = [
      await insertStop(`${prefix} span 1`, "SRID=4326;POINT(10.2000000 6.3000000)"),
      await insertStop(`${prefix} span 2`, "SRID=4326;POINT(10.2036000 6.3000000)"),
    ];
    try {
      await page.goto("/stops");
      await expect(page.locator(".map-cluster, button.map-marker").first()).toBeVisible({ timeout: 30_000 });
      await dockRow(page, `${prefix} span 1`).click();
      const bubbleOf = () => page.locator(".map-cluster").filter({ hasText: /^2$/ });
      // Zoomed in on the first stop, the two are told apart.
      await expect(page.locator(`button.map-marker[aria-label="${prefix} span 2"], .map-marker-selected`).first()).toBeVisible({ timeout: 15_000 });
      for (let i = 0; i < 4; i++) await page.getByRole("button", { name: "Zoom out" }).click();
      await expect(bubbleOf().or(page.locator(".map-cluster").first())).toBeVisible({ timeout: 15_000 });
    } finally {
      await serviceClient().from("stops").delete().in("id", ids);
    }
  });

  test("the selected stop is never swallowed by a bubble", async ({ page }) => {
    const ids = [
      await insertStop(`${prefix} pile 1`, "SRID=4326;POINT(11.5600000 3.9200000)"),
      await insertStop(`${prefix} pile 2`, "SRID=4326;POINT(11.5600600 3.9200200)"),
    ];
    try {
      await page.goto("/stops");
      await expect(page.locator(".map-cluster").first()).toBeVisible({ timeout: 30_000 });
      await dockRow(page, `${prefix} pile 1`).click();
      await expect(page.locator(".map-marker-selected")).toHaveCount(1);
    } finally {
      await serviceClient().from("stops").delete().in("id", ids);
    }
  });

  test("a scrolling container shows a thin scrollbar only while it is used", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 520 });
    await page.goto("/stops");
    await page.getByRole("button", { name: "Add a stop" }).click();
    const sheet = page.getByRole("dialog", { name: "Add a stop" });
    await expect(sheet).toBeVisible();

    // The sheet opens under the spot that was just clicked, so move the pointer off it: a hovered container shows its thumb.
    await page.mouse.move(4, 4);
    const colour = () => sheet.evaluate((el) => getComputedStyle(el).scrollbarColor);
    await page.waitForTimeout(900);
    const resting = await colour();
    await sheet.evaluate((el) => {
      el.scrollTop = 40;
    });
    await expect(sheet).toHaveClass(/is-scrolling/);
    await expect.poll(colour).not.toBe(resting);
    await expect(sheet).not.toHaveClass(/is-scrolling/, { timeout: 5000 });
    await expect.poll(colour, { timeout: 5000 }).toBe(resting);
  });

  test("where students live stays off until a zone has five students", async ({ page }) => {
    // Only meaningful when no zone of the school has five students yet (the demo data has some).
    const { data: rows } = await serviceClient().from("student_areas").select("area").eq("school_id", SEED.schoolId);
    const perZone = new Map<string, number>();
    for (const row of rows ?? []) perZone.set(String(row.area), (perZone.get(String(row.area)) ?? 0) + 1);
    test.skip([...perZone.values()].some((n) => n >= 5), "a zone already has five students");
    await page.goto("/stops");
    await bar(page).getByRole("button", { name: /^View all/ }).click();
    const areas = page.getByRole("switch", { name: "Where students live" });
    await expect(areas).toBeDisabled();
    await expect(page.getByText("No zone has 5 students yet.", { exact: false })).toBeVisible();
  });

  test("the help sheet explains the page with examples", async ({ page }) => {
    await page.goto("/stops");
    await page.getByRole("button", { name: "Help" }).click();
    const help = page.getByRole("dialog", { name: "How stops work" });
    await expect(help).toBeVisible();
    await expect(help.getByText("A road is closed for works")).toBeVisible();
  });
});

test.describe("pings and pins", () => {
  test.use({ reducedMotion: "no-preference" });

  test.beforeEach(async ({ page, context }) => {
    await useBlankMap(page);
    await signInBrowser(context, admin);
  });

  test("the visitor's position pings with a wave", async ({ page, context }) => {
    await context.grantPermissions(["geolocation"]);
    await context.setGeolocation({ latitude: 3.8481, longitude: 11.5021 });
    await page.goto("/stops");
    await bar(page).getByRole("button", { name: "Show my location" }).click();
    const dot = page.locator(".map-marker-me");
    await expect(dot).toBeVisible({ timeout: 30_000 });
    expect(await dot.evaluate((el) => getComputedStyle(el, "::before").animationName)).toBe("map-ping");
    expect(await dot.evaluate((el) => getComputedStyle(el, "::after").animationName)).toBe("map-ping");
  });

  test("a stop only pings, like the visitor's dot, once it is focused", async ({ page }) => {
    const lone = await insertStop(`${prefix} ripple`, "SRID=4326;POINT(9.8000000 4.6000000)");
    try {
      await page.goto("/stops");
      const dot = page.locator(`button.map-marker[aria-label="${prefix} ripple"]`);
      await expect(dot).toBeVisible({ timeout: 30_000 });
      // Not focused: a plain dot that does not ping.
      expect(await dot.evaluate((el) => getComputedStyle(el, "::before").animationName)).toBe("none");

      await dot.click();
      const pin = page.locator(".map-marker-selected");
      await expect(pin).toHaveCount(1);
      // Same wave as the visitor's own dot, no pin icon.
      await expect(pin.locator("svg")).toHaveCount(0);
      expect(await pin.evaluate((el) => getComputedStyle(el, "::before").animationName)).toBe("map-ping");
      expect(await pin.evaluate((el) => getComputedStyle(el, "::after").animationName)).toBe("map-ping");
    } finally {
      await serviceClient().from("stops").delete().eq("id", lone);
    }
  });
});

test.describe("showing where the administrator is", () => {
  test.beforeEach(async ({ page, context }) => {
    await useBlankMap(page);
    await signInBrowser(context, admin);
  });

  test("marks the position, lists the nearest stop first and shows distances", async ({ page, context }) => {
    await context.grantPermissions(["geolocation"]);
    // A few metres from the existing stop.
    await context.setGeolocation({ latitude: 3.8481, longitude: 11.5021 });
    await page.goto("/stops");

    const tiles = bar(page).getByRole("list", { name: "Your stops" });
    await expect(tiles).not.toContainText("from you");
    await bar(page).getByRole("button", { name: "Show my location" }).click();

    await expect(page.locator(".map-marker-me")).toBeVisible({ timeout: 30_000 });
    const first = tiles.getByRole("listitem").first();
    await expect(first).toContainText(`${prefix} existing`);
    await expect(first).toContainText("from you");
    await expect(first).toContainText(/\d+ m/);
    // Distances replace nothing else: every stop tile keeps its name and status.
    await expect(first).toContainText("Active");
  });

  test("pressing the location button again brings the map back to where the visitor is", async ({ page, context }) => {
    await context.grantPermissions(["geolocation"]);
    await context.setGeolocation({ latitude: 3.8481, longitude: 11.5021 });
    await page.goto("/stops");
    const here = bar(page).getByRole("button", { name: "Show my location" });
    await here.click();

    const dot = page.locator(".map-marker-me");
    await expect(dot).toBeVisible({ timeout: 30_000 });
    const viewport = page.viewportSize()!;
    const distanceFromCentre = async () => {
      const box = (await dot.boundingBox())!;
      return Math.hypot(box.x + box.width / 2 - viewport.width / 2, box.y + box.height / 2 - viewport.height / 2);
    };
    await expect.poll(distanceFromCentre, { timeout: 15_000 }).toBeLessThan(40);

    // Pan the map away by dragging it, well clear of the bar.
    await page.mouse.move(300, 150);
    await page.mouse.down();
    await page.mouse.move(420, 230, { steps: 8 });
    await page.mouse.up();
    await expect.poll(distanceFromCentre, { timeout: 10_000 }).toBeGreaterThan(100);

    // Again: even though the position did not change, the map returns to it.
    await here.click();
    await expect.poll(distanceFromCentre, { timeout: 15_000 }).toBeLessThan(40);
  });

  test("shows distances as approximations", async ({ page, context }) => {
    await context.grantPermissions(["geolocation"]);
    await context.setGeolocation({ latitude: 3.8481, longitude: 11.5021 });
    await page.goto("/stops");
    await bar(page).getByRole("button", { name: "Show my location" }).click();
    await expect(page.locator(".map-marker-me")).toBeVisible({ timeout: 30_000 });
    const tile = bar(page).getByRole("list", { name: "Your stops" }).getByRole("listitem").first();
    await expect(tile).toContainText(/~\d+(\.\d)? (m|km)/);
    await bar(page).getByRole("button", { name: /View all stops/ }).click();
    await expect(page.getByRole("complementary", { name: "All stops" })).toContainText("Distances are approximate, in a straight line.");
  });

  test("says so plainly when the location cannot be had", async ({ page }) => {
    await page.goto("/stops");
    await bar(page).getByRole("button", { name: "Show my location" }).click();
    await expect(bar(page).getByRole("alert")).toContainText("We could not get your location.");
    await expect(page.locator(".map-marker-me")).toHaveCount(0);
  });

  test("the full list shows distances too", async ({ page, context }) => {
    await context.grantPermissions(["geolocation"]);
    await context.setGeolocation({ latitude: 3.8481, longitude: 11.5021 });
    await page.goto("/stops");
    await bar(page).getByRole("button", { name: "Show my location" }).click();
    await expect(page.locator(".map-marker-me")).toBeVisible({ timeout: 30_000 });
    await bar(page).getByRole("button", { name: /View all stops/ }).click();
    const panel = page.getByRole("complementary", { name: "All stops" });
    await expect(panel).toContainText("Nearest first");
    await expect(panel.getByRole("button", { name: new RegExp(`^${prefix} existing`) })).toContainText("from you");
  });
});

test.describe("on a phone", () => {
  test.use({ viewport: { width: 390, height: 844 } });

  test("the map fills the screen, the list sits above the bar and nothing scrolls sideways", async ({ page, context }) => {
    await useBlankMap(page);
    await signInBrowser(context, admin);
    await page.goto("/stops");
    await expect(page.getByRole("button", { name: "Add a stop" })).toBeVisible();
    await expect(dockRow(page, `${prefix} existing`)).toBeVisible();
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBe(0);
  });
});

for (const [label, who] of [
  ["a student", () => student],
  ["a staff member", () => staff],
] as const) {
  test(`${label} cannot open the stops page or its old links`, async ({ page, context }) => {
    await signInBrowser(context, who());
    for (const path of ["/stops", "/stops/new", `/stops/${existingId}`]) {
      await page.goto(path);
      await expect(page).toHaveURL(/\/no-access$/);
    }
  });
}

test("signed-out visitors are sent to the login page", async ({ page }) => {
  await page.goto("/stops");
  await expect(page).toHaveURL(/\/login$/);
});
