import { describe, expect, it } from "vitest";

import { decideAccess } from "./access";

describe("decideAccess", () => {
  it("lets a verified admin in", () => {
    expect(decideAccess({ role: "admin", status: "verified" })).toBe("admin");
  });

  it("refuses staff and students", () => {
    expect(decideAccess({ role: "staff", status: "verified" })).toBe("forbidden");
    expect(decideAccess({ role: "student", status: "verified" })).toBe("forbidden");
  });

  it("refuses an admin who is suspended or pending", () => {
    expect(decideAccess({ role: "admin", status: "suspended" })).toBe("forbidden");
    expect(decideAccess({ role: "admin", status: "pending" })).toBe("forbidden");
  });

  it("refuses a missing profile and unknown values", () => {
    expect(decideAccess(null)).toBe("forbidden");
    expect(decideAccess(undefined)).toBe("forbidden");
    expect(decideAccess({ role: "Admin", status: "verified" })).toBe("forbidden");
    expect(decideAccess({ role: "owner", status: "verified" })).toBe("forbidden");
  });
});
