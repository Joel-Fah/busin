import { Add01Icon, Bus01Icon, Calendar02Icon, Coins01Icon, FlagTriangleRightIcon, ReceiptTextIcon, UserAdd01Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import type { Messages } from "@/lib/i18n/messages";

/**
 * The things an administrator does most, one click from the overview. Billing comes first while it is not set: students
 * cannot ask for a subscription before (ADR 0022).
 */
export function QuickActions({ t, pending, billingSet, payments }: { t: Messages; pending: number; billingSet: boolean; payments: number }) {
  const q = t.overview.quick;
  return (
    <nav aria-label={q.label} className="flex flex-wrap gap-2 sm:col-span-2 xl:col-span-4">
      {billingSet ? null : (
        <ButtonLink href="/billing" icon={Coins01Icon}>
          {q.billing}
        </ButtonLink>
      )}
      <ButtonLink href="/trips/new" variant={billingSet ? "primary" : "secondary"} icon={Add01Icon}>
        {q.trip}
      </ButtonLink>
      {payments > 0 ? (
        <ButtonLink href="/subscriptions?status=approved&payments=1" variant="secondary" icon={Coins01Icon}>
          {q.payments}
        </ButtonLink>
      ) : null}
      {pending > 0 ? (
        <ButtonLink href="/subscriptions" variant="secondary" icon={ReceiptTextIcon}>
          {q.review}
        </ButtonLink>
      ) : null}
      <ButtonLink href="/stops?add" variant="secondary" icon={FlagTriangleRightIcon}>
        {q.stop}
      </ButtonLink>
      <ButtonLink href="/buses/new?next=%2F" variant="secondary" icon={Bus01Icon}>
        {q.bus}
      </ButtonLink>
      <ButtonLink href="/semesters/new" variant="secondary" icon={Calendar02Icon}>
        {q.semester}
      </ButtonLink>
      <ButtonLink href="/people/invite" variant="secondary" icon={UserAdd01Icon}>
        {q.staff}
      </ButtonLink>
    </nav>
  );
}
