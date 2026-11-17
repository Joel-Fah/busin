"use client";

import { useRef, useState, type FormEvent } from "react";
import { Clock01Icon, FloppyDiskIcon, Money03Icon, PercentIcon } from "@hugeicons/core-free-icons";

import { useFormAction } from "@/components/payments/useFormAction";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Switch } from "@/components/ui/Choice";
import { Input } from "@/components/ui/Input";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import { useToast } from "@/components/ui/Toast";
import { formatAmount } from "@/lib/billing";
import { format } from "@/lib/i18n/format";
import type { PlatformPaymentsCopy } from "@/lib/i18n/platform-payments";
import {
  OPERATIONS,
  PROVIDERS,
  SETTING_RULES,
  feeEstimate,
  parseSettingsForm,
  rateField,
  settingsChanges,
  type PlatformPaymentState,
  type SettingKey,
  type SettingsForm,
  type SettingsSnapshot,
} from "@/lib/platform-payments";

type Props = {
  current: SettingsSnapshot;
  locale: string;
  copy: PlatformPaymentsCopy["settings"];
  operators: PlatformPaymentsCopy["operators"];
  errors: PlatformPaymentsCopy["errors"];
  action: (previous: PlatformPaymentState, formData: FormData) => Promise<PlatformPaymentState>;
};

/** The price the estimate is worked out on. */
const EXAMPLE_PRICE = 20000;

/** A setting's value as the form shows it: a decimal in the reader's language, a whole number plain. */
const shown = (value: number | null, locale: string) => (value === null ? "" : String(value).replace(".", locale === "fr" ? "," : "."));

/**
 * The payment settings in plain words, grouped (what pawaPay and the operators take, the student's fee, the schools),
 * with an estimate of what a student pays worked out from the values as they are typed. Saving shows each change and
 * asks to confirm; the server sends only what changed, so the platform audit names each one.
 */
