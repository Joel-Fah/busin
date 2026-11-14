import { describe, expect, it } from "vitest";

import { callingCode, countryOfPhone, defaultPhoneCountry, displayPhone, isE164, parsePhone } from "./phone";

describe("phone numbers (ADR 0024)", () => {
  it("stores a Cameroonian number typed in any usual way in one form", () => {
    for (const typed of ["677 12 34 56", "677123456", "0677123456", "+237 677-123-456", "+237677123456"]) {
      expect(parsePhone(typed, "CM").e164, typed).toBe("+237677123456");
    }
  });

  it("keeps a number's own country when it starts with +, and drops a national 0", () => {
    expect(parsePhone("+33 6 12 34 56 78", "CM").e164).toBe("+33612345678");
    expect(parsePhone("06 12 34 56 78", "FR").e164).toBe("+33612345678");
    expect(parsePhone("07400 123456", "GB").e164).toBe("+447400123456");
    expect(parsePhone("07911 123456", "GB").e164, "+44 is shared with Guernsey").toBe("+447911123456");
  });

  it("refuses empty, letters and numbers that do not exist", () => {
    expect(parsePhone("  ", "CM").problem).toBe("empty");
    expect(parsePhone("call me", "CM").problem).toBe("invalid");
    expect(parsePhone("12345", "CM").problem).toBe("invalid");
    expect(parsePhone("1".repeat(16), "CM").problem).toBe("invalid");
  });

  it("shows a stored number with spaces, and reads its country", () => {
    expect(displayPhone("+237677123456").replace(/\s/g, "")).toBe("+237677123456");
    expect(displayPhone("+237677123456")).toMatch(/^\+237 6/);
    expect(isE164("+237 677")).toBe(false);
    expect(countryOfPhone("+33612345678")).toBe("FR");
    expect(callingCode("CM")).toBe("237");
  });

  it("starts the field on the saved number, the school, the browser, then the fallback", () => {
    expect(defaultPhoneCountry({ saved: "+33612345678", schoolPhone: "+237677123456" })).toBe("FR");
    expect(defaultPhoneCountry({ schoolPhone: "+237677123456", region: "US" })).toBe("CM");
    expect(defaultPhoneCountry({ region: "ng" })).toBe("NG");
    expect(defaultPhoneCountry({})).toBe("CM");
  });
});
