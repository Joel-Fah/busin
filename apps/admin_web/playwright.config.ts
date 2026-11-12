import { defineConfig, devices } from "@playwright/test";

const PORT = process.env.E2E_PORT ?? "3000";

// Runs against the local Supabase stack (npx supabase start) and a local dev server.
// The dev server reads NEXT_PUBLIC_* values from .env.local.
export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  workers: 1,
  retries: 0,
  // The dev server compiles a page the first time it is visited, which can take several seconds.
  timeout: 60_000,
  expect: { timeout: 15_000 },
  reporter: [["list"]],
  use: {
    baseURL: `http://127.0.0.1:${PORT}`,
    trace: "retain-on-failure",
    // The logo intro and navigation reveal are skipped for reduced motion, so tests never wait for them.
    // The specs that test the animations turn it back on.
    reducedMotion: "reduce",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    // E2E_PROD=1 runs a production build instead, which can sit beside a dev server you already have (Next allows one dev server per project).
    command: process.env.E2E_PROD === "1" ? `npm run build && npm run start -- --port ${PORT}` : `npm run dev -- --port ${PORT}`,
    url: `http://127.0.0.1:${PORT}/login`,
    reuseExistingServer: true,
    timeout: 120_000,
    // Tests use the free map. Mapbox bills per map load, so it is only exercised on purpose:
    //   E2E_PROD=1 E2E_PORT=3100 MAP_PROVIDER=mapbox npx playwright test e2e/mapbox.spec.ts
    env: { MAP_PROVIDER: process.env.MAP_PROVIDER ?? "" },
  },
});
