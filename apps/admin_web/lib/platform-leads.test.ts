import { describe, expect, it } from "vitest";

import { kindFromParam, leadsHref, parseLeadCounts, parseLeads, statusFromParam } from "./platform-leads";

describe("parseLeads", () => {
  it("reads a page of leads and the total", () => {
    const { leads, total } = parseLeads([
      { id: "l1", kind: "school", name: "Ama", organisation: "Test College", email: "ama@x.org", locale: "fr", created_at: "2026-11-15T08:00:00Z", status: "contacted", total: 42 },
      { id: "l2", kind: "weird", email: "x@y.org", created_at: "2026-11-15T08:00:00Z", total: 42 },
    ]);
    expect(total).toBe(42);
    expect(leads).toHaveLength(1);
    expect(leads[0]).toMatchObject({ organisation: "Test College", locale: "fr", status: "contacted", note: null });
  });
  it("is empty for nothing", () => {
    expect(parseLeads(null)).toEqual({ leads: [], total: 0 });
  });
});

describe("filters", () => {
  it("reads the kind and status from the address", () => {
    expect(kindFromParam("notify")).toBe("notify");
    expect(kindFromParam("bogus")).toBe("school");
    expect(statusFromParam(["new"])).toBe("new");
    expect(statusFromParam("won")).toBeNull();
  });
  it("builds the address back", () => {
    expect(leadsHref("school", null)).toBe("/platform/leads?kind=school");
    expect(leadsHref("notify", "new", 3)).toBe("/platform/leads?kind=notify&status=new&page=3");
  });
});

describe("parseLeadCounts", () => {
  it("counts by kind, and by kind and status", () => {
    const counts = parseLeadCounts({ "school:new": 3, "school:contacted": 2, "notify:new": 40 });
    expect(counts.byKind).toEqual({ school: 5, notify: 40, deletion: 0 });
    expect(counts.get("school", "new")).toBe(3);
    expect(counts.get("school", "dismissed")).toBe(0);
  });
});
