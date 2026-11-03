import type { ReactNode } from "react";

import { Contour } from "./Contour";

type Props = {
  children: ReactNode;
  className?: string;
  /** Draws the inner contour. On by default. */
  contour?: boolean;
};

/** A raised surface. Corner 28px, contour 16px in, content padded clear of the stroke. */
export function Card({ children, className = "", contour = true }: Props) {
  return (
    <div className={`relative rounded-lg bg-surface p-8 text-fg shadow-soft ${className}`}>
      {contour ? <Contour radius={28} inset={16} /> : null}
      {children}
    </div>
  );
}
