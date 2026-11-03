import Image from "next/image";
import type { ReactNode } from "react";

import { Contour } from "./Contour";

type Props = {
  title: string;
  body?: string;
  /** Path to a 3D illustration, used only where it helps explain the state. */
  illustration?: string;
  /** What the person can do next, for example a button. */
  action?: ReactNode;
  className?: string;
};

/** An empty list or page. No card: the thread alone frames the message, and it slides when hovered. */
export function EmptyState({ title, body, illustration, action, className = "" }: Props) {
  return (
    <div className={`relative flex flex-col items-center gap-3 px-8 py-14 text-center [--thread-hover-width:2.25px] ${className}`}>
      <Contour radius={28} inset={0} live />
      {illustration ? <Image src={illustration} alt="" width={120} height={120} className="h-28 w-28" /> : null}
      <p className="text-lg font-bold">{title}</p>
      {body ? <p className="max-w-sm text-sm text-muted">{body}</p> : null}
      {action ? <div className="mt-2">{action}</div> : null}
    </div>
  );
}
