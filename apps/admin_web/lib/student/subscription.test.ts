import { describe, expect, it } from "vitest";

import { buildRequestHistory, closestStop, liveRequests, monthChoices, proofPath, stopsWithDistance, sniffImageType, stageOf, stillRunning, subscribeProblem, subscriptionToShow, uploadProblem, type SubscriptionRow } from "./subscription";

const row = (id: string, status: SubscriptionRow["status"], created_at: string, semester_id = "sem"): SubscriptionRow => ({
  id,
  semester_id,
  stop_id: "stop",
  status,
  proof_path: null,
  review_note: null,
  created_at,
});

describe("the subscription tab", () => {
  it("shows the live request of the semester first, else the newest", () => {
    const mine = [row("c", "rejected", "2026-11-03"), row("b", "pending", "2026-11-02"), row("a", "rejected", "2026-11-01")];
    expect(subscriptionToShow(mine, "sem")?.id).toBe("b");
    expect(subscriptionToShow([row("c", "rejected", "2026-11-03"), row("a", "expired", "2026-11-01")], "sem")?.id).toBe("c");
    expect(subscriptionToShow([row("x", "approved", "2026-11-03", "other")], "sem")).toBeNull();
  });

  it("lists requests and what happened to them, latest first", () => {
    const history = buildRequestHistory(
      [row("a", "rejected", "2026-11-01"), row("b", "approved", "2026-11-02")],
      [
        { id: 1, subscription_id: "a", action: "requested", note: null, created_at: "2026-11-01T08:00:00Z" },
        { id: 2, subscription_id: "a", action: "rejected", note: "Blurry", created_at: "2026-11-01T09:00:00Z" },
        { id: 3, subscription_id: "b", action: "requested", note: null, created_at: "2026-11-02T08:00:00Z" },
      ],
    );
    expect(history.map((r) => r.subscription.id)).toEqual(["b", "a"]);
    expect(history[1].events.map((e) => e.action)).toEqual(["rejected", "requested"]);
  });

  it("knows how far a request got", () => {
    expect(stageOf("pending")).toEqual({ reached: 1, failed: false });
    expect(stageOf("rejected")).toEqual({ reached: 2, failed: true });
    expect(stageOf("approved")).toEqual({ reached: 3, failed: false });
  });

  it("tells a photo's real type from its first bytes", () => {
    expect(sniffImageType(new Uint8Array([0xff, 0xd8, 0xff, 0xe0]))).toBe("image/jpeg");
    expect(sniffImageType(new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))).toBe("image/png");
    expect(sniffImageType(new TextEncoder().encode("RIFF\0\0\0\0WEBPVP8 "))).toBe("image/webp");
    expect(sniffImageType(new TextEncoder().encode("\0\0\0\x18ftypheic"))).toBeNull();
    expect(sniffImageType(new TextEncoder().encode("%PDF-1.7"))).toBeNull();
  });

  it("puts a proof in the student's own folder with a random name", () => {
    expect(proofPath("school", "me", "ab12", "image/jpeg")).toBe("school/me/ab12.jpg");
    expect(proofPath("school", "me", "ab12", "image/webp")).toBe("school/me/ab12.webp");
  });

  it("explains a refused request in the student's terms", () => {
    expect(subscribeProblem({ code: "55000", message: "semester_ended" })).toBe("ended");
    expect(subscribeProblem({ code: "22023", message: "proof_missing" })).toBe("proof");
    expect(subscribeProblem({ code: "23503", message: "violates foreign key" })).toBe("unavailable");
    expect(subscribeProblem({ code: "23505", message: "duplicate key" })).toBe("exists");
    expect(subscribeProblem({ code: "42501", message: "denied" })).toBe("failed");
    expect(uploadProblem({ statusCode: "413", message: "Payload too large" })).toBe("tooLarge");
    expect(uploadProblem({ statusCode: "415", message: "mime type not supported" })).toBe("type");
  });
});

