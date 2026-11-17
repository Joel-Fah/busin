"use client";

import { Call02Icon, Cancel01Icon, Tick02Icon, UserIcon } from "@hugeicons/core-free-icons";
import { useState } from "react";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Radio } from "@/components/ui/Choice";
import { Input } from "@/components/ui/Input";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import { SideSheet } from "@/components/ui/SideSheet";
import { useToast } from "@/components/ui/Toast";
import { format } from "@/lib/i18n/messages";
import type { PaymentsCopy } from "@/lib/i18n/payments";
import { PROVIDERS, guessOperator, type PaymentActionState, type Provider } from "@/lib/payments";

import { useFormAction } from "./useFormAction";

type Action = (previous: PaymentActionState, formData: FormData) => Promise<PaymentActionState>;

type Props = {
  active: { provider: string; phone: string; name: string | null; since: string; later: boolean } | null;
  proposal: { id: string; provider: string; phone: string; name: string | null; by: string; at: string; mine: boolean } | null;
  soleAdmin: boolean;
  copy: PaymentsCopy["account"];
  operators: PaymentsCopy["operators"];
  errors: PaymentsCopy["errors"];
  actions: { propose: Action; confirm: Action; decline: Action };
};

const operatorOf = (operators: PaymentsCopy["operators"], provider: string) => (provider in operators ? operators[provider as Provider] : provider);

/**
 * The school's payout number (ADR 0029): the one in use, a proposal waiting for a second administrator (who confirms or
 * declines it; the one who proposed it can only withdraw it), and a side sheet to propose a new one.
 */
