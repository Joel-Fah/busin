import type { Metadata } from "next";
import Link from "next/link";
import { Suspense, type ReactNode } from "react";
import { ChartBarLineIcon, School01Icon, Settings02Icon, Wallet01Icon, MoneyReceive01Icon } from "@hugeicons/core-free-icons";
import type { IconSvgElement } from "@hugeicons/react";

import { ConfirmPayoutNumber } from "@/components/platform/ConfirmPayoutNumber";
import { InfraCosts } from "@/components/platform/InfraCosts";
import { WalletMovement } from "@/components/platform/WalletMovement";
import { Amount } from "@/components/ui/Amount";
import { BarTable } from "@/components/ui/BarTable";
import { TrendChip } from "@/components/ui/TrendChip";
import { shownAmount } from "@/lib/money-format";
import { TONE_TEXT, toneOf, trend, type Tone, type ToneRule } from "@/lib/money-tones";
import { ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Icon } from "@/components/ui/Icon";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Skeleton } from "@/components/ui/Skeleton";
import { requirePlatformAdmin } from "@/lib/auth";
import { formatAmount } from "@/lib/billing";
import { format } from "@/lib/i18n/messages";
import { platformPaymentsCatalogues } from "@/lib/i18n/platform-payments";
import { getMessages } from "@/lib/i18n/server";
import {
  MONTH_COLUMNS,
  costMonths,
  costsByMonth,
  currentMonths,
  isProvider,
  monthOf,
  parseAlerts,
  parsePlatformPayments,
  walletGap,
  type InfraCost,
} from "@/lib/platform-payments";
import { createClient } from "@/lib/supabase/server";

import { addInfraCost, addWalletMovement, confirmPayoutAccount, deleteInfraCost, deleteWalletMovement } from "./actions";

export const metadata: Metadata = { title: "Payments" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function PlatformPaymentsPage() {
  return (
    <Suspense fallback={<PaymentsSkeleton />}>
      <Payments />
    </Suspense>
  );
}

function PaymentsSkeleton() {
  return (
    <div aria-hidden className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {[0, 1, 2, 3].map((i) => (
        <Skeleton key={i} className="h-36 rounded-lg" />
      ))}
      <Skeleton className="h-72 rounded-lg sm:col-span-2 xl:col-span-4" />
    </div>
  );
}

/** One figure: its icon and title, the amount in large type, and short "amount label" pairs or a line under it. */
/** Each month's measure in its state colour: what students paid, BusIn's income, its costs, and the margin by its sign. */
const PLATFORM_MONTH_TONES: Record<string, ToneRule> = { volume: "info", fees: "ok", charges: "ok", transferCosts: "bad", infra: "bad", margin: "signed" };

function Figure(props: {
  icon: IconSvgElement;
  title: string;
  value: ReactNode;
  parts?: [string, string][];
  note?: string;
  chip?: { tone: "ok" | "warn"; text: string };
  /** The figure's state colour, and this month against the last. */
  tone?: Tone;
  trend?: ReactNode;
  testId: string;
}) {
  const { icon, title, value, parts = [], note, chip, tone = "neutral", trend: trendLine, testId } = props;
  return (
    <div data-testid={testId}>
      <Card className="flex h-full flex-col gap-3 p-6!">
        <div className="flex items-start justify-between gap-2">
          <div className="flex items-center gap-2 text-sm font-semibold text-muted">
            <Icon icon={icon} size={18} />
            <h2 className="m-0 text-sm font-semibold">{title}</h2>
          </div>
          {chip ? <Chip tone={chip.tone}>{chip.text}</Chip> : null}
        </div>
        <p data-tone={tone} className={`m-0 text-3xl font-extrabold tracking-tight tabular-nums ${TONE_TEXT[tone]}`}>{value}</p>
        {trendLine}
        {parts.length > 0 ? (
          <ul className="m-0 flex list-none flex-wrap gap-x-3 gap-y-1 p-0 text-xs">
            {parts.map(([n, label]) => (
              <li key={label}>
                <strong className="font-bold tabular-nums">{n}</strong> <span className="text-muted">{label}</span>
              </li>
            ))}
          </ul>
        ) : null}
        {note ? <p className="m-0 text-xs text-muted">{note}</p> : null}
      </Card>
    </div>
  );
}

const FIRST_COST_MONTH = (now: Date) => monthOf(new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 11, 1)));

