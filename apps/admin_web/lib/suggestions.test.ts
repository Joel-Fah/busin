import { describe, expect, it } from "vitest";

import { buildSuggestions, suggestionPosition, type SuggestionRow } from "./suggestions";

const stops = [
  { id: "s1", name: "S1", position: { lat: 3.85, lng: 11.5 } },
  { id: "s2", name: "S2", position: { lat: 3.85, lng: 11.502 } },
  { id: "s3", name: "S3", position: null },
];
const row = (r: Partial<SuggestionRow>): SuggestionRow => ({
  kind: "unused",
  stop_id: null,
  other_stop_id: null,
  place_name: null,
  lat: null,
  lng: null,
  students: null,
  metres: null,
  ...r,
});

describe("buildSuggestions", () => {
  it("names each suggestion, new stops first, and drops what it cannot place", () => {
    const list = buildSuggestions(
      [
        row({ kind: "unused", stop_id: "s3", students: 2, metres: 42 }),
        row({ kind: "close_pair", stop_id: "s1", other_stop_id: "s2", students: 6, metres: 222 }),
        row({ kind: "new_stop", place_name: "Market", lat: 3.87, lng: 11.5, students: 6, metres: 2200 }),
        row({ kind: "close_pair", stop_id: "s1", other_stop_id: "gone", students: 3, metres: 100 }),
        row({ kind: "new_stop", place_name: null, lat: 3.8, lng: 11.4, students: 9, metres: 900 }),
        row({ kind: "something else" }),
      ],
      stops,
    );
    expect(list.map((s) => s.kind)).toEqual(["new_stop", "close_pair", "unused"]);
    expect(list[0]).toMatchObject({ place: "Market", students: 6, metres: 2200 });
    expect(list[1]).toMatchObject({ a: { name: "S1" }, b: { name: "S2" }, metres: 222 });
    expect(list[2]).toMatchObject({ stop: { name: "S3" }, weeks: 6 });
  });
});

describe("suggestionPosition", () => {
  it("is the place, the middle of a pair, or the stop", () => {
    const [newStop, pair, unused] = buildSuggestions(
      [
        row({ kind: "new_stop", place_name: "Market", lat: 3.87, lng: 11.5, students: 6, metres: 2200 }),
        row({ kind: "close_pair", stop_id: "s1", other_stop_id: "s2", students: 6, metres: 222 }),
        row({ kind: "unused", stop_id: "s3" }),
      ],
      stops,
    );
    expect(suggestionPosition(newStop)).toEqual({ lat: 3.87, lng: 11.5 });
    expect(suggestionPosition(pair)?.lat).toBe(3.85);
    expect(suggestionPosition(pair)?.lng).toBeCloseTo(11.501, 9);
    expect(suggestionPosition(unused)).toBeNull();
  });
});
