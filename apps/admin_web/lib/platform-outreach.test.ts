import { describe, expect, it } from "vitest";

import { en, fr } from "./i18n/messages";
import { parseSignal, type Signal } from "./platform-health";
import {
  isPortalPath,
  mailtoHref,
  messageCopy,
  parseContacts,
  parseSchoolOutreach,
  readyMessage,
  signalPath,
  whatsappHref,
} from "./platform-outreach";

const signal = (overrides: Record<string, unknown>): Signal =>
  parseSignal({
    signal: "oldest_pending_days",
    area: "waiting",
    value: 9,
    level: 2,
    weight: 3,
    direction: "above",
    watch: 3,
    needs_help: 7,
    critical: 14,
    ...overrides,
  })!;

describe("signalPath", () => {
  it("leads to the page that fixes the signal", () => {
    expect(signalPath(signal({}))).toBe("/subscriptions");
    expect(signalPath(signal({ signal: "oldest_request_days" }))).toBe("/people?role=verify");
    expect(signalPath(signal({ signal: "setup_missing", area: "setup", detail: ["billing", "route"] }))).toBe("/billing");
    expect(signalPath(signal({ signal: "setup_missing", area: "setup", detail: [] }))).toBe("/profile");
  });
});

describe("readyMessage", () => {
  const signals = [signal({}), signal({ signal: "profile_missing", area: "profile", value: 2, detail: ["logo", "website"] })];

  it("writes the message in English with one line per signal and its page", () => {
    const m = readyMessage("ICT University", signals, messageCopy(en), "en", "https://busin.example/");
    expect(m.subject).toBe("BusIn: a few things for ICT University");
    expect(m.body).toContain("Hello ICT University team,");
    expect(m.body).toContain("- A request with its proof has waited 9 days. Students are waiting for an answer: review them in Subscriptions. https://busin.example/subscriptions");
    expect(m.body).toContain("- 2 missing: logo, website.");
    expect(m.body.endsWith("The BusIn team")).toBe(true);
    expect(m.link).toBe("/subscriptions");
    expect(m.notice.startsWith("A reminder from BusIn:\nA request with its proof has waited 9 days.")).toBe(true);
  });

  it("writes it in French whatever the console's language", () => {
    const m = readyMessage("ICT University", signals, messageCopy(fr), "fr", "https://busin.example");
    expect(m.subject).toBe("BusIn : quelques points pour ICT University");
    expect(m.body).toContain("Une demande avec sa preuve attend depuis 9 jours.");
    expect(m.body).toContain("2 manquants : logo, site web.");
  });

  it("checks in without signals", () => {
    const m = readyMessage("A", [], messageCopy(en), "en", "https://busin.example");
    expect(m.body).toContain("We are checking in from BusIn to see how things are going.");
    expect(m.link).toBeNull();
  });

  it("keeps the notice within 600 characters", () => {
    const many = Array.from({ length: 14 }, () => signal({}));
    expect(readyMessage("A", many, messageCopy(en), "en", "https://b").notice.length).toBeLessThanOrEqual(600);
  });
});

describe("links that open the message", () => {
  it("opens the owner's email with subject and body", () => {
    expect(mailtoHref("office@a.edu", "Hi there", "Line 1\nLine 2")).toBe("mailto:office%40a.edu?subject=Hi%20there&body=Line%201%0ALine%202");
  });
  it("opens WhatsApp for an E.164 number, and refuses a number it cannot use", () => {
    expect(whatsappHref("+237 677 00 00 01", "Hello")).toBe("https://wa.me/237677000001?text=Hello");
    expect(whatsappHref("12", "Hello")).toBeNull();
  });
});

describe("isPortalPath", () => {
  it("accepts a page of the portal only", () => {
    expect(isPortalPath("/people?role=verify")).toBe(true);
    expect(isPortalPath("https://evil.example")).toBe(false);
    expect(isPortalPath("//evil")).toBe(false);
    expect(isPortalPath("/")).toBe(true);
    expect(isPortalPath("/Subscriptions")).toBe(false);
  });
});

describe("parseContacts", () => {
  it("lists the school first, then administrators that can be reached", () => {
    const contacts = parseContacts(
      {
        email: "office@a.edu",
        phone: "+237677000001",
        phone_secondary: "+237677000002",
        admins: [{ name: "Ada", email: "ada@a.edu", phone: null }, { name: "Nobody", email: null, phone: null }],
      },
      { school: "School", admin: "Administrator" },
    );
    expect(contacts.map((c) => [c.label, c.name, c.email, c.phone])).toEqual([
      ["School", null, "office@a.edu", "+237677000001"],
      ["School", null, null, "+237677000002"],
      ["Administrator", "Ada", "ada@a.edu", null],
    ]);
  });
});

describe("parseSchoolOutreach", () => {
  it("reads the history and the paused signals", () => {
    const outreach = parseSchoolOutreach({
      log: [
        { id: "o1", channel: "notice", signals: ["oldest_pending_days"], created_at: "2026-11-16T08:00:00Z", snooze_until: "2026-11-23" },
        { id: "o2", channel: "pigeon", created_at: "2026-11-16T08:00:00Z" },
      ],
      snoozed: { oldest_pending_days: { until: "2026-11-23", contacted_at: "2026-11-16T08:00:00Z" }, broken: {} },
    });
    expect(outreach.log).toHaveLength(1);
    expect(outreach.log[0]).toMatchObject({ channel: "notice", snoozeUntil: "2026-11-23" });
    expect(Object.keys(outreach.snoozed)).toEqual(["oldest_pending_days"]);
  });
});
