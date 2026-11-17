"use client";

import { useRef, useState } from "react";
import { FloppyDiskIcon, Money03Icon, PencilEdit02Icon } from "@hugeicons/core-free-icons";

import { useFormAction } from "@/components/payments/useFormAction";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Switch } from "@/components/ui/Choice";
import { DatePicker, type DatePickerText } from "@/components/ui/DatePicker";
import { Input } from "@/components/ui/Input";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import { SideSheet } from "@/components/ui/SideSheet";
import { useToast } from "@/components/ui/Toast";
import { formatAmount } from "@/lib/billing";
import { format } from "@/lib/i18n/format";
import type { PlatformPaymentsCopy } from "@/lib/i18n/platform-payments";
import { isProvider, type PlatformPaymentState, type SchoolPayments } from "@/lib/platform-payments";

import { ConfirmPayoutNumber } from "./ConfirmPayoutNumber";

type Action = (previous: PlatformPaymentState, formData: FormData) => Promise<PlatformPaymentState>;

type Props = {
  schoolId: string;
  schoolName: string;
  payments: SchoolPayments;
  /** The platform's charges, used when the school has none of its own. */
  platformCharges: { semester: number; month: number } | null;
  locale: "en" | "fr";
  /** The time the page was made (ISO), to tell a number not usable yet. */
  now: string;
  copy: PlatformPaymentsCopy;
  dateText: DatePickerText;
  actions: { save: Action; confirm: Action };
};

const dayText = (iso: string, locale: string) => new Intl.DateTimeFormat(locale, { day: "numeric", month: "long", year: "numeric", timeZone: "UTC" }).format(new Date(`${iso.slice(0, 10)}T00:00:00Z`));

/**
 * A school's payments on its console page (ADR 0029): mobile money on or off, from when BusIn charges it and how much,
 * who pays the fees (the school's choice, read only), its balance, its payout number (with Confirm for one waiting), what
 * it collected in 30 days and its open issues. The terms change in a side sheet, saved after a confirmation.
 */
