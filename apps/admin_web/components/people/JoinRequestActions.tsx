"use client";

import { Message01Icon } from "@hugeicons/core-free-icons";
import { useState } from "react";

import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { Textarea } from "@/components/ui/Textarea";
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
          <Textarea
            id={`${formId}-reason`}
            name="reason"
            label={copy.reason}
            icon={Message01Icon}
            placeholder={copy.reasonPlaceholder}
            hint={copy.reasonHint}
            maxLength={MAX_DECLINE_REASON}
            rows={3}
          />
        </form>
      </Modal>
    </div>
  );
}
