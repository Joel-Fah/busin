import Link from "next/link";
import type { ReactNode } from "react";

import { Card } from "@/components/ui/Card";

type Props = {
  title: string;
  /** A link to where the detail lives, shown in the tile's header. */
  action?: { href: string; label: string };
  children: ReactNode;
  className?: string;
  testId?: string;
};

/** One cell of the overview grid: a titled card whose action leads to the full page. */
export function Tile({ title, action, children, className = "", testId }: Props) {
  return (
    <Card className={`flex flex-col gap-5 p-6! sm:p-7! ${className}`}>
      <div data-testid={testId} className="relative flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
        <h2 className="text-base font-bold tracking-tight">{title}</h2>
        {action ? (
          <Link
            href={action.href}
            className="rounded-xs text-sm font-semibold text-link no-underline hover:text-fg focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus"
          >
            {action.label}
          </Link>
        ) : null}
      </div>
      <div className="relative flex min-h-0 flex-1 flex-col">{children}</div>
    </Card>
  );
}
