"use client";

import { useState } from "react";
import { Note01Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { Textarea } from "@/components/ui/Textarea";

type Props = {
  leadId: string;
  status: string;
  note: string | null;
  back: string;
  text: { note: string; notePlaceholder: string; saveNote: string; cancel: string };
  action: (formData: FormData) => Promise<void>;
};

/** Writes or changes the note of a lead, in a small dialog, so the list stays short. */
export function LeadNote({ leadId, status, note, back, text, action }: Props) {
  const [open, setOpen] = useState(false);
  const formId = `lead-note-${leadId}`;
  return (
    <>
      <Button variant="ghost" icon={Note01Icon} onClick={() => setOpen(true)}>
        {text.note}
      </Button>
      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title={text.note}
        actions={
          <>
            <Button variant="ghost" onClick={() => setOpen(false)}>
              {text.cancel}
            </Button>
            <Button type="submit" form={formId} icon={Note01Icon}>
              {text.saveNote}
            </Button>
          </>
        }
      >
        <form id={formId} action={action}>
          <input type="hidden" name="lead" value={leadId} />
          <input type="hidden" name="status" value={status} />
          <input type="hidden" name="back" value={back} />
          <Textarea id={`${formId}-text`} name="note" label={text.note} icon={Note01Icon} rows={4} maxLength={500} defaultValue={note ?? ""} placeholder={text.notePlaceholder} />
        </form>
      </Modal>
    </>
  );
}
