import type { IconSvgElement } from "@hugeicons/react";

/** Line weight of every icon in the portal. */
export const ICON_STROKE = 1.8;

/**
 * The thickness already baked into the outlines of icons that Hugeicons ships as one filled path
 * (for example FlagTriangleRightIcon) instead of a stroke.
 */
const BAKED_OUTLINE = 1.5;

/** True for icons drawn as filled outlines: every part is filled and none declares its own stroke. */
export function isFilledOutline(icon: IconSvgElement): boolean {
  return icon.length > 0 && icon.every(([, attrs]) => attrs.fill === "currentColor" && !attrs.stroke);
}

/**
 * Stroke width to pass to HugeiconsIcon. The library applies it to every path, so a filled
 * outline would get its own thickness plus the full stroke and look twice as heavy as its
 * neighbours. For those, only the small difference to the common weight is added.
 */
export function iconStrokeWidth(icon: IconSvgElement, stroke = ICON_STROKE): number {
  return isFilledOutline(icon) ? Math.max(0, stroke - BAKED_OUTLINE) : stroke;
}
