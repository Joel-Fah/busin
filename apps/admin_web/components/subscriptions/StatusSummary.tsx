import { Archive02Icon, BadgeCheckIcon, BanIcon, CancelCircleIcon, TimeQuarter02Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { Chip } from "@/components/ui/Chip";
import { statusTone, summarizeStatuses, type SubscriptionStatus } from "@/lib/subscriptions";

const ICONS: Record<SubscriptionStatus, IconSvgElement> = {
  pending: TimeQuarter02Icon,
  approved: BadgeCheckIcon,
  revoked: CancelCircleIcon,
  rejected: BanIcon,
  expired: Archive02Icon,
};

/**
 * How many requests a student has made so far, by state, each with its icon and the colour of that state ("1 revoked",
 * "1 pending"). Shown only when there is more than one: with one, the status chip beside it already says everything.
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
    <ul className="m-0 flex list-none flex-wrap items-center gap-2 p-0" aria-label={label}>
      {items.map(({ status, count }) => (
        <li key={status}>
          <Chip tone={statusTone(status)} icon={ICONS[status]}>
            {count} {names[status].toLowerCase()}
          </Chip>
        </li>
      ))}
    </ul>
  );
}
