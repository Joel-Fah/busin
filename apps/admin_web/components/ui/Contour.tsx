import { innerRadius } from "@/lib/ui/radius";

type Props = {
  /** Corner radius of the container this sits in, in pixels. */
  radius: number;
  /** Distance from the container edge to the stroke, in pixels. */
  inset?: number;
};

/**
 * The BusIn signature: a thin rounded stroke drawn inside a container. Its corners follow the
 * nested-radius rule (container radius minus inset) so the gap to the edge stays even. The parent
 * must be `relative`.
 */
export function Contour({ radius, inset = 16 }: Props) {
  return (
    <span
      aria-hidden
      className="pointer-events-none absolute border-contour"
      style={{
        inset,
        borderRadius: innerRadius(radius, inset),
        borderWidth: "var(--contour-width)",
        borderStyle: "solid",
      }}
    />
  );
}
