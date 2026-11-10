import { describe, expect, it } from "vitest";

import { downloads, httpsUrl } from "./downloads";
import { checkInterest, isInterestKind, outcomeOf } from "./interest";

describe("download links", () => {
  it("only accepts https addresses", () => {
    expect(httpsUrl("https://example.com/busin.apk")).toBe("https://example.com/busin.apk");
    expect(httpsUrl(" https://play.google.com/store/apps/details?id=x ")).toContain("play.google.com");
    expect(httpsUrl("http://example.com/busin.apk")).toBeNull();
    expect(httpsUrl("javascript:alert(1)")).toBeNull();
    expect(httpsUrl("not a url")).toBeNull();
    expect(httpsUrl("")).toBeNull();
    expect(httpsUrl(undefined)).toBeNull();
  });

  it("reads each setting on its own, so one link can exist without the others", () => {
    expect(downloads({ LANDING_PLAY_URL: "https://play.google.com/x" })).toEqual({ apk: null, play: "https://play.google.com/x", ios: null });
    expect(downloads({})).toEqual({ apk: null, play: null, ios: null });
  });
});

describe("the interest form", () => {
  it("knows its three kinds", () => {
    expect(isInterestKind("school")).toBe(true);
    expect(isInterestKind("notify_ios")).toBe(true);
    expect(isInterestKind("admin")).toBe(false);
  });

  it("asks only for an address to be told about a release", () => {
    expect(checkInterest({ kind: "notify_android", email: "ama@example.com" })).toEqual({});
    expect(checkInterest({ kind: "notify_ios", email: "" })).toEqual({ email: "required" });
    expect(checkInterest({ kind: "notify_ios", email: "ama@" })).toEqual({ email: "email" });
  });

  it("asks a school for a name and the school as well", () => {
    expect(checkInterest({ kind: "school", email: "head@school.example" })).toEqual({ name: "required", organisation: "required" });
    expect(checkInterest({ kind: "school", email: "head@school.example", name: "Ada", organisation: "Hill School", message: "Hello" })).toEqual({});
  });

  it("refuses text past the limits the database keeps", () => {
    const problems = checkInterest({ kind: "school", email: "a@b.example", name: "x".repeat(81), organisation: "y".repeat(121), message: "z".repeat(1001) });
    expect(problems).toEqual({ name: "long", organisation: "long", message: "long" });
  });

  it("turns the database's answer into what the form shows", () => {
    expect(outcomeOf({ data: "stored", error: null })).toBe("stored");
    expect(outcomeOf({ data: "already", error: null })).toBe("already");
    expect(outcomeOf({ data: null, error: { code: "22023" } })).toBe("invalid");
    expect(outcomeOf({ data: null, error: { code: "54000" } })).toBe("busy");
    expect(outcomeOf({ data: null, error: { code: "08006" } })).toBe("failed");
    expect(outcomeOf({ data: "odd", error: null })).toBe("failed");
  });
});
