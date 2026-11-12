import { afterEach, describe, expect, it, vi } from "vitest";

import { siteUrl } from "./site";

afterEach(() => vi.unstubAllEnvs());

describe("siteUrl", () => {
  it("is the configured address without a trailing slash", () => {
    vi.stubEnv("SITE_URL", "https://busin.example/");
    vi.stubEnv("VERCEL_PROJECT_PRODUCTION_URL", "busin.vercel.app");
    expect(siteUrl()).toBe("https://busin.example");
  });

  it("falls back to the Vercel production address, which comes without a scheme", () => {
    vi.stubEnv("SITE_URL", "");
    vi.stubEnv("VERCEL_PROJECT_PRODUCTION_URL", "busin.vercel.app");
    expect(siteUrl()).toBe("https://busin.vercel.app");
  });

  it("keeps the local address for development", () => {
    vi.stubEnv("SITE_URL", "");
    vi.stubEnv("VERCEL_PROJECT_PRODUCTION_URL", "");
    expect(siteUrl()).toBe("http://localhost:3000");
  });
});
