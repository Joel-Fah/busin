"use client";

import { useState } from "react";
import { Calendar03Icon, Delete02Icon, Money03Icon, Note01Icon, PlusSignIcon, Tag01Icon } from "@hugeicons/core-free-icons";

import { useFormAction } from "@/components/payments/useFormAction";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import { Select } from "@/components/ui/Select";
import { SideSheet } from "@/components/ui/SideSheet";
import { useToast } from "@/components/ui/Toast";
import { format } from "@/lib/i18n/format";
import type { PlatformPaymentsCopy } from "@/lib/i18n/platform-payments";
import { MAX_COST_NOTE, type PlatformPaymentState } from "@/lib/platform-payments";

type Action = (previous: PlatformPaymentState, formData: FormData) => Promise<PlatformPaymentState>;

export type CostMonth = { month: string; label: string; total: string; costs: { id: string; label: string; amount: string; note: string | null }[] };

type Props = {
  months: CostMonth[];
  /** The months a cost can be entered for, newest first. */
  choices: { value: string; label: string }[];
  copy: PlatformPaymentsCopy["costs"];
  errors: PlatformPaymentsCopy["errors"];
  actions: { add: Action; remove: Action };
};

/**
 * BusIn's monthly infrastructure costs (ADR 0029), so the margin is the real one: by month with each month's total, a
 * side sheet to add one, and a confirmation before deleting one.
 */
export function InfraCosts({ months, choices, copy, errors, actions }: Props) {
  const toast = useToast();
  const [sheet, setSheet] = useState(false);
  const [removing, setRemoving] = useState<{ id: string; text: string } | null>(null);
  const add = useFormAction(actions.add, (answer) => {
    if (!answer?.ok) return;
    toast(copy.added, { tone: "ok" });
    setSheet(false);
  });
  const remove = useFormAction(actions.remove, (answer) => {
    if (!answer?.ok) return;
    toast(copy.removed, { tone: "ok" });
    setRemoving(null);
  });
  const message = (state: PlatformPaymentState) => (state && !state.ok ? (errors[state.error as keyof typeof errors] ?? errors.generic) : null);
  const addError = add.state && !add.state.ok ? add.state.error : null;
  const on = (key: string) => (addError === key ? errors[key as keyof typeof errors] : undefined);

  return (
    <Card className="flex flex-col gap-4 p-6!">
      <section aria-labelledby="costs-title" data-testid="infra-costs" className="flex flex-col gap-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h2 id="costs-title" className="m-0 text-xl font-bold">
            {copy.title}
          </h2>
          <Button
            type="button"
            variant="secondary"
            icon={PlusSignIcon}
            onClick={() => {
              add.reset();
              setSheet(true);
            }}
          >
            {copy.add}
          </Button>
        </div>
        {months.length === 0 ? (
          <p className="m-0 text-sm text-muted">{copy.none}</p>
        ) : (
          <ul className="m-0 flex list-none flex-col gap-4 p-0">
            {months.map((m) => (
              <li key={m.month} data-month={m.month}>
                <div className="mb-1.5 flex items-baseline justify-between gap-3 text-sm">
                  <span className="font-semibold capitalize">{m.label}</span>
                  <span className="text-muted tabular-nums">
                    {copy.total} <strong className="text-fg">{m.total}</strong>
                  </span>
                </div>
                <ul className="m-0 flex list-none flex-col gap-1.5 p-0">
                  {m.costs.map((c) => (
                    <li key={c.id} data-cost={c.label} className="flex items-center justify-between gap-3 rounded-md bg-surface-2 py-1 pr-1 pl-4 text-sm">
                      <span className="min-w-0">
                        <span className="font-semibold">{c.label}</span>
                        {c.note ? <span className="block truncate text-xs text-muted">{c.note}</span> : null}
                      </span>
                      <span className="flex shrink-0 items-center gap-1">
                        <span className="font-semibold tabular-nums">{c.amount}</span>
                        <button
                          type="button"
                          aria-label={`${copy.remove}: ${c.label}`}
                          data-tip={copy.remove}
                          onClick={() => {
                            remove.reset();
                            setRemoving({ id: c.id, text: format(copy.removeBody, { label: c.label, amount: c.amount, month: m.label }) });
                          }}
                          className="grid size-9 cursor-pointer place-items-center rounded-xs border-0 bg-transparent text-muted hover:text-bad focus-visible:outline-3 focus-visible:outline-focus"
                        >
                          <Icon icon={Delete02Icon} size={18} />
                        </button>
                      </span>
                    </li>
                  ))}
                </ul>
              </li>
            ))}
          </ul>
        )}
      </section>

      <SideSheet open={sheet} onClose={() => setSheet(false)} title={copy.sheetTitle} closeLabel={copy.close}>
        <form onSubmit={add.onSubmit} className="flex flex-col gap-5" data-testid="infra-cost-sheet" noValidate>
          <Select id="cost-month" name="month" label={copy.month} icon={Calendar03Icon} options={choices} defaultValue={choices[0]?.value} error={on("bad_month")} />
          <Input id="cost-label" name="label" label={copy.label} hint={copy.labelHint} icon={Tag01Icon} required minLength={2} maxLength={80} autoComplete="off" error={on("bad_label")} />
          <Input id="cost-amount" name="amount" label={copy.amount} icon={Money03Icon} inputMode="numeric" required autoComplete="off" error={on("bad_amount")} />
          <Input id="cost-note" name="note" label={copy.note} icon={Note01Icon} maxLength={MAX_COST_NOTE} autoComplete="off" error={on("bad_note")} />
          {addError && !["bad_month", "bad_label", "bad_amount", "bad_note"].includes(addError) ? <Notice tone="bad">{message(add.state)}</Notice> : null}
          <div>
            <Button type="submit" icon={PlusSignIcon} disabled={add.pending}>
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
          <form onSubmit={remove.onSubmit} className="flex flex-wrap justify-end gap-3">
            <input type="hidden" name="cost" value={removing?.id ?? ""} />
            <Button type="button" variant="ghost" onClick={() => setRemoving(null)}>
              {copy.cancel}
            </Button>
            <Button type="submit" variant="danger" icon={Delete02Icon} disabled={remove.pending}>
              {copy.remove}
            </Button>
          </form>
        }
      >
        {message(remove.state) ? <Notice tone="bad">{message(remove.state)}</Notice> : null}
      </Modal>
    </Card>
  );
}
