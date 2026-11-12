/** Where to put a floating panel (menu, dropdown, calendar) next to the thing that opened it. Pure, so it is tested. */

export type Side = "bottom" | "top" | "left" | "right";

export type Box = { left: number; top: number; right: number; bottom: number };

type Options = {
  /** The trigger's box, in viewport coordinates. */
  anchor: Box;
  panel: { width: number; height: number };
  viewport: { width: number; height: number };
  /** The side to try first. "auto" means below, then above. */
  preferred?: Side | "auto";
  /** Space between the trigger and the panel. */
  gap?: number;
  /** Space kept between the panel and the screen edge. */
  margin?: number;
};

export type Placement = { side: Side; left: number; top: number };

const OPPOSITE: Record<Side, Side> = { bottom: "top", top: "bottom", left: "right", right: "left" };

const clamp = (value: number, min: number, max: number) => Math.max(min, Math.min(value, Math.max(min, max)));

/**
 * Picks the preferred side if the panel fits there, otherwise the opposite side, otherwise the
 * side with the most room, and keeps the panel on screen. Along the chosen side it lines up with
 * the trigger's start edge and shifts back if that would run off the screen.
 */
export function placePanel({ anchor, panel, viewport, preferred = "auto", gap = 8, margin = 8 }: Options): Placement {
  const room: Record<Side, number> = {
    bottom: viewport.height - anchor.bottom - gap - margin,
    top: anchor.top - gap - margin,
    right: viewport.width - anchor.right - gap - margin,
    left: anchor.left - gap - margin,
  };
  const need: Record<Side, number> = { bottom: panel.height, top: panel.height, left: panel.width, right: panel.width };

  const first: Side = preferred === "auto" ? "bottom" : preferred;
  const others = (["bottom", "top", "left", "right"] as Side[])
    .filter((side) => side !== first && side !== OPPOSITE[first])
    .sort((a, b) => room[b] - need[b] - (room[a] - need[a]));
  const order: Side[] = [first, OPPOSITE[first], ...others];

  const side = order.find((candidate) => room[candidate] >= need[candidate]) ?? order.reduce((best, s) => (room[s] - need[s] > room[best] - need[best] ? s : best), first);

  if (side === "bottom" || side === "top") {
    const left =
      anchor.left + panel.width <= viewport.width - margin
        ? anchor.left
        : anchor.right - panel.width;
    return {
      side,
      left: clamp(left, margin, viewport.width - panel.width - margin),
      top: clamp(side === "bottom" ? anchor.bottom + gap : anchor.top - gap - panel.height, margin, viewport.height - panel.height - margin),
    };
  }
  return {
    side,
    left: clamp(side === "right" ? anchor.right + gap : anchor.left - gap - panel.width, margin, viewport.width - panel.width - margin),
    top: clamp(anchor.top, margin, viewport.height - panel.height - margin),
  };
}
