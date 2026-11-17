import { describe, expect, it } from "vitest";

import { PLAN_LIMITS, bytesText, failingJobs, parseSystemHealth, pressure, scheduleText, systemAttention } from "./platform-system";

const copy = { everyMinute: "Every minute", hourly: "Every hour at :{minute}", daily: "Every day at {time} UTC", other: "{cron}" };

describe("pressure", () => {
  it("warns at 80 % and 95 %", () => {
    expect(pressure(79, 100)).toBe(0);
    expect(pressure(80, 100)).toBe(1);
    expect(pressure(95, 100)).toBe(2);
    expect(pressure(5, 0)).toBe(0);
  });
});

describe("bytesText", () => {
  it("reads sizes", () => {
    expect(bytesText(512, "en")).toBe("512 B");
    expect(bytesText(12.4 * 1024 * 1024, "en")).toBe("12 MB");
    expect(bytesText(1.25 * 1024 * 1024 * 1024, "fr")).toBe("1,3 GB");
  });
});

describe("scheduleText", () => {
  it("words BusIn's schedules", () => {
    expect(scheduleText("* * * * *", copy)).toBe("Every minute");
    expect(scheduleText("5 * * * *", copy)).toBe("Every hour at :05");
    expect(scheduleText("20 2 * * *", copy)).toBe("Every day at 02:20 UTC");
    expect(scheduleText("0 3 * * 1", copy)).toBe("0 3 * * 1");
  });
});

describe("parseSystemHealth and attention", () => {
  const health = parseSystemHealth({
    database_bytes: PLAN_LIMITS.databaseBytes * 0.85,
    storage: [{ bucket: "proofs", bytes: 1000, files: 3 }, { bucket: "logos", bytes: 500, files: 1 }],
    accounts: { total: 400, active_30d: 120 },
    usage: { directions_month: 12, place_searches_month: 40 },
    push: { sent_7d: 30, failed_7d: 1, waiting: 2, oldest_waiting_at: "2026-11-16T07:00:00Z" },
    devices: { android: 10, ios: 2, web: 5, stale_30d: 1 },
    jobs: [
      { name: "busin-send-push", schedule: "* * * * *", last_status: "failed", failures_7d: 7, last_error: "job startup timeout" },
      { name: "busin-school-health", schedule: "20 2 * * *", last_status: null },
    ],
    quiet_trips: [{ school: "A", school_id: "s1", started_at: "2026-11-16T07:00:00Z", last_position_at: null }],
  });

  it("reads everything, with storage summed", () => {
    expect(health.storageBytes).toBe(1500);
    expect(health.jobs[0]).toMatchObject({ failures7d: 7, lastError: "job startup timeout" });
    expect(failingJobs(health.jobs).map((j) => j.name)).toEqual(["busin-send-push"]);
  });

  it("counts what needs a look: a limit near full, a failing job, a stuck push, a quiet bus", () => {
    expect(systemAttention(health, new Date("2026-11-16T08:00:00Z"))).toBe(4);
  });

  it("never fails on nothing", () => {
    expect(systemAttention(parseSystemHealth(null))).toBe(0);
  });
});
