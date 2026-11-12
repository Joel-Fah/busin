/** Shape scale and the nested-radius rule. Values match --r-* in app/theme.css. */

export const RADIUS = { xs: 8, sm: 16, md: 20, lg: 28, xl: 36 } as const;
export type RadiusName = keyof typeof RADIUS;

/**
 * Radius of a shape drawn `gap` pixels inside a shape with radius `outer`. Concentric corners keep
 * an even visual gap: inner = outer - gap, never below zero.
 */
export function innerRadius(outer: number, gap: number): number {
  return Math.max(0, outer - gap);
}

/** The reverse: the radius a container needs to wrap a shape of radius `inner` with `gap` padding. */
export function outerRadius(inner: number, gap: number): number {
  return inner + gap;
}
