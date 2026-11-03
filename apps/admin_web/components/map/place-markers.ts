import { clusterPoints } from "@/lib/map/cluster";

import { createClusterElement, createMarkerElement } from "./marker-element";
import type { MapMarker } from "./types";

/** What placing markers needs from a map library, so one implementation serves every provider. */
export type MarkerHost = {
  getZoom(): number;
  /** Calls the listener as the zoom changes, including during an animated zoom. Returns a function that stops listening. */
  onZoom(listener: () => void): () => void;
  /** Zooms and pans so this box ([west, south], [east, north]) fills the map. */
  fitTo(bounds: [[number, number], [number, number]]): void;
  place(element: HTMLElement, position: [number, number]): { remove(): void };
};

type Options = {
  /** Merge markers that would overlap into a numbered bubble. Off while choosing a position. */
  clustering: boolean;
  /** Text for the bubble, with {count} for the number. */
  clusterLabel: string;
};

/**
 * Puts the markers on the map and keeps them right as the zoom changes: zoomed out, markers that would
 * overlap become one bubble with their count, zooming in gradually splits them, and choosing a bubble
 * zooms in on its members. The selected marker and the visitor's own position are never merged.
 * Returns a function that removes everything.
 */
export function placeMarkers(host: MarkerHost, markers: readonly MapMarker[], { clustering, clusterLabel }: Options): () => void {
  const byId = new Map(markers.map((marker) => [marker.id, marker]));
  // What is on the map now, by a signature of what it shows, so a zoom only touches what changed.
  let placed = new Map<string, { remove(): void }>();

  const signature = (group: { id: string; members: string[] }, members: MapMarker[]) =>
    members.length === 1
      ? `${group.id}|${members[0].selected ? "s" : ""}${members[0].muted ? "m" : ""}${members[0].variant ?? ""}`
      : `${group.id}|${members.length}`;

  const render = () => {
    const groups = clusterPoints(
      markers.map((marker) => ({ id: marker.id, position: marker.position, pinned: !clustering || marker.selected || marker.variant === "me" })),
      host.getZoom(),
    );

    const next = new Map<string, { remove(): void }>();
    for (const group of groups) {
      const members = group.members.map((id) => byId.get(id)).filter((marker): marker is MapMarker => marker !== undefined);
      if (members.length === 0) continue;
      const key = signature(group, members);

      const existing = placed.get(key);
      if (existing) {
        next.set(key, existing);
        placed.delete(key);
        continue;
      }
      const element =
        members.length === 1
          ? createMarkerElement(members[0])
          : createClusterElement(members.length, clusterLabel, () => {
              const lngs = members.map((marker) => marker.position.lng);
              const lats = members.map((marker) => marker.position.lat);
              host.fitTo([
                [Math.min(...lngs), Math.min(...lats)],
                [Math.max(...lngs), Math.max(...lats)],
              ]);
            });
      next.set(key, host.place(element, [group.position.lng, group.position.lat]));
    }

    // Whatever is left over is no longer wanted.
    for (const stale of placed.values()) stale.remove();
    placed = next;
  };

  // A zoom fires many times a second; do the work at most once per frame so it follows the map without lag.
  let frame = 0;
  const schedule = () => {
    if (frame) return;
    frame = requestAnimationFrame(() => {
      frame = 0;
      render();
    });
  };

  render();
  const stopListening = host.onZoom(schedule);
  return () => {
    stopListening();
    if (frame) cancelAnimationFrame(frame);
    for (const item of placed.values()) item.remove();
    placed = new Map();
  };
}
