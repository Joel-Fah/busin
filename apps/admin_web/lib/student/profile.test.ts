import { describe, expect, it } from "vitest";

import { checkFullName, checkMatricule, checkPhone, normalizePhone } from "./profile";

// The same cases as packages/busin_core/test/profile_validation_test.dart, so both clients accept the same input.
describe("what a student types about themselves", () => {
  it("needs a name of 2 to 80 characters", () => {
    expect(checkFullName("  ")).toBe("empty");
    expect(checkFullName("A")).toBe("tooShort");
    expect(checkFullName("A".repeat(81))).toBe("tooLong");
    expect(checkFullName(" Amara Ngono ")).toBeNull();
  });

  it("needs a student number of letters, digits and simple separators", () => {
    expect(checkMatricule("")).toBe("empty");
    expect(checkMatricule("IC")).toBe("tooShort");
    expect(checkMatricule("X".repeat(33))).toBe("tooLong");
    expect(checkMatricule("-ICT2026")).toBe("invalid");
    expect(checkMatricule("ICT2026@1")).toBe("invalid");
    expect(checkMatricule("ICT2026-0001")).toBeNull();
    expect(checkMatricule("ict/2026.01 b")).toBeNull();
  });

  it("needs a phone number of 8 to 15 digits", () => {
    expect(checkPhone("")).toBe("empty");
    expect(checkPhone("677 12 34 5a")).toBe("invalid");
    expect(checkPhone("677 12")).toBe("tooShort");
    expect(checkPhone("+1234567890123456")).toBe("tooLong");
    expect(checkPhone("677 12 34 56")).toBeNull();
    expect(checkPhone("+237 (677) 12-34.56")).toBeNull();
  });

  it("stores a phone number as the plus and digits only", () => {
    expect(normalizePhone(" +237 677-12.34 56 ")).toBe("+237677123456");
    expect(normalizePhone("677 12 34 56")).toBe("677123456");
  });
});
