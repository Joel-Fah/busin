"use client";

import { useState } from "react";
import { HelpCircleIcon } from "@hugeicons/core-free-icons";

import { Icon } from "./Icon";
import { SideSheet } from "./SideSheet";

export type HelpContent = {
  /** Accessible name of the help button. */
  label: string;
  title: string;
  intro: string;
  /** Real situations that show how the page is used. */
  scenarios: { title: string; body: string }[];
  scenariosLabel: string;
  closeLabel: string;
};

/** A help button that sits beside a page headline and opens a side sheet with worked examples. */
export function HelpSheet({ label, title, intro, scenarios, scenariosLabel, closeLabel }: HelpContent) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label={label}
        data-tip={label}
        aria-haspopup="dialog"
        className="inline-flex h-11 w-11 shrink-0 cursor-pointer items-center justify-center rounded-sm border-0 bg-transparent text-muted transition-colors duration-(--dur-fast) hover:bg-surface-2 hover:text-fg focus-visible:outline-3 focus-visible:outline-focus"
      >
        <Icon icon={HelpCircleIcon} size={26} />
      </button>
      <SideSheet open={open} onClose={() => setOpen(false)} title={title} closeLabel={closeLabel}>
        <p className="text-base text-muted">{intro}</p>
        <div>
          <h3 className="mb-3 text-sm font-semibold tracking-wide text-muted uppercase">{scenariosLabel}</h3>
          <ol className="m-0 flex list-none flex-col gap-3 p-0">
            {scenarios.map((scenario, index) => (
              <li key={scenario.title} className="rounded-md bg-surface-2 p-5">
                <p className="text-sm font-semibold text-muted">{index + 1}</p>
                <p className="mt-1 text-base font-bold">{scenario.title}</p>
                <p className="mt-1.5 text-sm text-muted">{scenario.body}</p>
              </li>
            ))}
          </ol>
        </div>
      </SideSheet>
    </>
  );
}
