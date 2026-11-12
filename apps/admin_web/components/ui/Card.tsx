import type { ReactNode } from "react";

import { Contour } from "./Contour";

type Props = {
  children: ReactNode;
  className?: string;
  /** Draws the inner contour. On by default. */
  contour?: boolean;
  /** Adds fine grain. For feature cards, not for cards that hold tables or forms. */
  grain?: boolean;
};

/** A raised surface. Corner 28px, contour 16px in, content padded clear of the stroke. */
export function Card({ children, className = "", contour = true, grain = false }: Props) {
  return (
    <div className={`relative rounded-lg bg-surface p-8 text-fg shadow-soft ${grain ? "texture-grain [--grain:0.8]" : ""} ${className}`}>
      {contour ? <Contour radius={28} inset={16} /> : null}
      {children}
    </div>
  );
}
