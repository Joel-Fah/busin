"use client";

import { Cancel01Icon, Coins01Icon, Tick02Icon } from "@hugeicons/core-free-icons";
import { useState } from "react";

import { ReasonField, type ReasonFieldText } from "@/components/ReasonField";
import { Button } from "@/components/ui/Button";
import { Radio } from "@/components/ui/Choice";
import { Input } from "@/components/ui/Input";
import { Notice } from "@/components/ui/Notice";
import { SideSheet } from "@/components/ui/SideSheet";
import { useToast } from "@/components/ui/Toast";
import { format } from "@/lib/i18n/messages";
import type { PaymentsCopy } from "@/lib/i18n/payments";
import { MAX_NOTE, type PaymentActionState } from "@/lib/payments";

import { useFormAction } from "./useFormAction";

type Props = {
  refund: { id: string; studentName: string; amount: number; amountText: string; reason: string | null; asked: string; receipt: string | null };
  copy: PaymentsCopy["refunds"];
  errors: PaymentsCopy["errors"];
  reasonText: Omit<ReasonFieldText, "label" | "placeholder" | "hint">;
  action: (previous: PaymentActionState, formData: FormData) => Promise<PaymentActionState>;
};

/**
 * A student's refund request, decided in a side sheet: refund all of it, part of it (an amount), or decline with a reason
 * the student reads. The button says exactly what will happen, so the sheet itself is the confirmation.
 */
export function RefundDecision({ refund, copy, errors, reasonText, action }: Props) {
  const [open, setOpen] = useState(false);
  const [choice, setChoice] = useState<"all" | "part" | "decline">("all");
  const toast = useToast();
  const { state, pending, onSubmit } = useFormAction(action, (answer) => {
    if (!answer?.ok) return;
    toast(answer.done === "declined" ? copy.done.declined : copy.done.approved, { tone: "ok" });
    setOpen(false);
  });
  const s = copy.sheet;

  const error = state && !state.ok ? (errors[state.error as keyof typeof errors] ?? errors.generic) : null;
  const reasonError = state && !state.ok && state.error.startsWith("reason_") ? error : undefined;
  const amountError = state && !state.ok && state.error === "bad_amount" ? error : undefined;

  return (
    <>
      <Button type="button" variant="secondary" onClick={() => setOpen(true)}>
        {copy.decide}
      </Button>
      <SideSheet open={open} onClose={() => setOpen(false)} title={s.title} closeLabel={s.close}>
        <form onSubmit={onSubmit} className="flex flex-col gap-5" data-testid="refund-sheet">
          <input type="hidden" name="refund" value={refund.id} />
          <dl className="m-0 grid gap-3 rounded-md bg-surface-2 p-4 text-sm">
            <div>
              <dt className="text-muted">{copy.student}</dt>
              <dd className="m-0 font-semibold">{refund.studentName}</dd>
            </div>
            <div>
              <dt className="text-muted">{s.paid}</dt>
              <dd className="m-0 font-semibold tabular-nums">
                {refund.amountText}
                {refund.receipt ? <span className="ml-2 font-normal text-muted">{format(copy.receipt, { number: refund.receipt })}</span> : null}
              </dd>
            </div>
            <div>
              <dt className="text-muted">{s.reasonLabel}</dt>
              <dd className="m-0">{refund.reason || "-"}</dd>
            </div>
            <div>
              <dt className="text-muted">{copy.asked}</dt>
              <dd className="m-0">{refund.asked}</dd>
            </div>
          </dl>

          <fieldset className="m-0 flex flex-col gap-4 border-0 p-0">
            <legend className="mb-1 p-0 text-base font-bold">{s.choice}</legend>
            <Radio name="decision" value="all" label={format(s.all, { amount: refund.amountText })} hint={s.allHint} checked={choice === "all"} onChange={() => setChoice("all")} />
            <Radio name="decision" value="part" label={s.part} hint={s.partHint} checked={choice === "part"} onChange={() => setChoice("part")} />
            {choice === "part" ? (
              <Input
                id={`refund-amount-${refund.id}`}
                name="amount"
                label={s.amountLabel}
                hint={format(s.amountHint, { max: refund.amountText })}
                icon={Coins01Icon}
                inputMode="numeric"
                autoComplete="off"
                required
                error={amountError ?? undefined}
                className="ml-9 max-w-xs"
              />
            ) : null}
            <Radio name="decision" value="decline" label={s.decline} hint={s.declineHint} checked={choice === "decline"} onChange={() => setChoice("decline")} />
            {choice === "decline" ? (
              <div className="ml-9">
                <ReasonField
                  id={`refund-note-${refund.id}`}
                  name="note"
                  text={{ ...reasonText, label: s.noteLabel, placeholder: s.notePlaceholder }}
                  presets={s.presets}
                  max={MAX_NOTE}
                  required
                  error={reasonError ?? undefined}
                />
              </div>
            ) : null}
          </fieldset>

          {choice !== "decline" ? <p className="text-sm text-muted">{s.cost}</p> : null}
          {error && !reasonError && !amountError ? <Notice tone="bad">{error}</Notice> : null}

          <div>
            {choice === "decline" ? (
              <Button type="submit" variant="danger" icon={Cancel01Icon} disabled={pending}>
                {s.confirmDecline}
              </Button>
            ) : (
              <Button type="submit" icon={Tick02Icon} disabled={pending}>
                {choice === "all" ? format(s.confirmAll, { amount: refund.amountText }) : s.confirmPart}
              </Button>
            )}
          </div>
        </form>
      </SideSheet>
    </>
  );
}
