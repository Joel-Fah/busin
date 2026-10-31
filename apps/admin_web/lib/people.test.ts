import { describe, expect, it } from "vitest";

import { lastPage, pageRange, parsePage } from "./pagination";
import {
  MAX_SEARCH_LENGTH,
  accountPill,
  initials,
  isPeopleDone,
  isRole,
  parseRoleFilter,
  parseSearch,
  peopleErrorKey,
  rolePill,
  searchFilter,
} from "./people";

describe("parseRoleFilter", () => {
  it("defaults to everyone", () => {
    expect(parseRoleFilter(undefined)).toBe("all");
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

describe("pills and done states", () => {
  it("give each role and status its own look", () => {
    expect(new Set((["student", "staff", "admin"] as const).map(rolePill)).size).toBe(3);
    expect(new Set((["pending", "verified", "suspended"] as const).map(accountPill)).size).toBe(3);
  });

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
