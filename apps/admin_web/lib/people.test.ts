import { describe, expect, it } from "vitest";

import { lastPage, pageRange, parsePage } from "./pagination";
import {
  MAX_SEARCH_LENGTH,
  accountTone,
  initials,
  isPeopleDone,
  isRole,
  parseRoleFilter,
  parseSearch,
  peopleErrorKey,
  roleTabCounts,
  roleTone,
  searchFilter,
} from "./people";

describe("parseRoleFilter", () => {
  it("defaults to everyone", () => {
    expect(parseRoleFilter(undefined)).toBe("all");
    expect(parseRoleFilter("verify")).toBe("verify");
    expect(parseRoleFilter("")).toBe("all");
    expect(parseRoleFilter("owner")).toBe("all");
  });

  it("accepts the known roles", () => {
    for (const role of ["all", "student", "staff", "admin"]) expect(parseRoleFilter(role)).toBe(role);
    expect(parseRoleFilter(["staff", "admin"])).toBe("staff");
  });
});

describe("isRole", () => {
  it("accepts only the three roles", () => {
    expect(isRole("student")).toBe(true);
    expect(isRole("admin")).toBe(true);
    expect(isRole("Admin")).toBe(false);
    expect(isRole("owner")).toBe(false);
    expect(isRole(null)).toBe(false);
  });
});

describe("parseSearch", () => {
  it("trims and collapses spaces", () => {
    expect(parseSearch("  ada   lovelace ")).toBe("ada lovelace");
  });

  it("removes characters that have meaning in a filter", () => {
    expect(parseSearch("a,b)")).toBe("a b");
    expect(parseSearch('x"y\'z')).toBe("x y z");
    expect(parseSearch("100%*\\")).toBe("100");
    expect(parseSearch("full_name.eq.1),email.ilike.%")).toBe("full_name.eq.1 email.ilike.");
  });

  it("returns an empty string for nothing searchable and caps the length", () => {
    expect(parseSearch(undefined)).toBe("");
    expect(parseSearch(" , % ")).toBe("");
    expect(parseSearch("x".repeat(500)).length).toBe(MAX_SEARCH_LENGTH);
  });

  it("uses the first of repeated values", () => {
    expect(parseSearch(["ada", "bob"])).toBe("ada");
  });
});

describe("searchFilter", () => {
  it("matches name, email and matricule", () => {
    expect(searchFilter("ada")).toBe("full_name.ilike.%ada%,email.ilike.%ada%,matricule.ilike.%ada%");
  });
});

describe("initials", () => {
  it("uses the first letters of two words", () => {
    expect(initials("Ada Lovelace", null)).toBe("AL");
    expect(initials("  grace   hopper  ", null)).toBe("GH");
  });

  it("falls back to the email, then to a single word, then a placeholder", () => {
    expect(initials("", "ada.lovelace@school.edu")).toBe("AL");
    expect(initials("Cher", null)).toBe("CH");
    expect(initials(null, null)).toBe("?");
    expect(initials("  ", "")).toBe("?");
  });
});

describe("peopleErrorKey", () => {
  it("maps the database error codes", () => {
    expect(peopleErrorKey("42501")).toBe("self");
    expect(peopleErrorKey("22023")).toBe("invalid");
    expect(peopleErrorKey("P0002")).toBe("not_found");
    expect(peopleErrorKey("XX000")).toBe("generic");
    expect(peopleErrorKey(undefined)).toBe("generic");
  });
});

describe("done states", () => {
  it("recognises only known outcomes", () => {
    expect(isPeopleDone("role")).toBe(true);
    expect(isPeopleDone("suspended")).toBe(true);
    expect(isPeopleDone("restored")).toBe(true);
    expect(isPeopleDone("deleted")).toBe(false);
  });
});

describe("pagination helpers", () => {
  it("compute pages and ranges", () => {
    expect(parsePage("2")).toBe(2);
    expect(pageRange(2)).toEqual({ from: 20, to: 39 });
    expect(lastPage(0)).toBe(1);
    expect(lastPage(20)).toBe(1);
    expect(lastPage(21)).toBe(2);
  });
});

describe("tones and tab counts", () => {
  it("gives roles and account states their own tones", () => {
    expect(roleTone("admin")).toBe("info");
    expect(roleTone("staff")).toBe("warn");
    expect(roleTone("student")).toBe("neutral");
    expect(accountTone("verified")).toBe("ok");
    expect(accountTone("suspended")).toBe("bad");
    expect(accountTone("pending")).toBe("warn");
  });

  it("adds up the total and treats a missing count as zero", () => {
    expect(roleTabCounts({ student: 120, staff: 6, admin: 2 })).toEqual({ all: 128, verify: 0, invited: 0, student: 120, staff: 6, admin: 2 });
    expect(roleTabCounts({ staff: 6 }, 0, 2)).toMatchObject({ all: 6, invited: 2 });
    expect(roleTabCounts({ student: 120 }, 3).verify).toBe(3);
    expect(roleTabCounts({ student: 120 }, null).verify).toBe(0);
    expect(roleTabCounts({ student: null }).all).toBe(0);
  });
});
