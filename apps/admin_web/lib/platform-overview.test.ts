import { describe, expect, it } from "vitest";

import { daysSince, parsePlatformOverview } from "./platform-overview";

describe("parsePlatformOverview", () => {
  it("reads the totals and the schools", () => {
    const overview = parsePlatformOverview({
      totals: { schools_active: 2, schools_inactive: 1, students: 340, scans_today: "57", buses_live: 3 },
      schools: [
        {
          id: "s1",
          name: "School A",
          short_name: "SA",
          logo_path: null,
          status: "active",
          created_at: "2026-11-01T00:00:00Z",
          students: 300,
          staff: 4,
          admins: 2,
          waiting_to_join: 5,
          subscriptions_pending: 12,
          trips_active: 1,
          last_admin_action_at: "2026-11-15T08:00:00Z",
        },
        { id: "s2", name: "School B", status: "inactive" },
      ],
    });
    expect(overview.totals.schoolsActive).toBe(2);
    expect(overview.totals.scansToday).toBe(57);
    expect(overview.totals.tripsActive).toBe(0);
    expect(overview.schools).toHaveLength(2);
    expect(overview.schools[0]).toMatchObject({ shortName: "SA", active: true, students: 300, subscriptionsPending: 12 });
    expect(overview.schools[1]).toMatchObject({ active: false, students: 0, lastAdminActionAt: null });
  });

  it("never fails on a malformed answer", () => {
    expect(parsePlatformOverview(null)).toEqual(parsePlatformOverview({}));
    const odd = parsePlatformOverview({ totals: { students: -4, staff: "many" }, schools: [{ name: "No id" }, 7, null] });
    expect(odd.totals.students).toBe(0);
    expect(odd.totals.staff).toBe(0);
    expect(odd.schools).toEqual([]);
  });
});

describe("daysSince", () => {
  const now = new Date("2026-11-16T12:00:00Z");
  it("counts whole days", () => {
    expect(daysSince("2026-11-13T13:00:00Z", now)).toBe(2);
    expect(daysSince("2026-11-16T11:00:00Z", now)).toBe(0);
  });
  it("is null without a readable moment", () => {
    expect(daysSince(null, now)).toBeNull();
    expect(daysSince("soon", now)).toBeNull();
  });
});