describe("monthly billing (ADR 0022)", () => {
  const month = (id: string, start: string, end: string, status: SubscriptionRow["status"] = "approved"): SubscriptionRow => ({
    ...row(id, status, `${start}T08:00:00Z`),
    period_start: start,
    period_end: end,
  });
  const fall = { start_date: "2026-09-01", end_date: "2027-01-31" };

  it("offers this month and the next inside the semester, not one already asked for", () => {
    expect(monthChoices(fall, "2026-11-14", [])).toEqual(["2026-11-01", "2026-12-01"]);
    expect(monthChoices(fall, "2026-11-14", [{ period_start: "2026-11-01" }])).toEqual(["2026-12-01"]);
    expect(monthChoices(fall, "2027-01-20", []), "February is after the semester").toEqual(["2027-01-01"]);
    expect(monthChoices(fall, "2026-12-05", [])).toEqual(["2026-12-01", "2027-01-01"]);
  });

  it("shows the running month first, and nothing once a month has ended", () => {
    const nov = month("nov", "2026-11-01", "2026-11-30");
    const dec = month("dec", "2026-12-01", "2026-12-31", "pending");
    expect(subscriptionToShow([dec, nov], "sem", "2026-11-14")?.id).toBe("nov");
    expect(liveRequests([dec, nov], "2026-11-14").map((s) => s.id)).toEqual(["nov", "dec"]);
    expect(subscriptionToShow([month("oct", "2026-10-01", "2026-10-31")], "sem", "2026-11-01")).toBeNull();
    expect(stillRunning(nov, "2026-11-30")).toBe(true);
    expect(stillRunning(nov, "2026-12-01")).toBe(false);
  });

  it("explains the billing refusals", () => {
    expect(subscribeProblem({ code: "55000", message: "billing_not_set" })).toBe("billing");
    expect(subscribeProblem({ code: "55000", message: "period_ended" })).toBe("periodEnded");
    expect(subscribeProblem({ code: "22023", message: "month_not_allowed" })).toBe("unavailable");
    expect(subscribeProblem({ code: "23505", message: "already_requested" })).toBe("exists");
  });
});

describe("receipts in the history (ADR 0022)", () => {
  it("keeps every receipt of a part with its decision, merged with the operations, the latest first", () => {
    const sub = { ...row("a", "approved", "2026-11-01T08:00:00Z"), payment_mode: "installments" };
    const history = buildRequestHistory(
      [sub],
      [{ id: 1, subscription_id: "a", action: "requested", note: null, created_at: "2026-11-01T08:00:00Z" }],
      [
        { id: "r1", subscription_id: "a", seq: 2, proof_path: "s/u/1.jpg", sent_at: "2026-11-02T08:00:00Z", decision: "rejected", note: "Blurry", decided_at: "2026-11-03T08:00:00Z" },
        { id: "r2", subscription_id: "a", seq: 2, proof_path: "s/u/2.jpg", sent_at: "2026-11-04T08:00:00Z", decision: "paid", note: null, decided_at: "2026-11-05T08:00:00Z" },
        { id: "r3", subscription_id: "a", seq: 3, proof_path: null, sent_at: "2026-11-06T08:00:00Z", decision: "paid", note: null, decided_at: "2026-11-06T08:00:00Z" },
      ],
    );
    expect(history[0].events.map((e) => `${e.action}${e.seq ?? ""}`)).toEqual(["partPaid3", "partPaid2", "partSent2", "partRejected2", "partSent2", "requested"]);
    expect(history[0].events.find((e) => e.action === "partRejected")?.note).toBe("Blurry");
  });
});

describe("the closest stop", () => {
  const stops = [
    { id: "far", position: { lat: 3.83, lng: 11.49 } },
    { id: "near", position: { lat: 3.89, lng: 11.51 } },
    { id: "unknown", position: null },
  ];
  it("says how far each stop is by road from the area, and points out the nearest without reordering", () => {
    const ranked = stopsWithDistance(stops, { lat: 3.88, lng: 11.51 });
    expect(ranked.map((r) => r.stop.id)).toEqual(["far", "near", "unknown"]);
    expect(ranked[1].km).toBeCloseTo(1.4, 1);
    expect(ranked[2].km).toBeNull();
    expect(closestStop(ranked)?.stop.id).toBe("near");
  });
  it("suggests nothing without an area", () => {
    expect(closestStop(stopsWithDistance(stops, null))).toBeNull();
  });
});
