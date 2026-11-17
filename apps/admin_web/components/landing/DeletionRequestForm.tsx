"use client";

import { useActionState } from "react";
import { Mail01Icon, Message01Icon, SentIcon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Notice } from "@/components/ui/Notice";
import { Textarea } from "@/components/ui/Textarea";
import type { DeletionCopy } from "@/lib/i18n/account-deletion";
import type { InterestOutcome } from "@/lib/landing/interest";

type Props = {
  action: (previous: InterestOutcome | null, form: FormData) => Promise<InterestOutcome>;
  copy: DeletionCopy["page"];
  locale: "en" | "fr";
};

/** For someone who cannot sign in any more: the email of their account, sent to the platform to confirm and schedule. */
export function DeletionRequestForm({ action, copy, locale }: Props) {
  const [outcome, formAction, pending] = useActionState(action, null);
  const done = outcome === "stored" || outcome === "already";
  return (
    <form action={formAction} className="flex flex-col gap-4" data-testid="deletion-request">
      <input type="hidden" name="locale" value={locale} />
      {/* Left empty by people; a bot that fills it is answered as if stored, and nothing is kept. */}
      <input type="text" name="website" tabIndex={-1} autoComplete="off" aria-hidden className="absolute -left-[9999px] h-0 w-0 opacity-0" />
      {done ? (
        <Notice tone="ok">{outcome === "already" ? copy.already : copy.sent}</Notice>
      ) : (
        <>
          {outcome ? <Notice tone="bad">{copy[outcome as "invalid" | "busy" | "failed"]}</Notice> : null}
          <Input id="deletion-email" name="email" type="email" label={copy.email} icon={Mail01Icon} required maxLength={254} autoComplete="email" />
          <Textarea id="deletion-message" name="message" label={copy.message} icon={Message01Icon} rows={3} maxLength={1000} />
          <div>
            <Button type="submit" icon={SentIcon} disabled={pending}>
              {copy.send}
            </Button>
          </div>
        </>
      )}
    </form>
  );
}
