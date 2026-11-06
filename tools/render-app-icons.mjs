// Renders the app icon images from the BusIn wordmark (apps/admin_web/public/brand/cyan.svg).
//   node tools/render-app-icons.mjs
// Uses the Chromium that Playwright already installed for the portal tests. Stand-in artwork until the
// owner's own icons exist: replace the PNGs in apps/<app>/assets/icon/ and run the launcher icons tool.
import { createRequire } from "node:module";
import { mkdirSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const require = createRequire(path.join(root, "apps/admin_web/package.json"));
const { chromium } = require("@playwright/test");

const SEED = "#002A33";
const WHITE = "#FFFFFF";
const svg = readFileSync(path.join(root, "apps/admin_web/public/brand/cyan.svg"), "utf8");
const mark = (colour) => svg.replaceAll('fill="#002A33"', `fill="${colour}"`).replace(/width="\d+" height="\d+"/, 'width="100%" height="100%"');

/** One square image: the wordmark at `width` px, centred, on `background` (or transparent). `canvas` is its side, 1024 by default. */
const page = ({ background, colour, width, canvas = 1024 }) => `<!doctype html><html><body style="margin:0;width:${canvas}px;height:${canvas}px;background:${background};display:grid;place-items:center">
<div style="width:${width}px;aspect-ratio:205/126">${mark(colour)}</div></body></html>`;

const apps = {
  student: [
    // Full square, for iOS and as the fallback icon.
    ["icon.png", { background: SEED, colour: WHITE, width: 700 }],
    // Adaptive icon foreground: inside the central 66% that Android never crops.
    ["icon_foreground.png", { background: "transparent", colour: WHITE, width: 560 }],
    // Android 13 themed icon: one colour, the system tints it.
    ["icon_monochrome.png", { background: "transparent", colour: "#000000", width: 560 }],
    // The native splash: the wordmark at 144 dp (576 px at 4x) in the middle of a 288 dp canvas, which is what Android 12
    // draws its splash icon in. The app's opening animation draws the same mark at the same 144 dp, so the hand-off is seamless.
    ["../splash/wordmark.png", { background: "transparent", colour: WHITE, width: 576, canvas: 1152 }],
  ],
};

const browser = await chromium.launch();
for (const [app, files] of Object.entries(apps)) {
  const out = path.join(root, "apps", app, "assets/icon");
  mkdirSync(out, { recursive: true });
  for (const [name, options] of files) {
    const canvas = options.canvas ?? 1024;
    const tab = await browser.newPage({ viewport: { width: canvas, height: canvas } });
    await tab.setContent(page(options));
    const target = path.join(out, name);
    mkdirSync(path.dirname(target), { recursive: true });
    await tab.screenshot({ path: target, omitBackground: options.background === "transparent" });
    await tab.close();
    console.log(path.relative(root, path.join(out, name)));
  }
}
await browser.close();
