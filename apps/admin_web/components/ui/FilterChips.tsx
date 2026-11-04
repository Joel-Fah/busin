import Link from "next/link";
import { Cancel01Icon } from "@hugeicons/core-free-icons";

import { Icon } from "./Icon";

export type FilterChip = {
  /** The column, for example "Stop". */
  label: string;
  /** What it is set to, for example "Mvan roundabout". */
  value: string;
  /** The list's address with just this filter removed. */
  href: string;
};

type Props = {
  chips: FilterChip[];
  /** The list's address with every column filter removed (tabs and the like stay). */
  clearAllHref: string;
  clearAllLabel: string;
  /** Accessible name of the group, for example "Active filters". */
  groupLabel: string;
  /** Read before each chip's name, for example "Remove filter". */
  removeLabel: string;
};

/** What a list is currently filtered by, one removable chip each. Shows nothing when nothing is filtered. */
export function FilterChips({ chips, clearAllHref, clearAllLabel, groupLabel, removeLabel }: Props) {
  if (chips.length === 0) return null;
  return (
    <div role="group" aria-label={groupLabel} className="flex flex-wrap items-center gap-2">
      {chips.map((chip) => (
        <Link
          key={chip.label}
          href={chip.href}
          aria-label={`${removeLabel}: ${chip.label} ${chip.value}`}
          className="inline-flex items-center gap-2 rounded-sm bg-surface px-3 py-1.5 text-sm text-fg no-underline shadow-soft transition-colors duration-(--dur-fast) hover:bg-surface-2 focus-visible:outline-3 focus-visible:outline-focus"
        >
          <span className="text-muted">{chip.label}</span>
          <strong className="font-semibold">{chip.value}</strong>
          <Icon icon={Cancel01Icon} size={14} />
        </Link>
      ))}
      {chips.length > 1 ? (
        <Link href={clearAllHref} className="px-2 py-1.5 text-sm font-semibold text-muted no-underline hover:text-fg">
          {clearAllLabel}
        </Link>
      ) : null}
    </div>
  );
}
