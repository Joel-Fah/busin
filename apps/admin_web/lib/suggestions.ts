import type { LatLng } from "@/lib/geo";

/** One row of `admin_stop_suggestions`. Fields depend on the kind; the database never sends a figure under 5 students for a new stop. */
export type SuggestionRow = {
  kind: string;
  stop_id: string | null;
  other_stop_id: string | null;
  place_name: string | null;
  lat: number | null;
  lng: number | null;
  students: number | null;
  metres: number | null;
  /** New stops: after which stop of the route it fits (-1 before the first), or null without a route. */
  insert_after?: number | null;
};

export type SuggestionStop = { id: string; name: string; position: LatLng | null };

export type Suggestion =
  | { kind: "new_stop"; id: string; place: string; position: LatLng; students: number; metres: number; insertAfter: number | null }
  | { kind: "close_pair"; id: string; a: SuggestionStop; b: SuggestionStop; students: number; metres: number }
  | { kind: "unused"; id: string; stop: SuggestionStop; students: number; weeks: number };

/** The rows with their stops' names and places, new stops first; rows about stops the page does not know are dropped. */
export function buildSuggestions(rows: readonly SuggestionRow[], stops: readonly SuggestionStop[]): Suggestion[] {
  const byId = new Map(stops.map((s) => [s.id, s]));
  const list: Suggestion[] = [];
  rows.forEach((row, index) => {
    if (row.kind === "new_stop" && row.place_name && row.lat !== null && row.lng !== null && Number.isFinite(row.lat) && Number.isFinite(row.lng)) {
      list.push({
        kind: "new_stop",
        id: `new:${index}`,
        place: row.place_name,
        position: { lat: row.lat, lng: row.lng },
        students: row.students ?? 0,
        metres: row.metres ?? 0,
        insertAfter: typeof row.insert_after === "number" ? row.insert_after : null,
      });
    } else if (row.kind === "close_pair") {
      const a = row.stop_id ? byId.get(row.stop_id) : undefined;
      const b = row.other_stop_id ? byId.get(row.other_stop_id) : undefined;
      if (a && b) list.push({ kind: "close_pair", id: `pair:${a.id}:${b.id}`, a, b, students: row.students ?? 0, metres: row.metres ?? 0 });
    } else if (row.kind === "unused") {
      const stop = row.stop_id ? byId.get(row.stop_id) : undefined;
      if (stop) list.push({ kind: "unused", id: `unused:${stop.id}`, stop, students: row.students ?? 0, weeks: Math.round((row.metres ?? 42) / 7) });
    }
  });
  const order = { new_stop: 0, close_pair: 1, unused: 2 } as const;
  return list.sort((x, y) => order[x.kind] - order[y.kind]);
}

/** Where a suggestion is on the map: the place, the middle of the two stops, or the stop. */
export function suggestionPosition(s: Suggestion): LatLng | null {
  if (s.kind === "new_stop") return s.position;
  if (s.kind === "unused") return s.stop.position;
  const { a, b } = s;
  return a.position && b.position ? { lat: (a.position.lat + b.position.lat) / 2, lng: (a.position.lng + b.position.lng) / 2 } : (a.position ?? b.position);
}
