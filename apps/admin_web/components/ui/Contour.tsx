import type { CSSProperties } from "react";

import { innerRadius } from "@/lib/ui/radius";

type Props = {
  /** Corner radius of the container this sits in, in pixels. */
  radius: number;
  /** Distance from the container edge to the thread, in pixels. */
  inset?: number;
  /** Dash and gap of the thread, in pixels. Shorter for small containers such as buttons. */
  dash?: [number, number];
  /** The thread slides forward on hover or focus of the parent and back on leave. For buttons, links and empty states. */
  live?: boolean;
};

/**
 * The BusIn signature: a stitched thread drawn inside a container. Round-capped dashes, corners that
 * follow the nested-radius rule (container radius minus inset). With `live`, the thread slides
 * forward when the parent is hovered or focused and back when it is left (see .contour-thread in
 * app/theme.css). Colour comes from --thread-color on the parent, so it stays tonal with its
 * background. The parent must be `relative`.
 */
export function Contour({ radius, inset = 16, dash = [9, 7], live = false }: Props) {
  const style = {
    inset,
    width: `calc(100% - ${inset * 2}px)`,
    height: `calc(100% - ${inset * 2}px)`,
    "--thread-dash": dash.join(" "),
    "--thread-length": `${dash[0] + dash[1]}px`,
  } as CSSProperties;

  return (
    <svg aria-hidden className={`pointer-events-none absolute overflow-visible ${live ? "contour-live" : ""}`} style={style}>
      <rect width="100%" height="100%" rx={innerRadius(radius, inset)} className="contour-thread" />
    </svg>
  );
}
