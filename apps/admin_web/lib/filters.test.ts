import { describe, expect, it } from "vitest";

import { VALUE_TOKEN, choiceParam, fillHref, listHref, uuidParam } from "./filters";

const ID = "a1000000-0000-4000-8000-000000000001";

describe("listHref", () => {
  it("leaves out empty parameters", () => {
    expect(listHref("/trips", {})).toBe("/trips");
    expect(listHref("/trips", { status: null, bus: "", page: undefined })).toBe("/trips");
  });

  it("keeps the others, in order, and encodes them", () => {
    expect(listHref("/trips", { status: "active", bus: ID, page: 2 })).toBe(`/trips?status=active&bus=${ID}&page=2`);
    expect(listHref("/trips", { date: "2026-11-04", q: "a b" })).toBe("/trips?date=2026-11-04&q=a+b");
  });
});

describe("uuidParam", () => {
  it("accepts an id and refuses the rest", () => {
    expect(uuidParam(ID)).toBe(ID);
    expect(uuidParam([ID, "x"])).toBe(ID);
    expect(uuidParam("nope")).toBeNull();
    expect(uuidParam("none")).toBeNull();
    expect(uuidParam(undefined)).toBeNull();
  });
});

describe("choiceParam", () => {
  it("accepts only the allowed values", () => {
    expect(choiceParam("inbound", ["inbound", "outbound"])).toBe("inbound");
    expect(choiceParam("sideways", ["inbound", "outbound"])).toBeNull();
    expect(choiceParam(undefined, ["inbound"])).toBeNull();
  });
});

describe("fillHref", () => {
  it("swaps the placeholder for the encoded value", () => {
    expect(fillHref(`/scans?date=${VALUE_TOKEN}`, "2026-11-04")).toBe("/scans?date=2026-11-04");
    expect(fillHref(`/x?q=${VALUE_TOKEN}`, "a&b")).toBe("/x?q=a%26b");
  });
});