/**
 * BusIn's money in the platform console (ADR 0029): the margin, what is held for schools, the wallet against the books
 * and what schools owe; month by month; the operators; the busiest schools; what needs a look; the infrastructure costs
 * and BusIn's own wallet movements. Totals only, through `platform_*` functions that check the platform admin.
 */
async function Payments() {
  await requirePlatformAdmin();
  const { locale, t } = await getMessages();
  const c = platformPaymentsCatalogues[locale];
  const now = new Date();
  const supabase = await createClient();
  const [overviewRes, alertsRes, costsRes, movementsRes] = await Promise.all([
    supabase.rpc("platform_payments_overview", { p_months: 6 }),
    supabase.rpc("platform_payment_alerts"),
    supabase.rpc("platform_infra_costs", { p_from: FIRST_COST_MONTH(now) }),
    supabase.rpc("platform_wallet_movements", { p_limit: 10 }),
  ]);
  const help = {
    label: t.help.open,
    title: c.page.help.title,
    intro: c.page.help.intro,
    scenarios: Object.values(c.page.help.scenarios),
    scenariosLabel: t.help.scenarios,
    closeLabel: t.help.close,
  };
  const settingsLink = (
    <ButtonLink href="/platform/payments/settings" variant="secondary" icon={Settings02Icon}>
      {c.page.settings}
    </ButtonLink>
  );
  if (overviewRes.error) {
    return (
      <>
        <PageHeader title={c.page.title} subtitle={c.page.subtitle} help={help} action={settingsLink} />
        <Notice tone="bad">{c.page.loadError}</Notice>
      </>
    );
  }

  const o = parsePlatformPayments(overviewRes.data);
  const alerts = parseAlerts(alertsRes.data);
  const money = (n: number) => formatAmount(n, locale);
  const monthName = (iso: string) => new Intl.DateTimeFormat(locale, { month: "long", year: "numeric", timeZone: "UTC" }).format(new Date(`${iso.slice(0, 10)}T00:00:00Z`));
  const when = (iso: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone: "UTC" }).format(new Date(iso));
  const operator = (provider: string) => (isProvider(provider) ? c.operators[provider] : provider);
  const percent = (share: number) => new Intl.NumberFormat(locale, { maximumFractionDigits: 1 }).format(share * 100);

  const { current, previous } = currentMonths(o.months, now);
  const gap = o.wallet ? walletGap(o.wallet) : null;
  const thisMonth = monthOf(now);
  const anyMonth = o.months.some((m) => MONTH_COLUMNS.some((col) => m[col] !== 0));

  const costs: InfraCost[] = (costsRes.data ?? []).map((row) => ({ id: row.id, month: row.month.slice(0, 10), label: row.label, amount: row.amount_xaf, note: row.note }));
  const costGroups = costsByMonth(costs).map((g) => ({
    month: g.month,
    label: monthName(g.month),
    total: money(g.total),
    costs: g.costs.map((cost) => ({ id: cost.id, label: cost.label, amount: money(cost.amount), note: cost.note })),
  }));

  return (
    <>
      <PageHeader title={c.page.title} subtitle={c.page.subtitle} help={help} action={settingsLink} />

      <section aria-label={c.tiles.label} className="grid grid-cols-[minmax(0,1fr)] gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Figure
          testId="tile-margin"
          icon={ChartBarLineIcon}
          title={c.tiles.margin}
          value={<Amount value={current?.margin ?? 0} locale={locale} />}
          tone={toneOf("signed", current?.margin ?? 0)}
          trend={<TrendChip testId="trend-margin" trend={trend(current?.margin ?? 0, previous?.margin ?? 0)} words={c.tiles.trend} />}
          parts={[[money(previous?.margin ?? 0), c.tiles.lastMonth]]}
        />
        <Figure testId="tile-held" icon={School01Icon} title={c.tiles.held} value={<Amount value={o.heldForSchools} locale={locale} />} note={c.tiles.heldHint} tone="info" />
        {o.wallet && gap ? (
          <Figure
            testId="tile-wallet"
            icon={Wallet01Icon}
            title={c.tiles.wallet}
            value={<Amount value={o.wallet.balance} locale={locale} />}
            tone={gap.flagged ? "warn" : "ok"}
            chip={gap.flagged ? { tone: "warn", text: c.tiles.flagged } : { tone: "ok", text: c.tiles.matches }}
            parts={[
              [money(o.wallet.book), c.tiles.books],
              [money(gap.gap), c.tiles.gap],
            ]}
            note={format(c.tiles.readAt, { when: when(o.wallet.takenAt) })}
          />
        ) : (
          <Figure testId="tile-wallet" icon={Wallet01Icon} title={c.tiles.wallet} value={c.tiles.walletNone} note={format(c.tiles.booksNow, { amount: money(o.bookBalance) })} />
        )}
        <Figure testId="tile-owed" icon={MoneyReceive01Icon} title={c.tiles.owed} value={<Amount value={o.owedBySchools} locale={locale} />} note={c.tiles.owedHint} tone={o.owedBySchools > 0 ? "warn" : "neutral"} />
      </section>

      <section aria-labelledby="alerts-title" className="flex flex-col gap-3" data-testid="payment-alerts">
        <h2 id="alerts-title" className="text-xl font-bold">
          {c.alerts.title}
        </h2>
        {alertsRes.error ? (
          <Notice tone="bad">{c.page.loadError}</Notice>
        ) : alerts.length === 0 ? (
          <Card className="p-6!">
            <p className="m-0 text-sm text-muted">{c.alerts.none}</p>
          </Card>
        ) : (
          <ul className="m-0 flex list-none flex-col gap-2 p-0">
            {alerts.map((a) => (
              <li key={`${a.kind}-${a.id}`} data-alert={a.kind} data-school={a.schoolId} className="flex flex-wrap items-center gap-x-4 gap-y-2 rounded-lg bg-surface px-5 py-4 shadow-soft">
                <Chip tone={a.kind === "payout_account" ? "warn" : "bad"}>{c.alerts.kinds[a.kind]}</Chip>
                <div className="min-w-48 flex-1">
                  <Link href={`/platform/schools/${a.schoolId}`} className="font-semibold text-fg no-underline hover:text-link">
                    {a.schoolName}
                  </Link>
                  <p className="m-0 text-xs text-muted">
                    {a.kind === "payout_account" ? operator(a.code ?? "") : [a.status, a.code].filter(Boolean).join(" · ")}
                    {a.at ? ` · ${when(a.at)}` : ""}
                  </p>
                </div>
                {a.amount !== null ? <span className="font-semibold tabular-nums">{money(a.amount)}</span> : null}
                {a.kind === "payout_account" ? (
                  <ConfirmPayoutNumber account={a.id} school={a.schoolName} detail={`${a.schoolName}, ${operator(a.code ?? "")}`} copy={c.alerts} errors={c.errors} action={confirmPayoutAccount} />
                ) : null}
              </li>
            ))}
          </ul>
        )}
      </section>

      <section aria-labelledby="months-title" className="flex flex-col gap-3">
        <h2 id="months-title" className="text-xl font-bold">
          {c.months.title}
        </h2>
        {anyMonth ? (
          <div data-testid="platform-months">
            <BarTable
              caption={c.months.caption}
              rowHeading={c.months.month}
              columns={MONTH_COLUMNS.map((key) => ({ key, label: c.months.columns[key], tone: PLATFORM_MONTH_TONES[key] }))}
              highlight={{ key: thisMonth, label: c.months.thisMonth }}
              rows={[...o.months].reverse().map((m) => ({
                key: m.month,
                label: monthName(m.month),
                values: Object.fromEntries(MONTH_COLUMNS.map((key) => [key, m[key]])),
                display: Object.fromEntries(MONTH_COLUMNS.map((key) => [key, shownAmount(m[key], locale).text])),
                full: Object.fromEntries(MONTH_COLUMNS.map((key) => [key, money(m[key])])),
              }))}
            />
          </div>
        ) : (
          <p className="m-0 rounded-md bg-surface-2 px-5 py-4 text-sm text-muted" data-testid="platform-months-empty">
            {c.months.empty}
          </p>
        )}
      </section>

      <div className="grid grid-cols-[minmax(0,1fr)] gap-6 lg:grid-cols-2">
        <Card className="flex flex-col gap-4 p-6!">
          <section aria-labelledby="operators-title" data-testid="operators" className="flex flex-col gap-4">
            <h2 id="operators-title" className="m-0 text-xl font-bold">
              {c.operatorsCard.title}
            </h2>
            {o.operators.length === 0 ? (
              <p className="m-0 text-sm text-muted">{c.operatorsCard.none}</p>
            ) : (
              <ul className="m-0 flex list-none flex-col gap-2 p-0">
                {o.operators.map((op) => (
                  <li key={op.provider} data-provider={op.provider} className="flex flex-col gap-1 rounded-md bg-surface-2 px-4 py-3 text-sm">
                    <span className="flex flex-wrap items-baseline justify-between gap-2">
                      <span className="font-semibold">{operator(op.provider)}</span>
                      {op.failureRate !== null ? <span className="font-semibold tabular-nums">{format(c.operatorsCard.failureRate, { n: percent(op.failureRate) })}</span> : null}
                    </span>
                    <span className="text-xs text-muted tabular-nums">
                      <strong className="text-fg">{op.completed}</strong> {c.operatorsCard.completed} · <strong className="text-fg">{op.failed}</strong> {c.operatorsCard.failed}
                      {op.topFailure ? ` · ${format(c.operatorsCard.topFailure, { code: op.topFailure })}` : ""}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </section>
        </Card>

        <Card className="flex flex-col gap-4 p-6!">
          <section aria-labelledby="top-title" data-testid="top-schools" className="flex flex-col gap-4">
            <h2 id="top-title" className="m-0 text-xl font-bold">
              {c.top.title}
            </h2>
            {o.topSchools.length === 0 ? (
              <p className="m-0 text-sm text-muted">{c.top.none}</p>
            ) : (
              <ol className="m-0 flex list-none flex-col gap-2 p-0">
                {o.topSchools.map((s) => (
                  <li key={s.id} className="flex items-center justify-between gap-3 rounded-md bg-surface-2 px-4 py-3 text-sm">
                    <span className="min-w-0">
                      <Link href={`/platform/schools/${s.id}`} className="font-semibold text-fg no-underline hover:text-link">
                        {s.name}
                      </Link>
                      <span className="block text-xs text-muted">{format(c.top.payments, { n: s.payments })}</span>
                    </span>
                    <Amount value={s.volume} locale={locale} className="shrink-0 font-semibold tabular-nums" />
                  </li>
                ))}
              </ol>
            )}
          </section>
        </Card>
      </div>

      <div className="grid grid-cols-[minmax(0,1fr)] items-start gap-6 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        {costsRes.error ? (
          <Notice tone="bad">{c.page.loadError}</Notice>
        ) : (
          <InfraCosts
            months={costGroups}
            choices={costMonths(now).map((value) => ({ value, label: monthName(value) }))}
            copy={c.costs}
            errors={c.errors}
            actions={{ add: addInfraCost, remove: deleteInfraCost }}
          />
        )}
        <WalletMovement
          copy={c.wallet}
          errors={c.errors}
          action={addWalletMovement}
          remove={deleteWalletMovement}
          movements={(movementsRes.data ?? []).map((m) => ({
            id: m.id,
            kind: m.kind === "top_up" ? "top_up" : "withdrawal",
            amount: money(m.amount_xaf),
            when: when(m.happened_at),
            note: m.note,
          }))}
        />
      </div>
    </>
  );
}
