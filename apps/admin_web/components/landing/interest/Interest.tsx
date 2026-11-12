"use client";

import { Mail01Icon, Message01Icon, School01Icon, UserIcon } from "@hugeicons/core-free-icons";
import { createContext, useContext, useState, useTransition, type ReactNode } from "react";

import { submitInterest } from "@/app/(landing)/landing/actions";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Modal } from "@/components/ui/Modal";
import { Textarea } from "@/components/ui/Textarea";
import { useToast } from "@/components/ui/Toast";
import type { LandingCopy } from "@/lib/i18n/landing";
import type { Locale } from "@/lib/i18n/messages";
import { checkInterest, LIMITS, type InterestField, type InterestKind, type InterestProblem } from "@/lib/landing/interest";

const OpenInterest = createContext<(kind: InterestKind) => void>(() => {});

/** Holds the one interest form of the page; any InterestButton below it opens it for its kind of request. */
export function InterestProvider({ copy, locale, children }: { copy: LandingCopy["form"]; locale: Locale; children: ReactNode }) {
  const [kind, setKind] = useState<InterestKind | null>(null);
  return (
    <OpenInterest.Provider value={setKind}>
      {children}
      {/* Mounted again for each opening, so the fields start empty. */}
      {kind ? <InterestForm key={kind} kind={kind} copy={copy} locale={locale} onClose={() => setKind(null)} /> : null}
    </OpenInterest.Provider>
  );
}

/** A button that opens the interest form for one kind of request. */
export function InterestButton({
  kind,
  children,
  className = "",
  variant = "primary",
}: {
  kind: InterestKind;
  children: ReactNode;
  className?: string;
  variant?: "primary" | "secondary";
}) {
  const open = useContext(OpenInterest);
  return (
    <Button type="button" variant={variant} className={className} onClick={() => open(kind)} data-interest={kind}>
      {children}
    </Button>
  );
}

function InterestForm({ kind, copy, locale, onClose }: { kind: InterestKind; copy: LandingCopy["form"]; locale: Locale; onClose: () => void }) {
  const toast = useToast();
  const [open, setOpen] = useState(true);
  const [problems, setProblems] = useState<Partial<Record<InterestField, InterestProblem>>>({});
  const [pending, startTransition] = useTransition();
  const school = kind === "school";

  const close = () => {
    setOpen(false);
    // Let the dialog play its closing motion before it leaves the page.
    window.setTimeout(onClose, 260);
  };

  const send = (form: HTMLFormElement) => {
    const data = new FormData(form);
    const value = (key: string) => String(data.get(key) ?? "");
    const found = checkInterest({ kind, email: value("email"), name: value("name"), organisation: value("organisation"), message: value("message") });
    setProblems(found);
    if (Object.keys(found).length > 0) return;
    startTransition(async () => {
      const outcome = await submitInterest(data);
      const good = outcome === "stored" || outcome === "already";
      toast(copy.outcomes[outcome], { tone: good ? "ok" : "bad" });
      if (good) close();
    });
  };

  const problem = (field: InterestField) => (problems[field] ? copy.problems[problems[field]] : undefined);

  return (
    <Modal
      open={open}
      onClose={close}
      title={copy.titles[kind]}
      description={copy.descriptions[kind]}
      actions={
        <>
          <Button type="button" variant="secondary" onClick={close}>
            {copy.cancel}
          </Button>
          <Button type="submit" form="interest-form" disabled={pending}>
            {pending ? copy.sending : copy.send}
          </Button>
        </>
      }
    >
      <form
        id="interest-form"
        noValidate
        className="flex flex-col gap-4"
        onSubmit={(event) => {
          event.preventDefault();
          send(event.currentTarget);
        }}
      >
        <input type="hidden" name="kind" value={kind} />
        <input type="hidden" name="locale" value={locale} />
        {/* Left empty by people, filled by bots: a request with it is dropped without a word. */}
        <div aria-hidden className="absolute -left-[9999px] size-px overflow-hidden">
          <label>
            Website
            <input type="text" name="website" tabIndex={-1} autoComplete="off" />
          </label>
        </div>
        {school ? (
          <>
            <Input id="interest-name" name="name" label={copy.name} icon={UserIcon} autoComplete="name" placeholder={copy.placeholders.name} maxLength={LIMITS.name} error={problem("name")} />
            <Input
              id="interest-organisation"
              name="organisation"
              label={copy.organisation}
              icon={School01Icon}
              autoComplete="organization"
              placeholder={copy.placeholders.organisation}
              maxLength={LIMITS.organisation}
              error={problem("organisation")}
            />
          </>
        ) : null}
        <Input
          id="interest-email"
          name="email"
          type="email"
          label={copy.email}
          icon={Mail01Icon}
          autoComplete="email"
          placeholder={copy.placeholders.email}
          maxLength={LIMITS.email}
          hint={copy.privacy}
          error={problem("email")}
        />
        {school ? (
          <Textarea
            id="interest-message"
            name="message"
            label={copy.message}
            icon={Message01Icon}
            hint={copy.messageHint}
            placeholder={copy.placeholders.message}
            maxLength={LIMITS.message}
            error={problem("message")}
            rows={3}
          />
        ) : null}
      </form>
    </Modal>
  );
}
