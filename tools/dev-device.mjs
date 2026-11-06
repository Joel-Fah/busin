// One command to run an app on a connected Android device against the local backend:
//
//   npm run dev:device                 the student app on the one connected device
//   npm run dev:device -- ops          the ops app
//   npm run dev:device -- --device ID  a specific device (needed when several are connected, unless --all)
//   npm run dev:device -- --all        every connected device at once
//   npm run dev:device -- --no-run     only check the backend and set up the tunnels
//
// What it does, in order:
//   1. checks the local backend answers, and starts it if it does not (Docker must be running);
//   2. finds the connected devices and forwards the backend and portal ports to each over USB (adb reverse), so the same
//      config/dev.json works on every device;
//   3. starts the app with fvm flutter run (hot reload keys work as usual);
//   4. while the app runs, restores the tunnels whenever a USB reset drops them, so the app does not go quiet.
//
// Nothing here changes any cloud resource: the backend is the local one.
import { spawn, spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { createInterface } from "node:readline/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const PORTS = [54321, 3000];
const BACKEND_URL = "http://127.0.0.1:54321/rest/v1/";

const args = process.argv.slice(2);
const flag = (name) => args.includes(`--${name}`);
const option = (name) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : undefined;
};
const app = args.find((a, i) => !a.startsWith("--") && args[i - 1] !== "--device") ?? "student";

const say = (message) => console.log(`[dev:device] ${message}`);
const fail = (message) => {
  console.error(`[dev:device] ${message}`);
  process.exit(1);
};

function adb(...rest) {
  return spawnSync("adb", rest, { encoding: "utf8" });
}

async function backendUp() {
  try {
    const response = await fetch(BACKEND_URL, { signal: AbortSignal.timeout(2500) });
    return response.status < 500;
  } catch {
    return false;
  }
}

async function ensureBackend() {
  if (await backendUp()) return say("backend is up (http://127.0.0.1:54321)");
  say("backend is not answering, starting it (needs Docker running)...");
  const started = spawnSync("npm", ["run", "backend:start"], { cwd: root, stdio: "inherit" });
  if (started.status !== 0) fail("the backend did not start. Start Docker, then run `npm run backend:start` and read its error.");
  for (let i = 0; i < 20; i++) {
    if (await backendUp()) return say("backend is up");
    await new Promise((r) => setTimeout(r, 1000));
  }
  fail("the backend started but still does not answer on port 54321.");
}

function connectedDevices() {
  const result = adb("devices");
  if (result.error) fail("adb was not found. Install the Android platform tools and put adb on your PATH.");
  const found = [];
  for (const line of result.stdout.split("\n").slice(1)) {
    const [id, state] = line.trim().split(/\s+/);
    if (!id) continue;
    if (state === "device") found.push(id);
    else say(`skipping ${id}: ${state} (${state === "unauthorized" ? "accept the USB debugging prompt on the device" : "reconnect the cable"})`);
  }
  return found;
}

const tunnelled = (id) => {
  const list = adb("-s", id, "reverse", "--list").stdout ?? "";
  return PORTS.every((port) => list.includes(`tcp:${port} tcp:${port}`));
};

function forward(id) {
  for (const port of PORTS) adb("-s", id, "reverse", `tcp:${port}`, `tcp:${port}`);
  return tunnelled(id);
}

async function chooseTargets(devices) {
  const wanted = option("device");
  if (wanted) {
    if (!devices.includes(wanted)) fail(`device ${wanted} is not connected. Connected: ${devices.join(", ") || "none"}.`);
    return [wanted];
  }
  if (devices.length === 1 || flag("all")) return devices;
  if (!process.stdin.isTTY) fail(`several devices are connected (${devices.join(", ")}). Pass --device <id> or --all.`);
  devices.forEach((id, i) => console.log(`  ${i + 1}. ${id}`));
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const answer = (await rl.question("Which device? (number, or a for all) ")).trim();
  rl.close();
  if (answer === "a") return devices;
  const picked = devices[Number(answer) - 1];
  if (!picked) fail("no such device.");
  return [picked];
}

async function main() {
  if (!["student", "ops"].includes(app)) fail(`unknown app "${app}". Use student or ops.`);
  const config = join(root, "config", "dev.json");
  if (!existsSync(config)) fail("config/dev.json is missing. Copy config/dev.example.json to config/dev.json and fill it in (see docs/guides/student-app-setup.md).");

  await ensureBackend();

  const devices = connectedDevices();
  if (devices.length === 0) fail("no Android device is connected. Plug one in, enable USB debugging, and run this again.");
  for (const id of devices) say(`${id}: tunnels ${forward(id) ? "ready" : "FAILED (check the cable and USB debugging)"}`);

  const targets = await chooseTargets(devices);
  if (flag("no-run")) return say("tunnels are set up. Not starting the app (--no-run).");

  // Keep the tunnels: a USB reset drops them, and the app then cannot reach the backend.
  const watcher = setInterval(async () => {
    for (const id of connectedDevices().filter((d) => targets.includes(d) || flag("all"))) {
      if (!tunnelled(id) && forward(id)) say(`${id}: tunnels were dropped, restored`);
    }
  }, 4000);
  watcher.unref();

  const device = targets.length === 1 ? targets[0] : "all";
  say(`starting the ${app} app on ${device}...`);
  const run = spawn("fvm", ["flutter", "run", "-d", device, "--dart-define-from-file=../../config/dev.json"], {
    cwd: join(root, "apps", app),
    stdio: "inherit",
  });
  run.on("error", () => fail("fvm was not found. Install fvm (see docs/guides/local-setup.md)."));
  run.on("exit", (code) => {
    clearInterval(watcher);
    process.exit(code ?? 0);
  });
}

main();
