import type { ReactNode } from "react";

import { Icon } from "./Icon";
import { ArrowDown01Icon } from "@hugeicons/core-free-icons";

type Props = {
  /** What the closed row shows: usually a title and a chip. */
  summary: ReactNode;
  children: ReactNode;
  /** Open when the page loads: the one that matters now (the latest). */
  defaultOpen?: boolean;
  className?: string;
};

/**
 * A row that opens to show more, built on the browser's own details element: keyboard and screen reader behaviour
 * come with it, nothing needs scripting. The arrow turns and the panel eases open and shut (see .accordion in theme.css).
 */
export function Accordion({ summary, children, defaultOpen = false, className = "" }: Props) {
  return (
    <details open={defaultOpen} className={`accordion group rounded-md bg-surface-2 ${className}`}>
      <summary className="flex cursor-pointer list-none items-center gap-3 rounded-md px-4 py-3.5 transition-colors duration-(--dur-fast) hover:bg-line focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden">
        <div className="min-w-0 flex-1">{summary}</div>
        <Icon icon={ArrowDown01Icon} size={20} className="shrink-0 text-muted transition-transform duration-(--dur) ease-soft group-open:rotate-180 motion-reduce:transition-none" />
      </summary>
      <div className="px-4 pt-1 pb-4">{children}</div>
    </details>
  );
}
