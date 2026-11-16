import { describe, expect, it } from "vitest";

import { deletionBack, deletionErrorKey, parseScheduled } from "./account-deletion";
import { deletionCatalogues } from "./i18n/account-deletion";

describe("parseScheduled", () => {
  it("reads a scheduled deletion and who asked", () => {
    expect(parseScheduled([{ due_at: "2026-11-23T08:00:00Z", requested_by: "platform" }])).toEqual({ dueAt: "2026-11-23T08:00:00Z", by: "platform" });
    expect(parseScheduled([{ due_at: "2026-11-23T08:00:00Z", requested_by: "self" }])?.by).toBe("self");
  });
  it("is null when nothing is scheduled", () => {
    expect(parseScheduled([])).toBeNull();
    expect(parseScheduled(null)).toBeNull();
  });
});

describe("deletionErrorKey and deletionBack", () => {
  it("keeps the refusals it explains", () => {
    expect(deletionErrorKey("last_admin")).toBe("last_admin");
    expect(deletionErrorKey("active_trip")).toBe("active_trip");
    expect(deletionErrorKey("boom")).toBe("generic");
  });
  it("only sends back to a profile page", () => {
    expect(deletionBack("/profile")).toBe("/profile");
    expect(deletionBack("https://evil.example")).toBe("/app/profile");
    expect(deletionBack(null)).toBe("/app/profile");
  });
});

describe("the deletion copy", () => {
  it("says the same things in English and French", () => {
    expect(deletionCatalogues.fr.confirm.erased).toHaveLength(deletionCatalogues.en.confirm.erased.length);
    expect(deletionCatalogues.fr.page.steps).toHaveLength(deletionCatalogues.en.page.steps.length);
  });
});
