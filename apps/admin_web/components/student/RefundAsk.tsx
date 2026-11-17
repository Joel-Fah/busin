"use client";

import { useActionState, useId } from "react";
import { NoteIcon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Notice } from "@/components/ui/Notice";
import { Textarea } from "@/components/ui/Textarea";
import type { StudentCopy } from "@/lib/i18n/student";
import { askRefund, type RefundAskState } from "@/lib/student/refund-actions";

/**
 * "Ask for a refund" under a receipt (ADR 0029): a native disclosure with the reason, sent to the school. It opens and
 * sends before the page's scripts have loaded, as any form here does.
 */
export function RefundAsk({ copy, paymentId }: { copy: StudentCopy["subscription"]["pay"]["refunds"]; paymentId: string }) {
  const [state, action, pending] = useActionState<RefundAskState, FormData>(askRefund, { sent: false, error: null });
  const id = useId();
  if (state.sent) return <Notice tone="ok">{copy.sent}</Notice>;
  const error = state.error === "short" ? copy.short : state.error === "long" ? copy.long : state.error === "notRefundable" ? copy.notRefundable : state.error ? copy.generic : undefined;
  return (
    <details className="group" open={state.error ? true : undefined} data-testid="refund-details">
      <summary className="inline-flex min-h-11 cursor-pointer list-none items-center rounded-sm px-1 font-semibold text-link focus-visible:outline-3 focus-visible:outline-focus [&::-webkit-details-marker]:hidden">
        {copy.ask}
      </summary>
      <form action={action} className="mt-2 flex flex-col gap-3" data-testid="refund-ask">
        <p className="m-0 font-bold">{copy.title}</p>
        <p className="m-0 text-sm text-muted">{copy.body}</p>
        <input type="hidden" name="payment" value={paymentId} />
        <Textarea id={`${id}-reason`} name="reason" label={copy.reasonLabel} placeholder={copy.reasonHint} icon={NoteIcon} rows={3} maxLength={500} error={error} />
        <Button type="submit" className="self-start" disabled={pending}>
          {copy.send}
        </Button>
      </form>
    </details>
  );
}
