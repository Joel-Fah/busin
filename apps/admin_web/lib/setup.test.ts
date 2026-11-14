import { describe, expect, it } from "vitest";

import { setupSteps } from "./setup";

describe("getting a school started", () => {
  const none = { semesters: 0, stops: 0, buses: 0, staff: 0, trips: 0 };

  it("lists the six steps in order, none done, for a new school", () => {
    const steps = setupSteps(none, false)!;
    expect(steps.map((s) => s.key)).toEqual(["semester", "billing", "stops", "buses", "staff", "trip"]);
    expect(steps.every((s) => !s.done)).toBe(true);
  });

  it("ticks what is there and is gone once everything is", () => {
    expect(setupSteps({ ...none, stops: 6 }, false)!.find((s) => s.key === "stops")!.done).toBe(true);
    expect(setupSteps({ semesters: 1, stops: 6, buses: 2, staff: 3, trips: 1 }, true)).toBeNull();
  });

  it("billing counts as a step until it is set", () => {
    const all = { semesters: 1, stops: 6, buses: 2, staff: 3, trips: 1 };
    expect(setupSteps(all, false)!.filter((s) => !s.done).map((s) => s.key)).toEqual(["billing"]);
    expect(setupSteps(none, true)!.find((s) => s.key === "billing")).toEqual({ key: "billing", href: "/billing", done: true });
  });

  it("adding a bus from here comes back to the overview", () => {
    expect(setupSteps(none, false)!.find((s) => s.key === "buses")!.href).toBe("/buses/new?next=%2F");
  });
});
