import { describe, expect, it } from "vitest";

import { lookupErrorKey, parseLookup } from "./platform-lookup";

describe("parseLookup", () => {
  it("reads an account found", () => {
    const account = parseLookup({
      found: true,
      id: "u1",
      email: "stu@look.edu",
      full_name: "Stu Dent",
      role: "student",
      status: "pending",
      school_name: "Lookup School",
      last_sign_in_at: "2026-11-15T08:00:00Z",
      provider: "google",
      join_requested_at: "2026-11-14T08:00:00Z",
      platform_admin: false,
      subscriptions: { approved: 1, rejected: 0 },
      devices: 2,
    });
    expect(account).toMatchObject({ found: true, role: "student", status: "pending", schoolName: "Lookup School", devices: 2, invite: null });
    expect(account.subscriptions).toEqual({ approved: 1 });
  });
  it("reads an email not found but invited", () => {
    const account = parseLookup({ found: false, invite: { school_name: "Lookup School", role: "admin", expires_at: "2026-12-15T00:00:00Z" } });
    expect(account.found).toBe(false);
    expect(account.invite).toMatchObject({ schoolName: "Lookup School", role: "admin" });
  });
  it("never trusts an unknown role", () => {
    expect(parseLookup({ found: true, role: "owner" }).role).toBeNull();
  });
});

describe("lookupErrorKey", () => {
  it("keeps the refusals it explains", () => {
    expect(lookupErrorKey("too_many")).toBe("too_many");
    expect(lookupErrorKey("boom")).toBe("generic");
  });
});
