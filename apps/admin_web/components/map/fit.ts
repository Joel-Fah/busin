/**
 * Padding for fitting the markers when part of the map is covered at the bottom (a dock over a full-screen map):
 * `reserve` is that share of the height, 0 to 0.8.
 */
export function fitPadding(height: number, reserve = 0, base = 56) {
  const covered = Math.round(height * Math.min(Math.max(reserve, 0), 0.8));
  return { top: base, left: base, right: base, bottom: base + covered };
}

/** How far up to shift a focused point so it sits in the middle of the part of the map left uncovered. */
export function focusOffset(height: number, reserve = 0): [number, number] {
  return [0, -Math.round((height * Math.min(Math.max(reserve, 0), 0.8)) / 2)];
}
