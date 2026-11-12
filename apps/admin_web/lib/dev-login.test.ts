import { describe, expect, it } from "vitest";

import { isLocalDevelopment } from "./dev-login";

describe("isLocalDevelopment", () => {
  it("allows a development server with a backend on this machine", () => {
    expect(isLocalDevelopment("development", "http://127.0.0.1:54321")).toBe(true);
    expect(isLocalDevelopment("development", "http://localhost:54321")).toBe(true);
    expect(isLocalDevelopment("development", "http://[::1]:54321")).toBe(true);
  });

  it("refuses every production and test build, even with a local backend", () => {
    expect(isLocalDevelopment("production", "http://127.0.0.1:54321")).toBe(false);
    expect(isLocalDevelopment("test", "http://127.0.0.1:54321")).toBe(false);
    expect(isLocalDevelopment(undefined, "http://127.0.0.1:54321")).toBe(false);
  });

  it("refuses a development server pointed at a remote backend", () => {
    expect(isLocalDevelopment("development", "https://abcd.supabase.co")).toBe(false);
    expect(isLocalDevelopment("development", "http://192.168.1.20:54321")).toBe(false);
  });

  it("is not fooled by look-alike hosts or bad values", () => {
    expect(isLocalDevelopment("development", "http://127.0.0.1.evil.example")).toBe(false);
    expect(isLocalDevelopment("development", "http://localhost.evil.example")).toBe(false);
    expect(isLocalDevelopment("development", "https://evil.example/?u=http://127.0.0.1")).toBe(false);
    expect(isLocalDevelopment("development", "not a url")).toBe(false);
    expect(isLocalDevelopment("development", "")).toBe(false);
  });
});
