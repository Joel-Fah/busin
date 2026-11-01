import { defineConfig, devices } from "@playwright/test";

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
    baseURL: "http://127.0.0.1:3000",
    trace: "retain-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    command: "npm run dev",
    url: "http://127.0.0.1:3000/login",
    reuseExistingServer: true,
    timeout: 120_000,
  },
});
