"use client";

import { useState } from "react";
import { Delete02Icon, UserCheck01Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import type { DeletionError, ScheduledDeletion } from "@/lib/account-deletion";
import { format } from "@/lib/i18n/format";
import type { DeletionCopy } from "@/lib/i18n/account-deletion";

type Props = {
  scheduled: ScheduledDeletion | null;
  /** The profile page this card sits on, where the forms come back to. */
  back: string;
  copy: DeletionCopy;
  locale: string;
  error?: DeletionError | null;
  request: (formData: FormData) => Promise<void>;
  cancel: (formData: FormData) => Promise<void>;
  className?: string;
};

/**
 * "Delete my account" on a profile page (ADR 0028). Asking opens a confirmation that says what is erased, what the
 * school keeps and that it happens in 7 days; once asked, the card says when, with a button to keep the account.
 */
export function DeleteAccount({ scheduled, back, copy, locale, error, request, cancel, className = "" }: Props) {
  const [open, setOpen] = useState(false);
  const date = scheduled
    ? new Intl.DateTimeFormat(locale, { weekday: "long", day: "numeric", month: "long" }).format(new Date(scheduled.dueAt))
    : null;

  return (
    <section id="delete-account" aria-labelledby="delete-account-title" className={`scroll-mt-8 ${className}`}>
      <Card className="flex flex-col gap-3 p-5 sm:p-6">
        <h2 id="delete-account-title" className="m-0 text-lg font-bold">
          {copy.card.title}
        </h2>
        {error ? <Notice tone="bad">{copy.errors[error]}</Notice> : null}
        {scheduled && date ? (
          <>
            <Notice tone="warn">{format(scheduled.by === "platform" ? copy.card.scheduledByPlatform : copy.card.scheduled, { date })}</Notice>
            <form action={cancel}>
              <input type="hidden" name="back" value={back} />
              <Button type="submit" variant="secondary" icon={UserCheck01Icon}>
                {copy.card.cancel}
              </Button>
            </form>
          </>
        ) : (
          <>
            <p className="m-0 text-sm text-muted">{copy.card.body}</p>
            <div>
              <Button variant="danger" icon={Delete02Icon} onClick={() => setOpen(true)}>
                {copy.card.open}
              </Button>
            </div>
          </>
        )}
      </Card>

      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title={copy.confirm.title}
        actions={
          <>
            <Button variant="ghost" onClick={() => setOpen(false)}>
              {copy.confirm.keep}
            </Button>
            <form action={request}>
              <input type="hidden" name="back" value={back} />
              <Button type="submit" variant="danger" icon={Delete02Icon}>
                {copy.confirm.delete}
              </Button>
            </form>
          </>
        }
      >
        <div className="flex flex-col gap-3 text-sm">
          <p className="m-0 font-semibold">{copy.confirm.intro}</p>
          <ul className="m-0 flex list-disc flex-col gap-1 pl-5">
            {copy.confirm.erased.map((line) => (
              <li key={line}>{line}</li>
            ))}
          </ul>
          <p className="m-0">{copy.confirm.kept}</p>
          <p className="m-0">{copy.confirm.subscription}</p>
          <p className="m-0 text-muted">{copy.confirm.signInAgain}</p>
          <p className="m-0 text-muted">{copy.confirm.cancelHint}</p>
        </div>
      </Modal>
    </section>
  );
}
