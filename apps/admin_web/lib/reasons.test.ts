import { describe, expect, it } from "vitest";

import { checkReason, isReasonProblem, REASON_MIN, reasonProblemFromDb, tidyReason, withPreset } from "./reasons";

describe("tidyReason", () => {
  it("trims and collapses spaces and line breaks", () => {
    expect(tidyReason("  The   receipt\n\nis  unreadable.  ")).toBe("The receipt is unreadable.");
    expect(tidyReason(undefined)).toBe("");
    expect(tidyReason(42)).toBe("");
  });
});

describe("checkReason", () => {
  const required = { required: true, max: 500 };
  const optional = { required: false, max: 300 };

  it("asks for a reason when one is needed, and takes none when it is not", () => {
    expect(checkReason("   ", required)).toEqual({ ok: false, problem: "reason_required" });
    expect(checkReason("", optional)).toEqual({ ok: true, value: null });
    expect(checkReason("   \n ", optional)).toEqual({ ok: true, value: null });
  });

  it(`wants at least ${REASON_MIN} characters, counted after tidying`, () => {
    expect(checkReason("too short", required)).toEqual({ ok: false, problem: "reason_too_short" });
    expect(checkReason("  a    b    c    d  e ", required)).toEqual({ ok: false, problem: "reason_too_short" });
    expect(checkReason("ten chars!", required)).toEqual({ ok: true, value: "ten chars!" });
    // A few words are not accepted even where a reason is optional.
    expect(checkReason("no", optional)).toEqual({ ok: false, problem: "reason_too_short" });
  });

  it("keeps to the longest the place allows", () => {
    expect(checkReason("x".repeat(500), required)).toMatchObject({ ok: true });
    expect(checkReason("x".repeat(501), required)).toEqual({ ok: false, problem: "reason_too_long" });
    expect(checkReason("x".repeat(301), optional)).toEqual({ ok: false, problem: "reason_too_long" });
  });

  it("returns the tidied text", () => {
    expect(checkReason("  The   amount\ndoes not match.  ", required)).toEqual({ ok: true, value: "The amount does not match." });
  });
});

describe("the database's reasons", () => {
  it("are recognised by code and short message", () => {
    expect(reasonProblemFromDb("22023", "reason_too_short")).toBe("reason_too_short");
    expect(reasonProblemFromDb("22023", "reason_required")).toBe("reason_required");
    expect(reasonProblemFromDb("22023", "something else")).toBeNull();
    expect(reasonProblemFromDb("55000", "reason_too_short")).toBeNull();
    expect(isReasonProblem("reason_too_long")).toBe(true);
    expect(isReasonProblem("nope")).toBe(false);
  });
});

describe("withPreset", () => {
  it("fills an empty field, appends to a written one, and never repeats or overflows", () => {
    expect(withPreset("", "The receipt is unreadable.", 500)).toBe("The receipt is unreadable.");
    expect(withPreset("   ", "The receipt is unreadable.", 500)).toBe("The receipt is unreadable.");
    expect(withPreset("Sorry.", "The receipt is unreadable.", 500)).toBe("Sorry. The receipt is unreadable.");
    expect(withPreset("The receipt is unreadable. Thanks", "The receipt is unreadable.", 500)).toBe("The receipt is unreadable. Thanks");
    expect(withPreset("x".repeat(490), "The receipt is unreadable.", 500)).toBe("x".repeat(490));
  });
});
