import { describe, expect, it } from "vitest";

import { RADIUS, innerRadius, outerRadius } from "./radius";

describe("innerRadius", () => {
  it("subtracts the gap from the outer radius", () => {
    expect(innerRadius(RADIUS.lg, 16)).toBe(12);
    expect(innerRadius(RADIUS.md, 6)).toBe(14);
  });

  it("never goes below zero", () => {
    expect(innerRadius(8, 20)).toBe(0);
  });
});

describe("RADIUS", () => {
  it("grows in order so a larger name is always rounder", () => {
    const values = Object.values(RADIUS);
    expect([...values].sort((a, b) => a - b)).toEqual(values);
  });
});

describe("outerRadius", () => {
  it("is the inverse of innerRadius", () => {
    expect(innerRadius(outerRadius(12, 16), 16)).toBe(12);
  });
});
