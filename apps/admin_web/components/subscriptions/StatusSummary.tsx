import { Archive02Icon, BadgeCheckIcon, BanIcon, CancelCircleIcon, TimeQuarter02Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { Icon } from "@/components/ui/Icon";
import { statusTone, summarizeStatuses, type SubscriptionStatus } from "@/lib/subscriptions";
import type { ChipTone } from "@/components/ui/Chip";

const ICONS: Record<SubscriptionStatus, IconSvgElement> = {
  pending: TimeQuarter02Icon,
  approved: BadgeCheckIcon,
  revoked: CancelCircleIcon,
  rejected: BanIcon,
  expired: Archive02Icon,
};

const INK: Record<ChipTone, string> = {
  neutral: "text-muted",
  accent: "text-fg",
  ok: "text-ok",
  warn: "text-warn",
  bad: "text-bad",
  info: "text-info",
};

/**
 * How many requests a student has made so far, by state, as plain text with the state's icon in its colour ("1 pending",
 * "1 revoked"), the way a pull request list sums up its open and closed. Not chips: the status beside it is already a chip.
 * Shown only when there is more than one request: with one, that status says everything.
 */
export function StatusSummary({
  statuses,
  label,
  names,
}: {
  statuses: readonly SubscriptionStatus[];
  /** Said by a screen reader before the counts. */
  label: string;
  /** Each state's name as written in the interface. */
  names: Record<SubscriptionStatus, string>;
}) {
  if (statuses.length < 2) return null;
  const items = summarizeStatuses(statuses);
  return (
    <ul className="m-0 flex list-none flex-wrap items-center gap-x-4 gap-y-1 p-0 text-sm text-muted" aria-label={label}>
      {items.map(({ status, count }) => (
        <li key={status} className="inline-flex items-center gap-1.5">
          <Icon icon={ICONS[status]} size={16} className={INK[statusTone(status)]} />
          {count} {names[status].toLowerCase()}
        </li>
      ))}
    </ul>
  );
}
