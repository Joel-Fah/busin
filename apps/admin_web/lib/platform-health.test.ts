import { describe, expect, it } from "vitest";

import { en, fr } from "./i18n/messages";
import {
  levelCounts,
  levelFromParam,
  needingAttention,
  parseSchoolDetail,
  parseSchoolRows,
  parseSignal,
  signalSentence,
  signalValue,
  thresholdsText,
  type SchoolHealthRow,
} from "./platform-health";

const pending = {
  signal: "oldest_pending_days",
  area: "waiting",
  value: 9.4,
  level: 2,
  weight: 3,
  direction: "above",
  watch: 3,
  needs_help: 7,
  critical: 14,
  graced: false,
  detail: null,
};

describe("parseSignal", () => {
  it("reads a signal", () => {
    expect(parseSignal(pending)).toMatchObject({ signal: "oldest_pending_days", value: 9.4, level: 2, needsHelp: 7, detail: [] });
  });
  it("leaves out a signal it does not know, and keeps a missing value as null", () => {
    expect(parseSignal({ ...pending, signal: "from_the_future" })).toBeNull();
    expect(parseSignal({ ...pending, value: null })?.value).toBeNull();
  });
});

describe("signalSentence", () => {
  it("says the value in a plain sentence, in each language", () => {
    const signal = parseSignal(pending)!;
    expect(signalSentence(signal, en.platform.health, "en")).toBe("A request with its proof has waited 9.4 days");
    expect(signalSentence(signal, fr.platform.health, "fr")).toBe("Une demande avec sa preuve attend depuis 9,4 jours");
  });
  it("names what is missing", () => {
    const signal = parseSignal({ ...pending, signal: "setup_missing", area: "setup", value: 2, detail: ["billing", "route"] })!;
    expect(signalSentence(signal, en.platform.health, "en")).toBe("2 missing: price, route");
    expect(signalSentence({ ...signal, value: 0, detail: [] }, fr.platform.health, "fr")).toBe("Rien ne manque");
  });
  it("says when a signal does not apply, and when the last semester has ended", () => {
    expect(signalSentence(parseSignal({ ...pending, value: null })!, en.platform.health, "en")).toBe("No request waiting");
    const ended = parseSignal({ ...pending, signal: "semester_days_left", area: "setup", value: -1, direction: "below" })!;
    expect(signalSentence(ended, en.platform.health, "en")).toBe("The last semester has ended and none follows");
  });
  it("words the thresholds with their unit", () => {
    expect(thresholdsText(parseSignal(pending)!, en.platform.health, "en")).toBe("Watch above 3, needs help above 7, critical above 14 (days)");
    const pct = parseSignal({ ...pending, signal: "scanned_trips_pct", direction: "below", watch: 80, needs_help: 50, critical: 20 })!;
    expect(thresholdsText(pct, en.platform.health, "en")).toBe("Watch below 80, needs help below 50, critical below 20 (%)");
  });
});

describe("parseSchoolRows and the attention list", () => {
  const rows = parseSchoolRows([
    { id: "a", name: "Alpha", status: "active", level: 1, score: 90, reasons: [pending] },
    { id: "b", name: "Beta", status: "active", level: 3, score: 40, reasons: [] },
    { id: "c", name: "Gamma", status: "active", level: 2, score: 55 },
    { id: "d", name: "Delta", status: "active", level: 3, score: 20 },
    { id: "e", name: "Off", status: "inactive", level: 3, score: 0 },
    { name: "No id" },
  ]);

  it("reads every school, and a switched-off school has no level", () => {
    expect(rows).toHaveLength(5);
    expect(rows[0].reasons[0].signal).toBe("oldest_pending_days");
    expect(rows.find((r) => r.id === "e")?.level).toBeNull();
  });

  it("lists Critical then Needs help, the lowest score first", () => {
    expect(needingAttention(rows).map((r: SchoolHealthRow) => r.id)).toEqual(["d", "b", "c"]);
  });

  it("leaves out a school whose serious signals are all paused after a contact", () => {
    const paused = parseSchoolRows([
      { id: "p", name: "Paused", status: "active", level: 2, score: 50, reasons: [pending], snoozed: { oldest_pending_days: { until: "2026-11-23" } }, last_outreach_at: "2026-11-16T08:00:00Z" },
      { id: "q", name: "Partly", status: "active", level: 2, score: 50, reasons: [pending, { ...pending, signal: "answer_time_days" }], snoozed: { oldest_pending_days: { until: "2026-11-23" } } },
    ]);
    expect(paused[0].snoozed).toEqual({ oldest_pending_days: "2026-11-23" });
    expect(paused[0].lastOutreachAt).toBe("2026-11-16T08:00:00Z");
    expect(needingAttention(paused).map((r) => r.id)).toEqual(["q"]);
  });

  it("counts the schools at each level", () => {
    expect(levelCounts(rows)).toEqual({ byLevel: [0, 1, 1, 2], off: 1 });
  });
});

describe("levelFromParam", () => {
  it("reads a level from the address", () => {
    expect(levelFromParam("critical")).toBe(3);
    expect(levelFromParam(["needsHelp"])).toBe(2);
    expect(levelFromParam("ok")).toBe(0);
    expect(levelFromParam("bogus")).toBeNull();
    expect(levelFromParam(undefined)).toBeNull();
  });
});

describe("parseSchoolDetail", () => {
  it("reads a school page", () => {
    const detail = parseSchoolDetail({
      school: { id: "a", name: "Alpha", status: "active", domains: ["a.edu", 4], accepts_open_signup: true },
      counts: { students: 12, staff: 2, admins: 1 },
      level: 2,
      score: 61,
      signals: [pending],
      history: [{ day: "2026-11-15", level: 1, score: 80 }, { day: "bad" }],
      admin_actions: [{ action: "subscription.approved", at: "2026-11-15T08:00:00Z" }, { action: "x" }],
    });
    expect(detail).toMatchObject({ domains: ["a.edu"], acceptsOpenSignup: true, level: 2, score: 61, counts: { students: 12 } });
    expect(detail?.history).toHaveLength(1);
    expect(detail?.adminActions).toHaveLength(1);
  });
  it("is null for an unknown school", () => {
    expect(parseSchoolDetail(null)).toBeNull();
  });
});

describe("signalValue", () => {
  const base = parseSignal(pending)!;
  it("says the value in a few words", () => {
    expect(signalValue(base, en.platform.health, "en")).toBe("9.4 days");
    expect(signalValue({ ...base, value: 1 }, en.platform.health, "en")).toBe("1 day");
    expect(signalValue({ ...base, signal: "scanned_trips_pct", value: 89 }, en.platform.health, "en")).toBe("89%");
    expect(signalValue({ ...base, signal: "scanned_trips_pct", value: 89 }, fr.platform.health, "fr")).toBe("89 %");
    expect(signalValue({ ...base, signal: "new_students_change_pct", value: 12 }, en.platform.health, "en")).toBe("+12%");
    expect(signalValue({ ...base, signal: "setup_missing", value: 2 }, en.platform.health, "en")).toBe("2 missing");
    expect(signalValue({ ...base, signal: "profile_missing", value: 0 }, en.platform.health, "en")).toBe("Complete");
    expect(signalValue({ ...base, signal: "semester_days_left", value: -1 }, en.platform.health, "en")).toBe("Ended");
    expect(signalValue({ ...base, signal: "admin_idle_days", value: 0 }, en.platform.health, "en")).toBe("Today");
    expect(signalValue({ ...base, value: null }, en.platform.health, "en")).toBe("No data");
  });
});
