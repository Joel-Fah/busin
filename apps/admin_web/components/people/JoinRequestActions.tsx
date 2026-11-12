"use client";

import { useState } from "react";

import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { ReasonField, type ReasonFieldText } from "@/components/ReasonField";
import { MAX_DECLINE_REASON } from "@/lib/people";

type Copy = {
  verify: string;
  decline: string;
  declineTitle: string;
  declineBody: string;
  reason: string;
  reasonPlaceholder: string;
  reasonHint: string;
  cancel: string;
  confirmDecline: string;
  /** "Quick reasons", the counter and the minimum, shared with the other reason fields. */
  field: Pick<ReasonFieldText, "presetsLabel" | "counter" | "minimum">;
  presets: readonly string[];
};

type Props = {
  id: string;
  /** "detail" when shown on the person's page, so the action comes back there. */
  from?: "list" | "detail";
  copy: Copy;
  verify: (form: FormData) => Promise<void>;
  decline: (form: FormData) => Promise<void>;
};

/** Verify or decline a request to join: Verify is one press; Decline asks for an optional reason first. */
export function JoinRequestActions({ id, from = "list", copy, verify, decline }: Props) {
  const [declining, setDeclining] = useState(false);
  const formId = `decline-${id}`;
  return (
    <div className="flex flex-wrap gap-2">
      <form action={verify}>
        <input type="hidden" name="id" value={id} />
        <input type="hidden" name="from" value={from} />
        <Button type="submit">{copy.verify}</Button>
      </form>
      <Button type="button" variant="secondary" onClick={() => setDeclining(true)}>
        {copy.decline}
      </Button>
      <Modal
        open={declining}
        onClose={() => setDeclining(false)}
        title={copy.declineTitle}
        description={copy.declineBody}
        actions={
          <>
            <Button type="button" variant="secondary" onClick={() => setDeclining(false)}>
              {copy.cancel}
            </Button>
            <Button type="submit" form={formId} variant="danger">
              {copy.confirmDecline}
            </Button>
          </>
        }
      >
        <form id={formId} action={decline}>
          <input type="hidden" name="id" value={id} />
          <input type="hidden" name="from" value={from} />
          <ReasonField
            id={`${formId}-reason`}
            name="reason"
            text={{ ...copy.field, label: copy.reason, placeholder: copy.reasonPlaceholder, hint: copy.reasonHint }}
            presets={copy.presets}
            max={MAX_DECLINE_REASON}
          />
        </form>
      </Modal>
    </div>
  );
}
