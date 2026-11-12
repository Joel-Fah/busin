import type { LatLng } from "@/lib/geo";

/**
 * Groups points that sit so close on screen that their markers would overlap, so a zoomed-out map shows
 * "5 stops" instead of a pile. Pure and independent of any map library: it projects to screen pixels
 * at the current zoom (Web Mercator, as every web map does) and groups what falls within a radius.
 */

export type ClusterPoint = {
  id: string;
  position: LatLng;
  /** Never merged into a group, for example the selected stop or the visitor's own position. */
  pinned?: boolean;
};

export type Group = {
  /** The point's own id for a single, a stable id built from the members for a group. */
  id: string;
  position: LatLng;
  members: string[];
};

const TILE_SIZE = 256;

/** Pixels from the world's top-left corner at a zoom level. */
export function project({ lat, lng }: LatLng, zoom: number): { x: number; y: number } {
  const scale = TILE_SIZE * 2 ** zoom;
  const clamped = Math.max(-85.0511, Math.min(85.0511, lat));
  const sin = Math.sin((clamped * Math.PI) / 180);
  return {
    x: ((lng + 180) / 360) * scale,
    y: (0.5 - Math.log((1 + sin) / (1 - sin)) / (4 * Math.PI)) * scale,
  };
}

/** At and beyond this zoom, points are shown one by one however close they are. */
export const MAX_CLUSTER_ZOOM = 16;
/** How close two markers may get, in screen pixels, before they are grouped. */
export const CLUSTER_RADIUS_PX = 54;

export function clusterPoints(
  points: readonly ClusterPoint[],
  zoom: number,
  radiusPx = CLUSTER_RADIUS_PX,
  maxZoom = MAX_CLUSTER_ZOOM,
): Group[] {
  const single = (point: ClusterPoint): Group => ({ id: point.id, position: point.position, members: [point.id] });
  if (zoom >= maxZoom) return points.map(single);

  const projected = points.map((point) => project(point.position, zoom));
  const taken = new Set<number>();
  const groups: Group[] = [];

  points.forEach((seed, index) => {
    if (taken.has(index)) return;
    taken.add(index);
    if (seed.pinned) {
      groups.push(single(seed));
      return;
    }

    const members = [index];
    points.forEach((other, otherIndex) => {
      if (taken.has(otherIndex) || other.pinned) return;
      if (Math.hypot(projected[otherIndex].x - projected[index].x, projected[otherIndex].y - projected[index].y) <= radiusPx) {
        taken.add(otherIndex);
        members.push(otherIndex);
      }
    });

    if (members.length === 1) {
      groups.push(single(seed));
      return;
    }
    const lat = members.reduce((sum, i) => sum + points[i].position.lat, 0) / members.length;
    const lng = members.reduce((sum, i) => sum + points[i].position.lng, 0) / members.length;
    const ids = members.map((i) => points[i].id).sort();
    groups.push({ id: `group:${ids.join(",")}`, position: { lat, lng }, members: ids });
  });

  return groups;
}
