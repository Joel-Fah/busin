"use client";

import { useState } from "react";
import { Tick02Icon } from "@hugeicons/core-free-icons";

import { useFormAction } from "@/components/payments/useFormAction";
import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import { useToast } from "@/components/ui/Toast";
import { format } from "@/lib/i18n/format";
import type { PlatformPaymentsCopy } from "@/lib/i18n/platform-payments";
import type { PlatformPaymentState } from "@/lib/platform-payments";

type Props = {
  account: string;
  school: string;
  /** What is being confirmed, for the dialog: the operator and the masked number. */
  detail: string;
  copy: PlatformPaymentsCopy["alerts"];
  errors: PlatformPaymentsCopy["errors"];
  action: (previous: PlatformPaymentState, formData: FormData) => Promise<PlatformPaymentState>;
};

/**
 * Confirms a payout number waiting for a second administrator, for a school that has only one (ADR 0029). The dialog
 * says when this is right: after checking the number with that administrator.
 */
export function ConfirmPayoutNumber({ account, school, detail, copy, errors, action }: Props) {
  const toast = useToast();
  const [open, setOpen] = useState(false);
  const confirm = useFormAction(action, (answer) => {
    if (!answer?.ok) return;
    toast(copy.confirmed, { tone: "ok" });
    setOpen(false);
  });
  const error = confirm.state && !confirm.state.ok ? (errors[confirm.state.error as keyof typeof errors] ?? errors.generic) : null;
  return (
    <>
      <Button type="button" variant="secondary" icon={Tick02Icon} onClick={() => setOpen(true)}>
        {copy.confirm}
      </Button>
      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title={format(copy.confirmTitle, { school })}
        description={copy.confirmBody}
        actions={
          <form onSubmit={confirm.onSubmit} className="flex flex-wrap justify-end gap-3">
            <input type="hidden" name="account" value={account} />
            <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
              {copy.cancel}
            </Button>
            <Button type="submit" icon={Tick02Icon} disabled={confirm.pending}>
              {copy.confirm}
            </Button>
          </form>
        }
      >
        <p className="m-0 font-semibold tabular-nums">{detail}</p>
        {error ? <Notice tone="bad" className="mt-3">{error}</Notice> : null}
      </Modal>
    </>
  );
}
