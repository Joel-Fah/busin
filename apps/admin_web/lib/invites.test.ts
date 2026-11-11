import { describe, expect, it } from "vitest";

import { daysLeft, inviteErrorKey, isInviteRole, normalizeInviteEmail, parseInviteDone, parseInviteError } from "./invites";

describe("normalizeInviteEmail", () => {
  it("trims and lowers a valid email", () => {
    expect(normalizeInviteEmail("  Driver.New@Gmail.COM ")).toBe("driver.new@gmail.com");
  });

  it("refuses anything that is not an email", () => {
    for (const value of ["", "driver", "a@b", "a b@c.org", "a@@c.org", 42, null, `${"a".repeat(250)}@b.org`]) {
      expect(normalizeInviteEmail(value)).toBeNull();
    }
  });
});

describe("roles", () => {
  it("only staff and admin can be invited", () => {
    expect(isInviteRole("staff")).toBe(true);
    expect(isInviteRole("admin")).toBe(true);
    expect(isInviteRole("student")).toBe(false);
  });
});

describe("inviteErrorKey", () => {
  it("maps the database answers", () => {
    expect(inviteErrorKey("55000", "other_school")).toBe("other_school");
    expect(inviteErrorKey("22023", "invalid_role")).toBe("invalid_role");
    expect(inviteErrorKey("22023", "invalid_email")).toBe("invalid_email");
    expect(inviteErrorKey("42501", "You cannot change your own role")).toBe("self");
    expect(inviteErrorKey("XX000", "boom")).toBe("generic");
  });

  it("reads only known keys back from the address", () => {
    expect(parseInviteError("other_school")).toBe("other_school");
    expect(parseInviteError("<script>")).toBeNull();
    expect(parseInviteDone(["applied"])).toBe("applied");
    expect(parseInviteDone("nope")).toBeNull();
  });
});

describe("daysLeft", () => {
  const now = new Date("2026-11-11T12:00:00Z");
  it("rounds up and never goes below zero", () => {
    expect(daysLeft("2026-12-11T12:00:00Z", now)).toBe(30);
    expect(daysLeft("2026-11-11T13:00:00Z", now)).toBe(1);
    expect(daysLeft("2026-11-10T12:00:00Z", now)).toBe(0);
  });
});