export function SchoolPaymentsCard({ schoolId, schoolName, payments, platformCharges, locale, now, copy, dateText, actions }: Props) {
  const c = copy.school;
  const toast = useToast();
  const form = useRef<HTMLFormElement>(null);
  const [sheet, setSheet] = useState(false);
  const [review, setReview] = useState<string | null>(null);
  const save = useFormAction(actions.save, (answer) => {
    setReview(null);
    if (!answer?.ok) return;
    toast(c.saved, { tone: "ok" });
    setSheet(false);
  });
  const money = (n: number) => formatAmount(n, locale);
  const terms = payments.terms;
  const enabled = terms?.enabled ?? false;
  const error = save.state && !save.state.ok ? save.state.error : null;
  const on = (key: string) => (error === key ? copy.errors[key as keyof typeof copy.errors] : undefined);
  const charge = (own: number | null | undefined, platform: number | undefined) =>
    own !== null && own !== undefined ? money(own) : format(c.platformDefault, { amount: money(platform ?? 0) });
  const account = payments.payoutAccount;
  const operator = (provider: string) => (isProvider(provider) ? copy.operators[provider] : provider);
  const phone = (masked: string) => (masked.startsWith("+") ? masked : `+${masked}`);

  const ask = () => {
    const data = form.current ? new FormData(form.current) : null;
    if (!data) return;
    const willEnable = data.get("enabled") === "on";
    const from = String(data.get("charges_from") ?? "");
    save.reset();
    setReview(willEnable ? format(c.confirmOn, { date: from ? dayText(from, locale) : c.noCharges }) : c.confirmOff);
  };

  return (
    <Card className="scroll-mt-32 p-6!">
      <section id="payments" aria-labelledby="payments-title" data-testid="school-payments" data-enabled={enabled ? "true" : "false"} className="flex flex-col gap-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h2 id="payments-title" className="m-0 text-base font-bold">
            {c.title}
          </h2>
          <Chip tone={enabled ? "ok" : "neutral"}>{enabled ? c.on : c.off}</Chip>
        </div>

        <dl className="m-0 grid grid-cols-2 gap-x-4 gap-y-3 text-sm">
          <div className="col-span-2">
            <dt className="text-muted">{c.chargesFrom}</dt>
            <dd className="m-0 font-semibold">{terms?.chargesFrom ? dayText(terms.chargesFrom, locale) : c.noDate}</dd>
          </div>
          <div>
            <dt className="text-muted">{c.chargeSemester}</dt>
            <dd className="m-0 font-semibold tabular-nums">{charge(terms?.chargeSemester, platformCharges?.semester)}</dd>
          </div>
          <div>
            <dt className="text-muted">{c.chargeMonth}</dt>
            <dd className="m-0 font-semibold tabular-nums">{charge(terms?.chargeMonth, platformCharges?.month)}</dd>
          </div>
          <div className="col-span-2">
            <dt className="text-muted">{c.feesPaidBy}</dt>
            <dd className="m-0 font-semibold">{c.feesBy[payments.feesPaidBy]}</dd>
          </div>
          <div>
            <dt className="text-muted">{c.available}</dt>
            <dd className="m-0 font-semibold tabular-nums">{money(payments.balance.available)}</dd>
          </div>
          <div>
            <dt className="text-muted">{c.onHold}</dt>
            <dd className="m-0 font-semibold tabular-nums">{money(payments.balance.onHold)}</dd>
          </div>
          {payments.balance.owed > 0 ? (
            <div>
              <dt className="text-muted">{c.owed}</dt>
              <dd className="m-0 font-semibold text-warn tabular-nums">{money(payments.balance.owed)}</dd>
            </div>
          ) : null}
          <div>
            <dt className="text-muted">{c.collected}</dt>
            <dd className="m-0 font-semibold tabular-nums">{money(payments.collected30d)}</dd>
          </div>
          <div>
            <dt className="text-muted">{c.issues}</dt>
            <dd className={`m-0 font-semibold tabular-nums ${payments.openIssues > 0 ? "text-bad" : ""}`}>{payments.openIssues}</dd>
          </div>
        </dl>

        <div className="flex flex-col gap-2 rounded-md bg-surface-2 p-4 text-sm" data-testid="school-payout-number">
          <span className="flex items-center justify-between gap-2">
            <span className="text-muted">{c.payout}</span>
            {account?.status === "proposed" ? <Chip tone="warn">{c.waiting}</Chip> : null}
          </span>
          {account ? (
            <>
              <span className="font-semibold">
                {operator(account.provider)} <span className="tabular-nums">{phone(account.phoneMasked)}</span>
              </span>
              {account.accountName ? <span>{account.accountName}</span> : null}
              {account.status === "active" && account.usableFrom && Date.parse(account.usableFrom) > Date.parse(now) ? (
                <span className="text-xs text-muted">{format(c.usableFrom, { date: dayText(account.usableFrom, locale) })}</span>
              ) : null}
              {account.status === "proposed" ? (
                <div>
                  <ConfirmPayoutNumber
                    account={account.id}
                    school={schoolName}
                    detail={`${operator(account.provider)} ${phone(account.phoneMasked)}${account.accountName ? `, ${account.accountName}` : ""}`}
                    copy={copy.alerts}
                    errors={copy.errors}
                    action={actions.confirm}
                  />
                </div>
              ) : null}
            </>
          ) : (
            <span className="font-semibold">{c.noPayout}</span>
          )}
        </div>

        <div>
          <Button
            type="button"
            variant="ghost"
            className="-ml-3"
            icon={PencilEdit02Icon}
            onClick={() => {
              save.reset();
              setSheet(true);
            }}
          >
            {c.change}
          </Button>
        </div>
      </section>

      <SideSheet open={sheet} onClose={() => setSheet(false)} title={c.sheetTitle} closeLabel={c.close}>
        <form
          ref={form}
          id="school-terms"
          onSubmit={(event) => {
            if (review === null) {
              event.preventDefault();
              ask();
              return;
            }
            save.onSubmit(event);
          }}
          className="flex flex-col gap-5"
          data-testid="school-terms-sheet"
          noValidate
        >
          <input type="hidden" name="school" value={schoolId} />
          <Switch name="enabled" label={c.enabled} hint={c.enabledHint} defaultChecked={enabled} />
          <DatePicker
            id="charges-from"
            name="charges_from"
            label={c.chargesFrom}
            hint={c.chargesFromHint}
            defaultValue={terms?.chargesFrom ?? ""}
            locale={locale}
            text={dateText}
            error={on("bad_date")}
          />
          <Input
            id="charge-semester"
            name="charge_semester_xaf"
            label={`${c.chargeSemester} (XAF)`}
            icon={Money03Icon}
            inputMode="numeric"
            autoComplete="off"
            defaultValue={terms?.chargeSemester ?? ""}
            hint={format(c.chargeHint, { amount: money(platformCharges?.semester ?? 0) })}
            error={on("bad_charge")}
          />
          <Input
            id="charge-month"
            name="charge_month_xaf"
            label={`${c.chargeMonth} (XAF)`}
            icon={Money03Icon}
            inputMode="numeric"
            autoComplete="off"
            defaultValue={terms?.chargeMonth ?? ""}
            hint={format(c.chargeHint, { amount: money(platformCharges?.month ?? 0) })}
            error={on("bad_charge")}
          />
          {error && !["bad_date", "bad_charge"].includes(error) ? <Notice tone="bad">{copy.errors[error as keyof typeof copy.errors] ?? copy.errors.generic}</Notice> : null}
          <div>
            <Button type="button" icon={FloppyDiskIcon} onClick={ask} disabled={save.pending}>
              {c.save}
            </Button>
          </div>
          <Modal
            open={review !== null}
            onClose={() => setReview(null)}
            title={format(c.confirmTitle, { school: schoolName })}
            description={review ?? undefined}
            actions={
              <>
                <Button type="button" variant="ghost" onClick={() => setReview(null)}>
                  {c.cancel}
                </Button>
                <Button type="submit" form="school-terms" icon={FloppyDiskIcon} disabled={save.pending}>
                  {c.save}
                </Button>
              </>
            }
          />
        </form>
      </SideSheet>
    </Card>
  );
}