export function PaymentSettingsForm({ current, locale, copy, operators, errors, action }: Props) {
  const toast = useToast();
  const form = useRef<HTMLFormElement>(null);
  const [values, setValues] = useState<SettingsForm>({ settings: current.settings, rates: current.rates });
  const [fieldError, setFieldError] = useState<string | null>(null);
  const [review, setReview] = useState<string[] | null>(null);
  const save = useFormAction(action, (answer) => {
    setReview(null);
    if (answer?.ok) toast(answer.done === "unchanged" ? copy.unchanged : copy.saved, { tone: "ok" });
    else if (answer && answer.error.startsWith("field:")) setFieldError(answer.error.slice(6));
  });
  const money = (n: number) => formatAmount(n, locale);
  const serverError = save.state && !save.state.ok && !save.state.error.startsWith("field:") ? (errors[save.state.error as keyof typeof errors] ?? errors.generic) : null;
  const errorOn = (field: string) => (fieldError === field ? copy.fieldError : undefined);

  const read = () => (form.current ? parseSettingsForm(new FormData(form.current)) : null);
  const onChange = () => {
    const parsed = read();
    if (parsed?.ok) {
      setValues(parsed.value);
      setFieldError(null);
    }
  };

  const unit = (key: SettingKey) => {
    const kind = SETTING_RULES[key].kind;
    return kind === "percent" ? copy.units.percent : kind === "xaf" ? copy.units.xaf : key === "hold_days" ? copy.units.days : copy.units.perHour;
  };
  const valueText = (key: SettingKey, value: unknown) =>
    typeof value === "boolean" ? (value ? copy.on : copy.off) : SETTING_RULES[key].kind === "percent" ? `${shown(value as number, locale)} %` : `${shown(value as number, locale)} ${unit(key)}`;

  /** Checks the form, then lists what would change for the confirmation. */
  const ask = () => {
    const parsed = read();
    if (!parsed) return;
    if (!parsed.ok) {
      setFieldError(parsed.field);
      document.getElementById(parsed.field)?.focus();
      return;
    }
    setFieldError(null);
    const changes = settingsChanges(current, parsed.value);
    const lines = [
      ...Object.entries(changes.settings).map(([key, value]) => `${copy.fields[key as SettingKey]}: ${valueText(key as SettingKey, current.settings[key as SettingKey])} > ${valueText(key as SettingKey, value)}`),
      ...changes.rates.map((rate) => {
        const before = current.rates.find((r) => r.provider === rate.provider && r.operation === rate.operation);
        const text = (r: { percent: number | null; fixed: number } | undefined) =>
          !r || r.percent === null ? copy.notSet : `${shown(r.percent, locale)} %${r.fixed ? ` + ${money(r.fixed)}` : ""}`;
        return `${operators[rate.provider]}, ${copy.rates.operations[rate.operation]}: ${text(before)} > ${text(rate)}`;
      }),
    ];
    if (lines.length === 0) {
      toast(copy.unchanged, { tone: "info" });
      return;
    }
    save.reset();
    setReview(lines);
  };

  const field = (key: Exclude<SettingKey, "student_fee_allowed">, hint?: string) => (
    <Input
      id={key}
      name={key}
      label={`${copy.fields[key]} (${unit(key)})`}
      icon={SETTING_RULES[key].kind === "percent" ? PercentIcon : SETTING_RULES[key].kind === "xaf" ? Money03Icon : Clock01Icon}
      inputMode={SETTING_RULES[key].kind === "percent" ? "decimal" : "numeric"}
      autoComplete="off"
      defaultValue={shown(current.settings[key], locale)}
      hint={hint}
      error={errorOn(key)}
    />
  );

  const estimate = feeEstimate(values.settings, values.rates, EXAMPLE_PRICE, values.settings.charge_semester_xaf);

  // Enter in a field asks first, as the button does; only the dialog's button saves.
  const onSubmit = (event: FormEvent<HTMLFormElement>) => {
    if (review === null) {
      event.preventDefault();
      ask();
      return;
    }
    save.onSubmit(event);
  };

  return (
    <form ref={form} id="payment-settings" onSubmit={onSubmit} onChange={onChange} className="flex flex-col gap-6" noValidate data-testid="payment-settings">
      <div className="grid grid-cols-[minmax(0,1fr)] gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,22rem)]">
        <div className="flex min-w-0 flex-col gap-6">
          <Card className="flex flex-col gap-5 p-6!">
            <h2 className="m-0 text-xl font-bold">{copy.groups.takes}</h2>
            <div className="grid gap-4 sm:grid-cols-2">
              {field("pawapay_percent")}
              {field("pawapay_vat_percent", copy.hints.pawapay_vat_percent)}
            </div>
            <fieldset className="m-0 flex flex-col gap-4 border-0 p-0" data-testid="provider-rates">
              <legend className="mb-1 p-0 text-sm font-semibold">{copy.rates.caption}</legend>
              {PROVIDERS.map((provider) => (
                <div key={provider} className="flex flex-col gap-2 rounded-md bg-surface-2/60 p-4">
                  <p className="m-0 font-semibold">{operators[provider]}</p>
                  <div className="grid gap-3 sm:grid-cols-3">
                    {OPERATIONS.map((operation) => {
                      const rate = current.rates.find((r) => r.provider === provider && r.operation === operation);
                      const percentName = rateField(provider, operation, "percent");
                      const fixedName = rateField(provider, operation, "fixed");
                      const names = { operator: operators[provider], operation: copy.rates.operations[operation] };
                      return (
                        <div key={operation} className="flex flex-col gap-2">
                          <p className="m-0 text-xs font-semibold tracking-wide text-muted uppercase">{copy.rates.operations[operation]}</p>
                          <Input
                            id={percentName}
                            name={percentName}
                            label={format(copy.rates.percent, names)}
                            className="[&>label]:sr-only"
                            icon={PercentIcon}
                            inputMode="decimal"
                            autoComplete="off"
                            placeholder={copy.notSet}
                            defaultValue={shown(rate?.percent ?? null, locale)}
                            error={errorOn(percentName)}
                          />
                          <Input
                            id={fixedName}
                            name={fixedName}
                            label={format(copy.rates.fixed, names)}
                            className="[&>label]:sr-only"
                            icon={Money03Icon}
                            inputMode="numeric"
                            autoComplete="off"
                            defaultValue={String(rate?.fixed ?? 0)}
                            error={errorOn(fixedName)}
                          />
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
              <p className="m-0 text-sm text-muted">{copy.rates.empty}</p>
            </fieldset>
          </Card>

          <Card className="flex flex-col gap-5 p-6!">
            <h2 className="m-0 text-xl font-bold">{copy.groups.student}</h2>
            <div className="grid gap-4 sm:grid-cols-2">
              {field("fee_buffer_percent", copy.hints.fee_buffer_percent)}
              {field("fee_min_xaf")}
            </div>
            <Switch id="student_fee_allowed" name="student_fee_allowed" label={copy.fields.student_fee_allowed} hint={copy.hints.student_fee_allowed} defaultChecked={current.settings.student_fee_allowed} />
            {field("max_starts_per_hour")}
          </Card>

          <Card className="flex flex-col gap-5 p-6!">
            <h2 className="m-0 text-xl font-bold">{copy.groups.schools}</h2>
            <div className="grid gap-4 sm:grid-cols-2">
              {field("hold_days")}
              {field("payout_min_xaf")}
              {field("charge_semester_xaf", copy.hints.charge)}
              {field("charge_month_xaf", copy.hints.charge)}
            </div>
          </Card>
        </div>

        <aside className="flex min-w-0 flex-col gap-4 lg:sticky lg:top-6 lg:self-start">
          <Card className="flex flex-col gap-4 p-6!">
            <section aria-labelledby="estimate-title" aria-live="polite" data-testid="fee-estimate" className="flex flex-col gap-3">
              <h2 id="estimate-title" className="m-0 text-base font-bold">
                {copy.estimate.title}
              </h2>
              <p className="m-0 text-sm text-muted">{format(copy.estimate.body, { price: money(EXAMPLE_PRICE), charge: money(values.settings.charge_semester_xaf) })}</p>
              <ul className="m-0 flex list-none flex-col gap-2 p-0">
                <li className="flex items-baseline justify-between gap-3 rounded-md bg-surface-2 px-4 py-3 text-sm">
                  <span className="font-semibold">{copy.estimate.receipt}</span>
                  <strong className="tabular-nums">{money(estimate.receipt)}</strong>
                </li>
                {estimate.operators.map((o) => (
                  <li key={o.provider} data-provider={o.provider} className="flex flex-col gap-0.5 rounded-md bg-surface-2 px-4 py-3 text-sm">
                    <span className="flex items-baseline justify-between gap-3">
                      <span className="font-semibold">{operators[o.provider]}</span>
                      <strong className="tabular-nums">{"stopped" in o ? "-" : money(o.studentPays)}</strong>
                    </span>
                    <span className="text-xs text-muted tabular-nums">
                      {"stopped" in o
                        ? copy.estimate.stopped
                        : o.schoolBears > 0
                          ? format(copy.estimate.bears, { cost: money(o.schoolBears) })
                          : format(copy.estimate.fee, { fee: money(o.fee) })}
                    </span>
                  </li>
                ))}
              </ul>
              <p className="m-0 text-xs text-muted">{copy.estimate.note}</p>
            </section>
          </Card>
          {serverError ? <Notice tone="bad">{serverError}</Notice> : null}
          <div>
            <Button type="button" icon={FloppyDiskIcon} onClick={ask} disabled={save.pending} data-testid="settings-save">
              {copy.save}
            </Button>
          </div>
        </aside>
      </div>

      <Modal
        open={review !== null}
        onClose={() => setReview(null)}
        title={copy.confirmTitle}
        description={copy.confirmBody}
        actions={
          <>
            <Button type="button" variant="ghost" onClick={() => setReview(null)}>
              {copy.cancel}
            </Button>
            <Button type="submit" form="payment-settings" icon={FloppyDiskIcon} disabled={save.pending}>
              {copy.save}
            </Button>
          </>
        }
      >
        <ul className="m-0 flex list-none flex-col gap-1.5 p-0 text-sm" data-testid="settings-changes">
          {(review ?? []).map((line) => (
            <li key={line} className="rounded-xs bg-surface-2 px-3 py-2 tabular-nums">
              {line}
            </li>
          ))}
        </ul>
      </Modal>
    </form>
  );
}
