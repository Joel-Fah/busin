"use client";

import { useState } from "react";
import { Delete02Icon, Money03Icon, MoneySend01Icon, Note01Icon } from "@hugeicons/core-free-icons";

import { useFormAction } from "@/components/payments/useFormAction";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { RadioGroup } from "@/components/ui/Choice";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import { SideSheet } from "@/components/ui/SideSheet";
import { useToast } from "@/components/ui/Toast";
import { format } from "@/lib/i18n/format";
import type { PlatformPaymentsCopy } from "@/lib/i18n/platform-payments";
import { MAX_COST_NOTE, WALLET_KINDS, type PlatformPaymentState } from "@/lib/platform-payments";

type Action = (previous: PlatformPaymentState, formData: FormData) => Promise<PlatformPaymentState>;

/** A movement as the page writes it: its kind, the amount and when, already in words. */
export type WalletMovementRow = { id: string; kind: "withdrawal" | "top_up"; amount: string; when: string; note: string | null };

type Props = {
  copy: PlatformPaymentsCopy["wallet"];
  errors: PlatformPaymentsCopy["errors"];
  action: Action;
  /** The latest movements, newest first, each removable when entered by mistake. */
  movements?: WalletMovementRow[];
  remove?: Action;
};

/**
 * Records BusIn taking money out of its pawaPay wallet (to its bank) or putting money in, so the books, and the daily
 * check of the wallet against them, count it.
 */
export function WalletMovement({ copy, errors, action, movements = [], remove }: Props) {
  const toast = useToast();
  const [sheet, setSheet] = useState(false);
  const [removing, setRemoving] = useState<{ id: string; text: string } | null>(null);
  const removal = useFormAction(remove ?? action, (answer) => {
    if (!answer?.ok) return;
    toast(copy.removed, { tone: "ok" });
    setRemoving(null);
  });
  const removalError = removal.state && !removal.state.ok ? (errors[removal.state.error as keyof typeof errors] ?? errors.generic) : null;
  const record = useFormAction(action, (answer) => {
    if (!answer?.ok) return;
    toast(copy.recorded, { tone: "ok" });
    setSheet(false);
  });
  const error = record.state && !record.state.ok ? record.state.error : null;
  const on = (key: string) => (error === key ? errors[key as keyof typeof errors] : undefined);

  return (
    <Card className="flex flex-col gap-4 p-6!">
      <section aria-labelledby="wallet-title" data-testid="wallet-movements" className="flex flex-col gap-4">
        <div>
          <h2 id="wallet-title" className="m-0 text-xl font-bold">
            {copy.title}
          </h2>
          <p className="mt-1 mb-0 text-sm text-muted">{copy.hint}</p>
        </div>
        <div>
          <Button
            type="button"
            variant="secondary"
            icon={MoneySend01Icon}
            onClick={() => {
              record.reset();
              setSheet(true);
            }}
          >
            {copy.record}
          </Button>
        </div>
        <div>
          <h3 className="m-0 mb-2 text-sm font-semibold text-muted">{copy.recent}</h3>
          {movements.length === 0 ? (
            <p className="m-0 text-sm text-muted">{copy.none}</p>
          ) : (
            <ul className="m-0 flex list-none flex-col gap-1.5 p-0">
              {movements.map((m) => (
                <li key={m.id} data-movement={m.kind} className="flex items-center justify-between gap-3 rounded-md bg-surface-2 py-1 pr-1 pl-4 text-sm">
                  <span className="min-w-0">
                    <span className="font-semibold">{copy.kinds[m.kind]}</span>
                    <span className="block truncate text-xs text-muted">{m.note ? `${m.when} · ${m.note}` : m.when}</span>
                  </span>
                  <span className="flex shrink-0 items-center gap-1">
                    {/* Out of the wallet is money leaving: red with its sign; in is green. The kind says it in words. */}
                    <span className={`font-semibold tabular-nums ${m.kind === "withdrawal" ? "text-bad" : "text-ok"}`}>
                      {m.kind === "withdrawal" ? "-" : "+"}
                      {m.amount}
                    </span>
                    {remove ? (
                      <button
                        type="button"
                        aria-label={`${copy.remove}: ${copy.kinds[m.kind]}, ${m.amount}`}
                        data-tip={copy.remove}
                        onClick={() => {
                          removal.reset();
                          setRemoving({ id: m.id, text: format(copy.removeBody, { kind: copy.kinds[m.kind], amount: m.amount, when: m.when }) });
                        }}
                        className="grid size-9 cursor-pointer place-items-center rounded-xs border-0 bg-transparent text-muted hover:text-bad focus-visible:outline-3 focus-visible:outline-focus"
                      >
                        <Icon icon={Delete02Icon} size={18} />
                      </button>
                    ) : null}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </section>

      <SideSheet open={sheet} onClose={() => setSheet(false)} title={copy.sheetTitle} closeLabel={copy.close}>
        <form onSubmit={record.onSubmit} className="flex flex-col gap-5" data-testid="wallet-sheet" noValidate>
          <RadioGroup legend={copy.kind} name="kind" defaultValue="withdrawal" options={WALLET_KINDS.map((kind) => ({ value: kind, label: copy.kinds[kind] }))} />
          <Input id="wallet-amount" name="amount" label={copy.amount} icon={Money03Icon} inputMode="numeric" required autoComplete="off" error={on("bad_amount")} />
          <Input id="wallet-note" name="note" label={copy.note} hint={copy.noteHint} icon={Note01Icon} maxLength={MAX_COST_NOTE} autoComplete="off" error={on("bad_note")} />
          {error && !["bad_amount", "bad_note"].includes(error) ? <Notice tone="bad">{errors[error as keyof typeof errors] ?? errors.generic}</Notice> : null}
          <div>
            <Button type="submit" icon={MoneySend01Icon} disabled={record.pending}>
              {copy.save}
            </Button>
          </div>
        </form>
      </SideSheet>

      <Modal
        open={removing !== null}
        onClose={() => setRemoving(null)}
        title={copy.removeTitle}
        description={removing?.text}
        actions={
          <form onSubmit={removal.onSubmit} className="flex flex-wrap justify-end gap-3">
            <input type="hidden" name="movement" value={removing?.id ?? ""} />
            <Button type="button" variant="ghost" onClick={() => setRemoving(null)}>
              {copy.cancel}
            </Button>
            <Button type="submit" variant="danger" icon={Delete02Icon} disabled={removal.pending}>
              {copy.remove}
            </Button>
          </form>
        }
      >
        {removalError ? <Notice tone="bad">{removalError}</Notice> : null}
      </Modal>
    </Card>
  );
}
