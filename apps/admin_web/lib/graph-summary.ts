/**
 * The graph read out in a few plain facts, worked out from the same figures it draws, so an admin who has never seen it
 * knows what to look at first. Pure, so it is tested; the page turns each fact into a sentence.
 */
import type { LoadLevel, StopLoads } from "@/lib/insights";
import type { Proximity } from "@/lib/proximity";
import type { Suggestion } from "@/lib/suggestions";

export type GraphFact =
  | { kind: "stops"; stops: number; subscribers: number; withArea: number }
  | { kind: "fullest"; stop: string; level: LoadLevel; share: number }
  | { kind: "allQuiet" }
  | { kind: "farthest"; stop: string; metres: number }
  | { kind: "nearer"; groups: number; students: number; from: string; to: string }
  | { kind: "suggested"; count: number; first: string }
  | { kind: "notEnough"; stops: number };

export function graphFacts(loads: StopLoads, proximity: Proximity, suggestions: readonly Suggestion[]): GraphFact[] {
  const facts: GraphFact[] = [{ kind: "stops", stops: proximity.stops.length, subscribers: proximity.subscribers, withArea: proximity.withArea }];

  const fullest = loads.stops.find((s) => s.load !== null && s.level !== null);
  if (fullest && fullest.level && fullest.load !== null && (fullest.level === "busy" || fullest.level === "full")) {
    facts.push({ kind: "fullest", stop: fullest.name, level: fullest.level, share: fullest.load });
  } else if (loads.stops.some((s) => s.load !== null)) {
    facts.push({ kind: "allQuiet" });
  }

  // Proximity stops come farthest median first.
  const farthest = proximity.stops.find((s) => s.median !== null);
  if (farthest && farthest.median !== null && farthest.median >= 1000) facts.push({ kind: "farthest", stop: farthest.name, metres: farthest.median });

  const groups = proximity.stops.flatMap((s) => s.nearer.map((n) => ({ from: s.name, to: n.toName, students: n.students })));
  if (groups.length > 0) {
    const biggest = groups.reduce((a, b) => (b.students > a.students ? b : a));
    facts.push({ kind: "nearer", groups: groups.length, students: groups.reduce((sum, g) => sum + g.students, 0), from: biggest.from, to: biggest.to });
  }

  const newStops = suggestions.filter((s) => s.kind === "new_stop");
  if (newStops.length > 0 && newStops[0].kind === "new_stop") facts.push({ kind: "suggested", count: newStops.length, first: newStops[0].place });

  const thin = proximity.stops.filter((s) => s.median === null).length;
  if (thin > 0) facts.push({ kind: "notEnough", stops: thin });

  return facts;
}
