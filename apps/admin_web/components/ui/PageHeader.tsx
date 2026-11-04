import type { ReactNode } from "react";

import { HelpSheet, type HelpContent } from "./HelpSheet";

type Props = {
  title: string;
  subtitle?: string;
  /** When given, a help button beside the headline opens a side sheet with worked examples. */
  help?: HelpContent;
  /** The page's main action, for example an Add button, placed at the far end of the headline row. */
  action?: ReactNode;
};

export function PageHeader({ title, subtitle, help, action }: Props) {
  return (
    <header>
      <div className="flex flex-wrap items-center gap-3">
        <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl">{title}</h1>
        {help ? <HelpSheet {...help} /> : null}
        {action ? <div className="ml-auto">{action}</div> : null}
      </div>
      {subtitle ? <p className="mt-2 max-w-2xl text-base text-muted">{subtitle}</p> : null}
    </header>
  );
}