export function PayoutAccount({ active, proposal, soleAdmin, copy, operators, errors, actions }: Props) {
  const toast = useToast();
  const [sheet, setSheet] = useState(false);
  const [ask, setAsk] = useState<"confirm" | "decline" | null>(null);
  const [phone, setPhone] = useState("");
  const [provider, setProvider] = useState<Provider | null>(null);
  const [picked, setPicked] = useState(false);
  const propose = useFormAction(actions.propose, (answer) => {
    if (!answer?.ok) return;
    toast(copy.done.proposed, { tone: "ok" });
    setSheet(false);
  });
  const confirm = useFormAction(actions.confirm, (answer) => {
    if (answer?.ok) toast(copy.done.confirmed, { tone: "ok" });
    setAsk(null);
  });
  const decline = useFormAction(actions.decline, (answer) => {
    if (answer?.ok) toast(copy.done.declined, { tone: "ok" });
    setAsk(null);
  });

  // The network follows the number as it is typed, until it is chosen by hand.
  const shown = picked ? provider : (guessOperator(phone) ?? provider);

  const message = (state: PaymentActionState) => (state && !state.ok ? (errors[state.error as keyof typeof errors] ?? errors.generic) : null);
  const proposeError = propose.state && !propose.state.ok ? propose.state.error : null;
  const decisionError = message(confirm.state) ?? message(decline.state);

  return (
    <Card className="flex flex-col gap-5" contour>
      <div data-testid="payout-account" className="flex flex-col gap-5">
        <div>
          <h2 className="text-xl font-bold">{copy.title}</h2>
          <p className="mt-1 text-sm text-muted">{copy.hint}</p>
        </div>

        {active ? (
          <div className="flex flex-col gap-1 rounded-md bg-surface-2 p-4">
            <span className="flex flex-wrap items-center gap-2">
              <Chip tone={active.later ? "warn" : "ok"}>{copy.current}</Chip>
              <span className="font-semibold">{operatorOf(operators, active.provider)}</span>
            </span>
            <p className="m-0 mt-1 text-lg font-bold tabular-nums">{active.phone}</p>
            {active.name ? (
              <p className="m-0 text-sm">
                <span className="text-muted">{copy.holder}: </span>
                {active.name}
              </p>
            ) : null}
            <p className="m-0 text-sm text-muted">{format(active.later ? copy.usableFrom : copy.usableNow, { date: active.since })}</p>
          </div>
        ) : (
          <p className="m-0 text-sm font-semibold">{copy.none}</p>
        )}

        {proposal ? (
          <div className="flex flex-col gap-3 rounded-md bg-warn-bg p-4" data-testid="payout-proposal">
            <p className="m-0 text-sm font-bold text-warn">{copy.proposedTitle}</p>
            <div>
              <p className="m-0 font-semibold">
                {operatorOf(operators, proposal.provider)} <span className="tabular-nums">{proposal.phone}</span>
              </p>
              {proposal.name ? <p className="m-0 text-sm">{proposal.name}</p> : null}
              <p className="m-0 text-sm text-muted">{format(copy.proposedBy, { name: proposal.mine ? copy.you : proposal.by, date: proposal.at })}</p>
            </div>
            {proposal.mine ? <p className="m-0 text-sm">{soleAdmin ? copy.soleAdmin : copy.needsOther}</p> : null}
            {decisionError ? <Notice tone="bad">{decisionError}</Notice> : null}
            <div className="flex flex-wrap gap-2">
              {proposal.mine ? null : (
                <Button type="button" icon={Tick02Icon} onClick={() => setAsk("confirm")}>
                  {copy.confirm}
                </Button>
              )}
              <Button type="button" variant="ghost" icon={Cancel01Icon} onClick={() => setAsk("decline")}>
                {proposal.mine ? copy.withdraw : copy.decline}
              </Button>
            </div>
          </div>
        ) : null}

        <div>
          <Button type="button" variant="secondary" icon={Call02Icon} onClick={() => setSheet(true)}>
            {active ? copy.replace : copy.propose}
          </Button>
        </div>
      </div>

      <SideSheet open={sheet} onClose={() => setSheet(false)} title={copy.sheetTitle} closeLabel={copy.close}>
        <form onSubmit={propose.onSubmit} className="flex flex-col gap-5" data-testid="payout-sheet">
          {active ? <Notice tone="warn">{copy.replaceWarning}</Notice> : <p className="text-sm text-muted">{copy.firstNote}</p>}
          <Input
            id="payout-phone"
            name="phone"
            label={copy.number}
            hint={copy.numberHint}
            icon={Call02Icon}
            inputMode="tel"
            autoComplete="off"
            required
            maxLength={40}
            value={phone}
            onChange={(event) => setPhone(event.target.value)}
            error={proposeError === "bad_phone" ? errors.bad_phone : undefined}
          />
          <fieldset className="m-0 flex flex-col gap-3 border-0 p-0">
            <legend className="mb-1 p-0 text-sm font-semibold">{copy.operator}</legend>
            {PROVIDERS.map((p) => (
              <Radio
                key={p}
                name="provider"
                value={p}
                label={operators[p]}
                checked={shown === p}
                onChange={() => {
                  setProvider(p);
                  setPicked(true);
                }}
              />
            ))}
            {proposeError === "bad_provider" ? (
              <p role="alert" className="m-0 text-sm text-bad">
                {errors.bad_provider}
              </p>
            ) : null}
          </fieldset>
          <Input
            id="payout-name"
            name="name"
            label={copy.name}
            hint={copy.nameHint}
            icon={UserIcon}
            autoComplete="off"
            required
            maxLength={120}
            error={proposeError === "bad_name" ? errors.bad_name : undefined}
          />
          {proposeError && !["bad_phone", "bad_provider", "bad_name"].includes(proposeError) ? <Notice tone="bad">{message(propose.state)}</Notice> : null}
          <div>
            <Button type="submit" icon={Tick02Icon} disabled={propose.pending}>
              {copy.send}
            </Button>
          </div>
        </form>
      </SideSheet>

      {proposal ? (
        <>
          <Modal
            open={ask === "confirm"}
            onClose={() => setAsk(null)}
            title={copy.confirmTitle}
            description={`${format(copy.confirmBody, { operator: operatorOf(operators, proposal.provider), phone: proposal.phone, name: proposal.name ?? "-" })}${active ? ` ${copy.confirmReplace}` : ""}`}
            actions={
              <form onSubmit={confirm.onSubmit} className="flex flex-wrap justify-end gap-3">
                <input type="hidden" name="account" value={proposal.id} />
                <Button type="button" variant="ghost" onClick={() => setAsk(null)}>
                  {copy.cancel}
                </Button>
                <Button type="submit" icon={Tick02Icon} disabled={confirm.pending}>
                  {copy.confirm}
                </Button>
              </form>
            }
          />
          <Modal
            open={ask === "decline"}
            onClose={() => setAsk(null)}
            title={copy.declineTitle}
            description={copy.declineBody}
            actions={
              <form onSubmit={decline.onSubmit} className="flex flex-wrap justify-end gap-3">
                <input type="hidden" name="account" value={proposal.id} />
                <Button type="button" variant="ghost" onClick={() => setAsk(null)}>
                  {copy.cancel}
                </Button>
                <Button type="submit" variant="danger" icon={Cancel01Icon} disabled={decline.pending}>
                  {proposal.mine ? copy.withdraw : copy.decline}
                </Button>
              </form>
            }
          />
        </>
      ) : null}
    </Card>
  );
}
