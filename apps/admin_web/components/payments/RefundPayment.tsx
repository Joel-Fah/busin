"use client";

import { Coins01Icon, MoneyReceive02Icon } from "@hugeicons/core-free-icons";
import { useState } from "react";

import { ReasonField, type ReasonFieldText } from "@/components/ReasonField";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Notice } from "@/components/ui/Notice";
import { SideSheet } from "@/components/ui/SideSheet";
import { useToast } from "@/components/ui/Toast";
import { format } from "@/lib/i18n/messages";
import type { PaymentsCopy } from "@/lib/i18n/payments";
import { MAX_NOTE, type PaymentActionState } from "@/lib/payments";

import { useFormAction } from "./useFormAction";

type Props = {
  payment: { id: string; amount: number; amountText: string };
  copy: PaymentsCopy["subscription"];
  errors: PaymentsCopy["errors"];
  reasonText: Omit<ReasonFieldText, "label" | "placeholder" | "hint">;
  action: (previous: PaymentActionState, formData: FormData) => Promise<PaymentActionState>;
};

/** The school refunds a payment on its own (`admin_refund_payment`): how much, and why, in a side sheet. */
export function RefundPayment({ payment, copy, errors, reasonText, action }: Props) {
  const [open, setOpen] = useState(false);
  const toast = useToast();
  const { state, pending, onSubmit } = useFormAction(action, (answer) => {
    if (!answer?.ok) return;
    toast(copy.refunded, { tone: "ok" });
    setOpen(false);
  });

  const error = state && !state.ok ? (errors[state.error as keyof typeof errors] ?? errors.generic) : null;
  const reasonError = state && !state.ok && state.error.startsWith("reason_") ? error : null;
  const amountError = state && !state.ok && state.error === "bad_amount" ? error : null;

  return (
    <>
      <Button type="button" variant="secondary" icon={MoneyReceive02Icon} onClick={() => setOpen(true)}>
        {copy.refund}
      </Button>
      <SideSheet open={open} onClose={() => setOpen(false)} title={copy.refundTitle} closeLabel={copy.close}>
        <form onSubmit={onSubmit} className="flex flex-col gap-5" data-testid="school-refund-sheet">
          <input type="hidden" name="payment" value={payment.id} />
          <p className="text-sm text-muted">{format(copy.refundIntro, { amount: payment.amountText })}</p>
          <Input
            id={`school-refund-amount-${payment.id}`}
            name="amount"
            label={copy.amountLabel}
            hint={format(copy.amountHint, { max: payment.amountText })}
            icon={Coins01Icon}
            inputMode="numeric"
            autoComplete="off"
            required
            defaultValue={String(payment.amount)}
            error={amountError ?? undefined}
            className="max-w-xs"
          />
          <ReasonField
            id={`school-refund-note-${payment.id}`}
            name="note"
            text={{ ...reasonText, label: copy.reasonLabel, placeholder: copy.reasonPlaceholder }}
            presets={copy.presets}
            max={MAX_NOTE}
            required
            error={reasonError ?? undefined}
          />
          {error && !reasonError && !amountError ? <Notice tone="bad">{error}</Notice> : null}
          <div>
            <Button type="submit" variant="danger" icon={MoneyReceive02Icon} disabled={pending}>
              {copy.confirm}
            </Button>
          </div>
        </form>
      </SideSheet>
    </>
  );
}
