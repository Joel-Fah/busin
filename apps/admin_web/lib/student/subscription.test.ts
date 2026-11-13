import { describe, expect, it } from "vitest";

import { buildRequestHistory, proofPath, sniffImageType, stageOf, subscribeProblem, subscriptionToShow, uploadProblem, type SubscriptionRow } from "./subscription";

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
