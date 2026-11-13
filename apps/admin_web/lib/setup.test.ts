import { describe, expect, it } from "vitest";

import { setupSteps } from "./setup";

describe("getting a school started", () => {
  const none = { semesters: 0, stops: 0, buses: 0, staff: 0, trips: 0 };

  it("lists the five steps in order, none done, for a new school", () => {
    const steps = setupSteps(none)!;
    expect(steps.map((s) => s.key)).toEqual(["semester", "stops", "buses", "staff", "trip"]);
    expect(steps.every((s) => !s.done)).toBe(true);
  });

  it("ticks what is there and is gone once everything is", () => {
    expect(setupSteps({ ...none, stops: 6 })!.find((s) => s.key === "stops")!.done).toBe(true);
    expect(setupSteps({ semesters: 1, stops: 6, buses: 2, staff: 3, trips: 1 })).toBeNull();
  });

  it("adding a bus from here comes back to the overview", () => {
    expect(setupSteps(none)!.find((s) => s.key === "buses")!.href).toBe("/buses/new?next=%2F");
  });
});
